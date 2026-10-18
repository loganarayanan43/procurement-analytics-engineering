{{ config(materialized='view') }}

-- Prescriptive decision support, NOT a claim of waste, misconduct, or savings.
-- One row per awarding agency and review signal. Thresholds are illustrative.
-- Use only awarding agencies here: mixing awarding and funding roles double-counts actions.
with agency_metrics as (
    select
        agency_key,
        count(*) as action_count,
        countif(number_of_offers_received >= 0) as usable_offer_count_actions,
        countif(number_of_offers_received >= 1) as actions_with_at_least_one_offer,
        countif(number_of_offers_received = 1) as single_offer_actions,
        sum(if(obligation_amount > 0, obligation_amount, 0)) as funding_increases,
        -sum(if(obligation_amount < 0, obligation_amount, 0)) as funding_reductions
    from {{ ref('fct_contract_actions') }}
    group by agency_key
),

agency_supplier_totals as (
    select
        agency_key,
        supplier_key,
        sum(if(obligation_amount > 0, obligation_amount, 0)) as funding_increases
    from {{ ref('fct_contract_actions') }}
    group by agency_key, supplier_key
),

agency_supplier_evidence as (
    select
        agency_key,
        countif(supplier_key != 'unknown' and funding_increases > 0)
            as identified_positive_suppliers,
        sum(if(supplier_key = 'unknown', funding_increases, 0))
            as unknown_supplier_funding_increases,
        max(if(supplier_key != 'unknown', funding_increases, null))
            as largest_identified_supplier_funding_increases
    from agency_supplier_totals
    group by agency_key
),

evidence as (
    select
        a.*,
        coalesce(d.agency_name, 'Unknown agency') as agency_name,
        s.identified_positive_suppliers,
        100.0 * safe_divide(a.usable_offer_count_actions, a.action_count)
            as offer_count_coverage_percent,
        100.0 * safe_divide(a.single_offer_actions, a.actions_with_at_least_one_offer)
            as single_offer_percent,
        100.0 * safe_divide(
            s.unknown_supplier_funding_increases, a.funding_increases
        ) as unknown_supplier_funding_share_percent,
        100.0 * safe_divide(
            s.largest_identified_supplier_funding_increases, a.funding_increases
        ) as leading_supplier_funding_share_percent,
        100.0 * safe_divide(a.funding_reductions, a.funding_increases)
            as funding_reduction_to_increase_percent
    from agency_metrics a
    left join agency_supplier_evidence s using (agency_key)
    left join {{ ref('dim_agency') }} d using (agency_key)
)

select
    e.agency_key,
    e.agency_name,
    rule.review_type,
    rule.priority,
    rule.evidence_metric,
    round(rule.evidence_percent, 2) as evidence_percent,
    -- Rule decisions use the unrounded percentage; keep it for auditability.
    rule.evidence_percent as evidence_percent_unrounded,
    e.action_count as agency_action_count,
    rule.supporting_record_count,
    rule.recommended_next_step,
    rule.interpretation_guardrail
from evidence e,
{{ procurement_review_rules('e') }} as rule
where rule.meets_rule
