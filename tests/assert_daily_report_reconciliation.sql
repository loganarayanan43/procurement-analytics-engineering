with daily_totals as (
    select
        sum(action_count) as actions,
        sum(positive_obligations) as increases,
        sum(funding_reductions) as reductions,
        sum(net_obligations) as net
    from {{ ref('rpt_daily_obligations') }}
)

select daily_totals.*
from daily_totals
cross join {{ ref('rpt_procurement_overview') }} overview
where daily_totals.actions is distinct from overview.total_actions
   or daily_totals.increases
        is distinct from overview.positive_obligations
   or daily_totals.reductions
        is distinct from overview.funding_reductions
   or daily_totals.net
        is distinct from overview.net_obligations
