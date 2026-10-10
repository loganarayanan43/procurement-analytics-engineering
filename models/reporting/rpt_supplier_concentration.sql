{{ config(materialized='view') }}

with supplier_totals as (
    select
        supplier_key,
        count(*) as action_count,
        count(distinct contract_id) as distinct_contracts_observed,

        sum(case when obligation_amount > 0
            then obligation_amount else 0 end)
            as positive_obligations,

        -sum(case when obligation_amount < 0
            then obligation_amount else 0 end)
            as funding_reductions,

        sum(obligation_amount) as net_obligations

    from {{ ref('fct_contract_actions') }}
    group by supplier_key
),

ranked_identified_suppliers as (
    select
        supplier_key,
        row_number() over (
            order by positive_obligations desc, supplier_key
        ) as supplier_rank
    from supplier_totals
    where supplier_key != 'unknown'
      and positive_obligations > 0
)

select
    t.supplier_key,
    s.supplier_name,
    t.supplier_key = 'unknown' as is_unknown_supplier,
    r.supplier_rank,
    t.action_count,
    t.distinct_contracts_observed,
    t.positive_obligations,
    t.funding_reductions,
    t.net_obligations,

    100.0 * safe_divide(
        t.positive_obligations,
        sum(t.positive_obligations) over ()
    ) as share_of_all_positive_obligations_percent

from supplier_totals t
left join {{ ref('dim_supplier') }} s
    on t.supplier_key = s.supplier_key
left join ranked_identified_suppliers r
    on t.supplier_key = r.supplier_key
