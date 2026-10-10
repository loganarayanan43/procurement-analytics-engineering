{{ config(materialized='table') }}

select
    concat('uei:', recipient_uei) as supplier_key,
    recipient_uei,
    coalesce(recipient_name, 'Name unavailable') as supplier_name
from {{ ref('int_contract_actions') }}
where recipient_uei is not null
qualify row_number() over (
    partition by recipient_uei
    order by action_date desc, contract_transaction_unique_key desc
) = 1

union all

select
    'unknown' as supplier_key,
    cast(null as string) as recipient_uei,
    'Unknown supplier' as supplier_name
