with report_totals as (
    select
        concat('Agency: ', agency_role) as report_name,
        sum(action_count) as actions,
        sum(positive_obligations) as increases,
        sum(funding_reductions) as reductions,
        sum(net_obligations) as net,
        sum(usable_offer_count_actions) as usable_offers,
        sum(actions_reporting_at_least_one_offer) as positive_offers,
        sum(single_offer_actions) as single_offers
    from {{ ref('rpt_agency_summary') }}
    group by agency_role

    union all

    select
        'Industry',
        sum(action_count),
        sum(positive_obligations),
        sum(funding_reductions),
        sum(net_obligations),
        sum(usable_offer_count_actions),
        sum(actions_reporting_at_least_one_offer),
        sum(single_offer_actions)
    from {{ ref('rpt_industry_summary') }}
)

select r.*
from report_totals r
cross join {{ ref('rpt_procurement_overview') }} o
where r.actions is distinct from o.total_actions
   or r.increases is distinct from o.positive_obligations
   or r.reductions is distinct from o.funding_reductions
   or r.net is distinct from o.net_obligations
   or r.usable_offers is distinct from o.usable_offer_count_actions
   or r.positive_offers
        is distinct from o.actions_reporting_at_least_one_offer
   or r.single_offers is distinct from o.single_offer_actions
