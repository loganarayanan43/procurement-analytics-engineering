# Validation status

## Supplied test definitions

The original archive contains 9 singular SQL tests; two prescriptive rule validation tests have now been added (11 total):

| Test | Main check |
|---|---|
| `assert_contract_row_count` | Raw count is 500,000; staging preserves it |
| `assert_contract_action_quality` | Expected count, transaction identifiers, dates, amounts, offer casts, and missing flags |
| `assert_fact_reconciliation` | Row count, signed obligations, and absolute obligations preserved through dimension joins |
| `assert_funding_agency_relationship` | Funding agency join preserves count/amount and has no unmatched keys |
| `assert_procurement_overview` | Funding identity, action categories, and offer-quality categories reconcile |
| `assert_daily_report_reconciliation` | Daily totals reconcile to overview |
| `assert_supplier_report_reconciliation` | Supplier totals reconcile to overview |
| `assert_agency_industry_reconciliation` | Each agency role and industry totals reconcile to overview |
| `assert_summary_grains` | Agency role/key and industry key groups are unique |
| `assert_review_queue_logic` | Review queue priority, evidence and one-row-per-agency-and-signal validation |
| `assert_review_queue_thresholds` | Independently reconcile review eligibility, severity thresholds, evidence values and counts against underlying agency/fact summaries |

Generic tests in `models/marts/marts.yml` cover dimension key uniqueness/nulls, fact transaction identifier uniqueness/nulls, and supplier/awarding-agency/date relationships.

## Evidence and limits

The project owner previously reported passing record-count and obligation-total checks. Supplied screenshots show the expected summary metrics. During repository preparation, the source archive, YAML structure, local model references, and documentation image paths were inspected. Original model and test bytes were preserved.

No warehouse connection, raw extract, or dbt run-results artifact was supplied for this packaging run. The SQL was not executed against BigQuery during packaging; this is not a claim that every supplied test has just passed.

For fresh execution evidence, run `dbt build` in the configured environment and record the date, dbt/adapter versions, source row count, and pass/fail summary. Review logs before sharing them because they may include environment details.

## Report evidence

The three images are cropped versions of supplied desktop screenshots. They are historical captures, not fresh exports after packaging. The overview retains the original source-note formatting. The competition capture was taken while its table was selected, and its original Power BI filter pane still showed an `agency_role` filter. Verify the final report configuration before replacing these with final exports.

## Added Power BI project

The supplied improved PBIP archive contains a legacy report.json report and a model.bim semantic model. The package retains their original bytes and excludes the 103,481,344-byte imported cache. JSON syntax and relative report/model paths were checked. The current committed project contains four pages, 17 DAX measures, four business tables, and two hidden automatic date tables. Power BI Desktop opening, rendering, refresh, and interactions remain untested here. Screenshots show the earlier layout.

## Prescriptive validation status

The newly added [prescriptive dbt view](../models/reporting/rpt_procurement_review_queue.sql) and [test](../tests/assert_review_queue_logic.sql) have **not been run against BigQuery** during this GitHub update. No agency review alerts or savings are claimed as observed outcomes. The current Power BI project has a fourth page with eight additional DAX measures. Static checks inspect field references, but Power BI Desktop execution, native rendering, filtering and BigQuery refresh remain **unverified**.

## Automated and native execution evidence

The repository now includes an offline [integrity validator](../scripts/validate_repository.py), a GitHub Actions static-validation workflow, an *explicitly manual* billable BigQuery/dbt validation workflow, and an evidence recorder that rejects missing or failed dbt run results. See the [execution validation guide](execution-validation.md). The static tests do not prove SQL ran in BigQuery or that Power BI Desktop opened/refreshed successfully. Until authenticated execution and native Desktop screenshots are captured, both high-priority verification items remain open.
