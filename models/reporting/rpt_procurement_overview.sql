{{ config(materialized='view') }}

with totals as (
    select
        min(date_key) as first_action_date,
        max(date_key) as last_action_date,
        count(*) as total_actions,
        count(distinct contract_id) as distinct_contracts_observed,
        count(distinct case
            when supplier_key != 'unknown' then supplier_key
        end) as identified_suppliers,

        sum(case when obligation_amount > 0
            then obligation_amount else 0 end)
            as positive_obligations,

        -sum(case when obligation_amount < 0
            then obligation_amount else 0 end)
            as funding_reductions,

        sum(obligation_amount) as net_obligations,

        countif(obligation_amount > 0) as funding_increase_actions,
        countif(obligation_amount < 0) as funding_reduction_actions,
        countif(obligation_amount = 0) as zero_obligation_actions,

        countif(is_offer_count_missing) as missing_offer_count_actions,
        countif(is_offer_count_invalid) as invalid_offer_count_actions,
        countif(number_of_offers_received < 0)
            as negative_offer_count_actions,
        countif(number_of_offers_received >= 0)
            as usable_offer_count_actions,
        countif(number_of_offers_received = 0)
            as zero_offer_actions,
        countif(number_of_offers_received >= 1)
            as actions_reporting_at_least_one_offer,
        countif(number_of_offers_received = 1)
            as single_offer_actions

    from {{ ref('fct_contract_actions') }}
)

select
    *,
    100.0 * safe_divide(
        usable_offer_count_actions, total_actions
    ) as offer_count_coverage_percent,

    100.0 * safe_divide(
        single_offer_actions,
        actions_reporting_at_least_one_offer
    ) as single_offer_share_percent

from totals
