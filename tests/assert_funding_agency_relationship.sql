with baseline as (
    select
        count(*) as record_count,
        sum(obligation_amount) as obligations
    from {{ ref('fct_contract_actions') }}
),

joined as (
    select
        count(*) as record_count,
        sum(f.obligation_amount) as obligations,
        countif(a.agency_key is null) as unmatched_records
    from {{ ref('fct_contract_actions') }} f
    left join {{ ref('dim_agency') }} a
        on f.funding_agency_key = a.agency_key
)

select
    joined.record_count,
    joined.unmatched_records
from baseline
cross join joined
where joined.record_count != baseline.record_count
   or joined.obligations is distinct from baseline.obligations
   or joined.unmatched_records > 0
