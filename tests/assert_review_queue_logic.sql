-- dbt singular test: return zero rows for malformed recommendations.
with q as (
  select * from {{ ref('rpt_procurement_review_queue') }}
),
invalid as (
  select agency_key, review_type
  from q
  where nullif(trim(agency_key), '') is null
     or nullif(trim(agency_name), '') is null
     or review_type is null
     or review_type not in (
       'OFFER_DATA_COMPLETENESS', 'SINGLE_OFFER_REVIEW',
       'SUPPLIER_CONCENTRATION_REVIEW', 'FUNDING_CHANGE_REVIEW'
     )
     or priority is null or priority not in ('HIGH', 'MEDIUM')
     or nullif(trim(evidence_metric), '') is null
     or evidence_percent is null or evidence_percent_unrounded is null
     or (is_inf(evidence_percent_unrounded) or is_nan(evidence_percent_unrounded))
     or evidence_percent_unrounded < 0
     or (review_type is null or review_type != 'FUNDING_CHANGE_REVIEW')
        and evidence_percent_unrounded > 100
     or evidence_percent is distinct from round(evidence_percent_unrounded, 2)
     or agency_action_count is null or agency_action_count < 50
     or supporting_record_count is null or supporting_record_count < 0
     or nullif(trim(recommended_next_step), '') is null
     or nullif(trim(interpretation_guardrail), '') is null
),
duplicates as (
  select agency_key, review_type
  from q group by agency_key, review_type having count(*) > 1
)
select 'invalid_review_rule' as issue, agency_key, review_type from invalid
union all
select 'duplicate_agency_review', agency_key, review_type from duplicates
