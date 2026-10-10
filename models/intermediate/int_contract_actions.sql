{{ config(materialized='view') }}

with staging as (
    select *
    from {{ ref('stg_contract_actions') }}
),

typed as (
    select
        * except (
            action_date,
            federal_action_obligation,
            number_of_offers_received
        ),

        action_date as action_date_raw,
        federal_action_obligation as federal_action_obligation_raw,
        number_of_offers_received as number_of_offers_received_raw,

        safe_cast(action_date as date) as action_date,
        safe_cast(federal_action_obligation as numeric)
            as federal_action_obligation,
        safe_cast(number_of_offers_received as int64)
            as number_of_offers_received,

        number_of_offers_received is null as is_offer_count_missing,

        number_of_offers_received is not null
            and safe_cast(number_of_offers_received as int64) is null
            as is_offer_count_invalid

    from staging
)

select
    *,
    case
        when federal_action_obligation > 0 then 'Funding increase'
        when federal_action_obligation < 0 then 'Funding reduction'
        when federal_action_obligation = 0 then 'No funding change'
        else 'Unknown'
    end as funding_change_type
from typed
