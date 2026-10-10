{{ config(materialized='view') }}

select
    date_key as action_date,
    count(*) as action_count,

    sum(case when obligation_amount > 0
        then obligation_amount else 0 end)
        as positive_obligations,

    -sum(case when obligation_amount < 0
        then obligation_amount else 0 end)
        as funding_reductions,

    sum(obligation_amount) as net_obligations

from {{ ref('fct_contract_actions') }}
group by date_key
