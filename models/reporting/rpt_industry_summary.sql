{{ config(materialized='view') }}

with base as (
    select
        *,
        coalesce(naics_code, 'unknown') as industry_key
    from {{ ref('fct_contract_actions') }}
),

industry_labels as (
    select
        industry_key,
        naics_description as industry_description
    from base
    where naics_code is not null
      and naics_description is not null
    qualify row_number() over (
        partition by industry_key
        order by date_key desc, transaction_id desc
    ) = 1
),

aggregated as (
    select
        industry_key,

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

    from base
    group by industry_key
)

select
    a.*,
    case
        when a.industry_key = 'unknown' then 'Unknown industry'
        else coalesce(l.industry_description, 'Description unavailable')
    end as industry_description,
    a.industry_key = 'unknown' as is_unknown_industry,

    100.0 * safe_divide(
        a.positive_obligations,
        sum(a.positive_obligations) over ()
    ) as share_of_positive_obligations_percent

from aggregated a
left join industry_labels l
    on a.industry_key = l.industry_key
