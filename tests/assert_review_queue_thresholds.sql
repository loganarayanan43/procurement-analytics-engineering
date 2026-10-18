-- Independent integration assertion for the review queue.
-- Builds expected eligibility/priorities from an established agency summary plus
-- separate supplier aggregates; flags missing, unexpected or incorrect queue rows.
-- Returns ZERO rows when the model's four threshold rules behave as specified.
-- Requires a real BigQuery/dbt execution; this file alone is NOT test evidence.
with agency as (
    select *
    from {{ ref('rpt_agency_summary') }}
    where agency_role = 'Awarding'
),
supplier_totals as (
    select
        agency_key,
        supplier_key,
        sum(if(obligation_amount > 0, obligation_amount, 0)) as positive
    from {{ ref('fct_contract_actions') }}
    group by 1, 2
),
suppliers as (
    select
        agency_key,
        countif(supplier_key != 'unknown' and positive > 0) as identified_count,
        sum(if(supplier_key = 'unknown', positive, 0)) as unknown_positive,
        max(if(supplier_key != 'unknown', positive, null)) as leading_identified_positive
    from supplier_totals
    group by agency_key
),
evidence as (
    select
        a.*,
        s.identified_count,
        100.0 * safe_divide(s.unknown_positive, a.positive_obligations) as unknown_share,
        100.0 * safe_divide(s.leading_identified_positive, a.positive_obligations) as leading_share,
        100.0 * safe_divide(a.funding_reductions, a.positive_obligations) as reduction_ratio
    from agency a
    left join suppliers s using (agency_key)
),
expected as (
    select
        agency_key,
        'OFFER_DATA_COMPLETENESS' as review_type,
        if(offer_count_coverage_percent < 35, 'HIGH', 'MEDIUM') as priority,
        round(offer_count_coverage_percent, 2) as evidence_percent,
        action_count - usable_offer_count_actions as supporting_record_count
    from evidence
    where action_count >= 50 and offer_count_coverage_percent < 70

    union all

    select
        agency_key,
        'SINGLE_OFFER_REVIEW',
        if(single_offer_share_percent >= 65, 'HIGH', 'MEDIUM'),
        round(single_offer_share_percent, 2),
        actions_reporting_at_least_one_offer
    from evidence
    where actions_reporting_at_least_one_offer >= 50
      and offer_count_coverage_percent >= 70
      and single_offer_share_percent >= 50

    union all

    select
        agency_key,
        'SUPPLIER_CONCENTRATION_REVIEW',
        if(leading_share >= 50, 'HIGH', 'MEDIUM'),
        round(leading_share, 2),
        identified_count
    from evidence
    where action_count >= 50
      and positive_obligations > 0
      and identified_count >= 3
      and unknown_share <= 20
      and leading_share >= 35

    union all

    select
        agency_key,
        'FUNDING_CHANGE_REVIEW',
        if(reduction_ratio >= 40, 'HIGH', 'MEDIUM'),
        round(reduction_ratio, 2),
        action_count
    from evidence
    where action_count >= 50
      and positive_obligations > 0
      and reduction_ratio >= 20
),
actual as (
    select agency_key, review_type, priority, evidence_percent, supporting_record_count
    from {{ ref('rpt_procurement_review_queue') }}
)
select
    coalesce(e.agency_key, a.agency_key) as agency_key,
    coalesce(e.review_type, a.review_type) as review_type,
    e.priority as expected_priority,
    a.priority as actual_priority,
    e.evidence_percent as expected_evidence_percent,
    a.evidence_percent as actual_evidence_percent
from expected e
full outer join actual a
    on e.agency_key = a.agency_key
   and e.review_type = a.review_type
where e.agency_key is null
   or a.agency_key is null
   or e.priority is distinct from a.priority
   or e.supporting_record_count is distinct from a.supporting_record_count
   or e.evidence_percent is distinct from a.evidence_percent
