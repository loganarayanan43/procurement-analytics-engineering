-- Independent fact-level reconciliation: detects missing and extra review rows,
-- incorrect eligibility, priority, denominators and support counts.
-- Unlike the fixture test, this works on the actual configured fact table.
with agency as (
 select agency_key, count(*) n,
 countif(number_of_offers_received >= 0) usable,
 countif(number_of_offers_received >= 1) reported,
 countif(number_of_offers_received = 1) single_count,
 sum(greatest(coalesce(obligation_amount,0),0)) increases,
 sum(greatest(-coalesce(obligation_amount,0),0)) reductions
 from {{ ref('fct_contract_actions') }} group by 1
),
supplier as (
 select agency_key,supplier_key,
 sum(greatest(coalesce(obligation_amount,0),0)) amt
 from {{ ref('fct_contract_actions') }} group by 1,2
),
supplier_summary as (
 select agency_key,
 countif(supplier_key != 'unknown' and amt > 0) suppliers,
 sum(if(supplier_key='unknown',amt,0)) unknown_amt,
 max(if(supplier_key != 'unknown',amt,null)) largest_amt
 from supplier group by 1
),
metrics as (
 select a.*,s.suppliers,
 100 * safe_divide(usable,n) coverage,
 100 * safe_divide(single_count,reported) single_share,
 100 * safe_divide(s.unknown_amt,increases) unknown_share,
 100 * safe_divide(s.largest_amt,increases) supplier_share,
 100 * safe_divide(reductions,increases) reduction_share
 from agency a left join supplier_summary s using(agency_key)
),
expected as (
 select agency_key,'OFFER_DATA_COMPLETENESS' review_type,
 if(coverage < 35,'HIGH','MEDIUM') priority,coverage pct,n-usable support,n action_count
 from metrics where n>=50 and coverage<70
 union all
 select agency_key,'SINGLE_OFFER_REVIEW',
 if(single_share>=65,'HIGH','MEDIUM'),single_share,reported,n
 from metrics where reported>=50 and coverage>=70 and single_share>=50
 union all
 select agency_key,'SUPPLIER_CONCENTRATION_REVIEW',
 if(supplier_share>=50,'HIGH','MEDIUM'),supplier_share,suppliers,n
 from metrics where n>=50 and increases>0 and suppliers>=3
 and unknown_share<=20 and supplier_share>=35
 union all
 select agency_key,'FUNDING_CHANGE_REVIEW',
 if(reduction_share>=40,'HIGH','MEDIUM'),reduction_share,n,n
 from metrics where n>=50 and increases>0 and reduction_share>=20
),
actual as (
 select agency_key,review_type,priority,evidence_percent_unrounded pct,
 supporting_record_count support,agency_action_count action_count
 from {{ ref('rpt_procurement_review_queue') }}
),
missing as (
 select e.* from expected e left join actual a
 on e.agency_key=a.agency_key and e.review_type=a.review_type
 where a.agency_key is null
),
extra as (
 select a.* from actual a left join expected e
 on e.agency_key=a.agency_key and e.review_type=a.review_type
 where e.agency_key is null
),
wrong as (
 select e.* from expected e join actual a
 on e.agency_key=a.agency_key and e.review_type=a.review_type
 where e.priority is distinct from a.priority
 or abs(e.pct-a.pct)>0.000001 or (e.pct is null) != (a.pct is null)
 or e.support is distinct from a.support
 or e.action_count is distinct from a.action_count
)
select 'missing' issue,agency_key,review_type from missing
union all select 'unexpected',agency_key,review_type from extra
union all select 'incorrect_values',agency_key,review_type from wrong
