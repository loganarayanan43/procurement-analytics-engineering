# Prescriptive analysis: evidence-led procurement review queue

## Purpose

The existing report answers **what happened**: obligations, suppliers, agencies, and offer-count coverage. This extension proposes **what an analyst should examine next**. It is a **rule-based, explainable review queue**, not a predictive model, a formal risk score, or a procurement compliance decision.

The new dbt view is `models/reporting/rpt_procurement_review_queue.sql`. It creates **one row per awarding agency and triggered review rule** from `fct_contract_actions`. It does not overwrite facts or change existing Power BI relationships. Review results are created when dbt runs; no rows are embedded as synthetic findings.

## Existing evidence from the 500,000-action extract

- **Offer data completeness:** usable offer counts are available for **34.44%** of actions. Priority: review missing/invalid data before comparing competition.
- **Competition signal:** **36.10%** of actions reporting at least one offer report exactly one offer. This is not 36.10% of all actions. Priority: sample relevant solicitations only where coverage and sample size meet minimum requirements.
- **Supplier concentration:** top five identified suppliers account for **21.26%** of all positive obligations in the extract. Priority: examine agency-level concentration, business context, and contract categories; do not assume dependence or misconduct.
- **Funding interpretation:** **$135.77B** of increases and **$6.49B** of reductions correspond to **$129.28B** net obligations. Priority: check large adjustments, not label reductions as savings.

These are descriptive results that **motivate** the review rules, not observed outputs of the new view. No newly derived agency-level priorities are claimed until dbt is executed.

## Review rules (illustrative thresholds, not regulatory standards)

| Rule | Minimum support and trigger | Example recommended action |
|---|---|---|
| `OFFER_DATA_COMPLETENESS` | At least 50 agency actions; usable offer-count coverage below 70% (HIGH below 35%) | Audit source reporting and field mapping; sample missing/invalid records |
| `SINGLE_OFFER_REVIEW` | At least 50 actions with >=1 reported offer, coverage >=70%, single-offer share >=50% (HIGH >=65%) | Review solicitations, procurement methods, and documented competition exceptions |
| `SUPPLIER_CONCENTRATION_REVIEW` | At least 50 agency actions, at least 3 identified suppliers with positive obligations, unknown-supplier funding share <=20%, leading supplier share >=35% (HIGH >=50%) | Evaluate award concentration by category and examine sourcing options with the business owner |
| `FUNDING_CHANGE_REVIEW` | At least 50 agency actions, positive increases, reduction/increase ratio >=20% (HIGH >=40%) | Review large contract modifications and reconcile finance explanations |

**Denominators:** offer-count coverage uses *all awarding-agency actions*; single-offer share uses only actions with **at least one** reported offer. Supplier concentration divides the **largest identified supplier's positive obligations** by **all positive obligations of the awarding agency** (including unknown-supplier obligations). Funding-change ratio divides the positive magnitude of negative obligations by positive obligations. Unknown supplier share is checked before concentration rules fire.

**Scope:** rules group by awarding agency only. Never aggregate awarding and funding agency roles as if they were distinct actions.

## Prioritization and stakeholder workflow

1. Materialize/refresh the fact and queue with `dbt build`; inspect `dbt test --select assert_review_queue_logic`.
2. Sort HIGH ahead of MEDIUM; within priority, use evidence, denominator/sample count and analyst capacity to plan review.
3. Validate a sample of action-level source records, supplier identifiers and contract documentation.
4. Discuss exceptions with agency/procurement owners. Record a decision: no action, additional data collection, targeted review, or policy/process improvement.
5. Track the **share of reviewed items resolved**, offer-data completeness improvements, and documented follow-up actions. Do not report unverified dollar savings.

The `evidence_percent` column is **not a risk probability**, and different review types cannot be directly compared by magnitude. The `supporting_record_count` changes interpretation by rule: missing/unusable records, actions with >=1 reported offer, identified suppliers with increases, or total actions.

## Query example

```sql
select
  agency_name,
  review_type,
  priority,
  evidence_metric,
  evidence_percent,
  agency_action_count,
  supporting_record_count,
  recommended_next_step,
  interpretation_guardrail
from `YOUR_PROJECT.YOUR_DBT_DATASET.rpt_procurement_review_queue`
order by case priority when 'HIGH' then 0 else 1 end,
         agency_action_count desc,
         review_type;
```

## How this fits Power BI

The shipped PBIP now contains a fourth **Prescriptive Analysis** page with DAX-based agency priorities and recommendations. It uses the existing imported fact and agency dimensions, not the separate dbt review queue. The two implementations share review intent but are not a single shared implementation: SQL produces one row per triggered rule, while Power BI presents the highest-priority signal. Desktop rendering, interaction, and refresh have not been tested; the fourth-page image is a design preview rather than a genuine Power BI Desktop capture. See [execution validation](execution-validation.md).

## Limitations and validation

- This is a **nonrandom extract of 500,000 actions over September 10–30, 2025**, not a full fiscal year. Findings cannot establish trends, national prevalence, savings opportunities or causal outcomes.
- Offer-count missingness is substantial. A single offer does not indicate misconduct; a reduction does not mean saved cash; supplier concentration can reflect legitimate specialized purchasing.
- Rule cutoffs are **transparent illustrative triage defaults**. Confirm with procurement stakeholders before operational use.
- Run `dbt build` in BigQuery to verify the new SQL model and its singular test. No new view results or report-refresh validation are asserted by this commit.

## Additional validation coverage

The repository now includes `tests/assert_review_queue_thresholds.sql`, which independently reconstructs review signals and priorities from the awarding-agency summary and fact to compare actual queue output. Boundary specification tests cover 35%/70% offer coverage, 50%/65% single-offer thresholds, 35%/50% supplier share and 20%/40% funding adjustments. This increases verification coverage, but remains **unexecuted against the BigQuery dataset** until an authenticated `dbt build` passes.
