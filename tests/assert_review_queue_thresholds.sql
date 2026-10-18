-- Synthetic boundary regression. Uses the very same production rule expansion,
-- but expected outputs below are explicit, independently hand-specified cases.
-- No access to raw 500k extract is required.
with cases as (
 select * from unnest([
 struct('base' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('small_agency' as agency_key, 49 as action_count, 20 as usable_offer_count_actions, 20 as actions_with_at_least_one_offer, 4 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('coverage_69' as agency_key, 100 as action_count, 69 as usable_offer_count_actions, 69 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('coverage_70' as agency_key, 100 as action_count, 70 as usable_offer_count_actions, 70 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('coverage_34' as agency_key, 100 as action_count, 34 as usable_offer_count_actions, 34 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('coverage_35' as agency_key, 100 as action_count, 35 as usable_offer_count_actions, 35 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_49' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 39 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_50' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 40 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_65' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 52 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_support_49' as agency_key, 100 as action_count, 70 as usable_offer_count_actions, 49 as actions_with_at_least_one_offer, 30 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_support_50' as agency_key, 100 as action_count, 70 as usable_offer_count_actions, 50 as actions_with_at_least_one_offer, 30 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('single_coverage_69' as agency_key, 100 as action_count, 69 as usable_offer_count_actions, 69 as actions_with_at_least_one_offer, 40 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('supplier_34' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 34 as leading_supplier_funding_share_percent),
 struct('supplier_35' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 35 as leading_supplier_funding_share_percent),
 struct('supplier_50' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 50 as leading_supplier_funding_share_percent),
 struct('supplier_two' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 2 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 50 as leading_supplier_funding_share_percent),
 struct('supplier_unknown_20' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 20 as unknown_supplier_funding_share_percent, 50 as leading_supplier_funding_share_percent),
 struct('supplier_unknown_21' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 21 as unknown_supplier_funding_share_percent, 50 as leading_supplier_funding_share_percent),
 struct('fund_19' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 19 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('fund_20' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 20 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('fund_40' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 40 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('fund_over_100' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 150 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('fund_zero' as agency_key, 100 as action_count, 80 as usable_offer_count_actions, 80 as actions_with_at_least_one_offer, 20 as single_offer_actions, 0 as funding_increases, 20 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 0 as leading_supplier_funding_share_percent),
 struct('near_rounded_70' as agency_key, 100000 as action_count, 69999 as usable_offer_count_actions, 69999 as actions_with_at_least_one_offer, 1000 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent),
 struct('negative_offers' as agency_key, 100 as action_count, 69 as usable_offer_count_actions, 69 as actions_with_at_least_one_offer, 20 as single_offer_actions, 100 as funding_increases, 0 as funding_reductions, 3 as identified_positive_suppliers, 0 as unknown_supplier_funding_share_percent, 20 as leading_supplier_funding_share_percent)
 ])
),
e as (
 select *,
 100.0 * safe_divide(usable_offer_count_actions,action_count) offer_count_coverage_percent,
 100.0 * safe_divide(single_offer_actions,actions_with_at_least_one_offer) single_offer_percent,
 100.0 * safe_divide(funding_reductions,funding_increases) funding_reduction_to_increase_percent
 from cases
),
actual as (
 select e.agency_key,rule.review_type,rule.priority
 from e, {{ procurement_review_rules('e') }} as rule
 where rule.meets_rule
),
expected as (
 select * from unnest([
 struct('coverage_69' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'MEDIUM' as priority),
 struct('coverage_34' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'HIGH' as priority),
 struct('coverage_35' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'MEDIUM' as priority),
 struct('single_50' as agency_key,'SINGLE_OFFER_REVIEW' as review_type,'MEDIUM' as priority),
 struct('single_65' as agency_key,'SINGLE_OFFER_REVIEW' as review_type,'HIGH' as priority),
 struct('single_support_50' as agency_key,'SINGLE_OFFER_REVIEW' as review_type,'MEDIUM' as priority),
 struct('single_coverage_69' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'MEDIUM' as priority),
 struct('supplier_35' as agency_key,'SUPPLIER_CONCENTRATION_REVIEW' as review_type,'MEDIUM' as priority),
 struct('supplier_50' as agency_key,'SUPPLIER_CONCENTRATION_REVIEW' as review_type,'HIGH' as priority),
 struct('supplier_unknown_20' as agency_key,'SUPPLIER_CONCENTRATION_REVIEW' as review_type,'HIGH' as priority),
 struct('fund_20' as agency_key,'FUNDING_CHANGE_REVIEW' as review_type,'MEDIUM' as priority),
 struct('fund_40' as agency_key,'FUNDING_CHANGE_REVIEW' as review_type,'HIGH' as priority),
 struct('fund_over_100' as agency_key,'FUNDING_CHANGE_REVIEW' as review_type,'HIGH' as priority),
 struct('near_rounded_70' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'MEDIUM' as priority),
 struct('negative_offers' as agency_key,'OFFER_DATA_COMPLETENESS' as review_type,'MEDIUM' as priority)
 ])
),
missing as (
 select * from expected except distinct select * from actual
),
unexpected as (
 select * from actual except distinct select * from expected
),
duplicates as (
 select agency_key,review_type,priority from actual
 group by 1,2,3 having count(*)>1
)
select 'missing_expected_rule' issue,* from missing
union all select 'unexpected_rule',* from unexpected
union all select 'duplicate_rule',* from duplicates
