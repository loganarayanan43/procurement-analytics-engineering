with expected as (
    select
        count(*) as record_count,
        sum(federal_action_obligation) as net_obligations,
        sum(abs(federal_action_obligation)) as absolute_obligations
    from {{ ref('int_contract_actions') }}
),

actual as (
    select
        count(*) as record_count,
        sum(f.obligation_amount) as net_obligations,
        sum(abs(f.obligation_amount)) as absolute_obligations
    from {{ ref('fct_contract_actions') }} f
    left join {{ ref('dim_supplier') }} s
        on f.supplier_key = s.supplier_key
    left join {{ ref('dim_agency') }} a
        on f.agency_key = a.agency_key
    left join {{ ref('dim_date') }} d
        on f.date_key = d.date_key
)

select
    expected.record_count as expected_records,
    actual.record_count as actual_records,
    expected.net_obligations as expected_net_obligations,
    actual.net_obligations as actual_net_obligations
from expected
cross join actual
where expected.record_count != actual.record_count
   or expected.net_obligations
       is distinct from actual.net_obligations
   or expected.absolute_obligations
       is distinct from actual.absolute_obligations
