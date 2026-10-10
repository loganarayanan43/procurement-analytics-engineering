-- dbt singular test: return zero rows when the recommendation queue is well formed.
with q as (
  select * from {{ ref('rpt_procurement_review_queue') }}
),
invalid as (
  select agency_key, review_type
  from q
  where agency_key is null
     or agency_name is null
     or review_type not in (
       'OFFER_DATA_COMPLETENESS',
       'SINGLE_OFFER_REVIEW',
       'SUPPLIER_CONCENTRATION_REVIEW',
       'FUNDING_CHANGE_REVIEW'
     )
     or priority not in ('HIGH', 'MEDIUM')
     or evidence_percent is null
     or evidence_percent < 0
     or (review_type != 'FUNDING_CHANGE_REVIEW' and evidence_percent > 100)
     or agency_action_count < 50
     or supporting_record_count < 0
     or recommended_next_step is null
     or interpretation_guardrail is null
),
duplicates as (
  select agency_key, review_type
  from q
  group by agency_key, review_type
  having count(*) > 1
)
select 'invalid_review_rule' as issue, agency_key, review_type from invalid
union all
select 'duplicate_agency_review' as issue, agency_key, review_type from duplicates
