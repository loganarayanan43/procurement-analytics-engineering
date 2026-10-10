{{ config(materialized='table') }}

with agency_observations as (
    select
        awarding_agency_code as agency_code,
        awarding_agency_name as agency_name,
        action_date,
        contract_transaction_unique_key as transaction_id,
        1 as role_priority
    from {{ ref('int_contract_actions') }}

    union all

    select
        funding_agency_code as agency_code,
        funding_agency_name as agency_name,
        action_date,
        contract_transaction_unique_key as transaction_id,
        2 as role_priority
    from {{ ref('int_contract_actions') }}
)

select
    concat('agency:', agency_code) as agency_key,
    agency_code,
    coalesce(agency_name, 'Name unavailable') as agency_name
from agency_observations
where agency_code is not null
qualify row_number() over (
    partition by agency_code
    order by
        action_date desc,
        transaction_id desc,
        role_priority
) = 1

union all

select
    'unknown',
    cast(null as string),
    'Unknown agency'
