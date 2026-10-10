with records as (
    select *
    from {{ ref('int_contract_actions') }}
),

checks as (
    select
        'record_count_changed' as failed_check,
        abs(count(*) - 500000) as failure_count
    from records

    union all

    select
        'missing_transaction_identifiers',
        countif(
            nullif(trim(contract_transaction_unique_key), '') is null
        )
    from records

    union all

    select
        'duplicate_transaction_identifiers',
        count(contract_transaction_unique_key)
            - count(distinct contract_transaction_unique_key)
    from records

    union all

    select
        'missing_or_invalid_action_dates',
        countif(action_date is null)
    from records

    union all

    select
        'missing_or_invalid_obligations',
        countif(federal_action_obligation is null)
    from records

    union all

    select
        'invalid_offer_counts',
        countif(is_offer_count_invalid)
    from records

    union all

    select
        'incorrect_missing_offer_flags',
        countif(
            is_offer_count_missing
            != (number_of_offers_received_raw is null)
        )
    from records
)

select *
from checks
where failure_count > 0
