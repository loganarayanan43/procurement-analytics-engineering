select *
from {{ ref('rpt_procurement_overview') }}
where positive_obligations - funding_reductions
        is distinct from net_obligations
   or total_actions != (
        select count(*)
        from {{ ref('fct_contract_actions') }}
   )
   or funding_increase_actions
        + funding_reduction_actions
        + zero_obligation_actions != total_actions
   or missing_offer_count_actions
        + invalid_offer_count_actions
        + negative_offer_count_actions
        + usable_offer_count_actions != total_actions
