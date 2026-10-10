with report_totals as (
    select
        sum(action_count) as actions,
        sum(positive_obligations) as increases,
        sum(funding_reductions) as reductions,
        sum(net_obligations) as net
    from {{ ref('rpt_supplier_concentration') }}
)

select report_totals.*
from report_totals
cross join {{ ref('rpt_procurement_overview') }} overview
where report_totals.actions is distinct from overview.total_actions
   or report_totals.increases
        is distinct from overview.positive_obligations
   or report_totals.reductions
        is distinct from overview.funding_reductions
   or report_totals.net
        is distinct from overview.net_obligations
