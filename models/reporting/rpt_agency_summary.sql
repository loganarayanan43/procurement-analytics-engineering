{{ config(materialized='view') }}

with agency_roles as (
    select
        'Awarding' as agency_role,
        agency_key,
        contract_id,
        obligation_amount,
        number_of_offers_received
    from {{ ref('fct_contract_actions') }}

    union all

    select
        'Funding' as agency_role,
        funding_agency_key as agency_key,
        contract_id,
        obligation_amount,
        number_of_offers_received
    from {{ ref('fct_contract_actions') }}
),

aggregated as (
    select
        agency_role,
        agency_key,

    count(*) as action_count,
    count(distinct contract_id) as distinct_contracts_observed,

    sum(case when obligation_amount > 0
        then obligation_amount else 0 end) as positive_obligations,

    -sum(case when obligation_amount < 0
        then obligation_amount else 0 end) as funding_reductions,

    sum(obligation_amount) as net_obligations,

    countif(number_of_offers_received >= 0)
        as usable_offer_count_actions,

    countif(number_of_offers_received >= 1)
        as actions_reporting_at_least_one_offer,

    countif(number_of_offers_received = 1)
        as single_offer_actions,

    100.0 * safe_divide(
        countif(number_of_offers_received >= 0),
        count(*)
    ) as offer_count_coverage_percent,

    100.0 * safe_divide(
        countif(number_of_offers_received = 1),
        countif(number_of_offers_received >= 1)
    ) as single_offer_share_percent

    from agency_roles
    group by agency_role, agency_key
)

select
    a.*,
    d.agency_name,
    a.agency_key = 'unknown' as is_unknown_agency,

    100.0 * safe_divide(
        a.positive_obligations,
        sum(a.positive_obligations) over (
            partition by a.agency_role
        )
    ) as share_of_positive_obligations_percent

from aggregated a
left join {{ ref('dim_agency') }} d
    on a.agency_key = d.agency_key
