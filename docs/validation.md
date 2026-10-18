# Validation status

## Supplied test definitions

The original archive contains 9 singular SQL tests; three prescriptive validation tests are now included (12 total):

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
| `assert_review_queue_logic` | Null-safe required fields, priority/evidence constraints and one-row-per-agency-and-signal validation |
| `assert_review_queue_thresholds` | Synthetic boundary and eligibility fixtures for four prescriptive review types |
| `assert_review_queue_reconciliation` | Independent real-data expected-vs-actual review output, priority, evidence and support checks |

Generic tests in `models/marts/marts.yml` cover dimension key uniqueness/nulls, fact transaction identifier uniqueness/nulls, and supplier/awarding-agency/date relationships.

## Evidence and limits

The project owner previously reported passing record-count and obligation-total checks. Supplied screenshots show the expected summary metrics. During repository preparation, the source archive, YAML structure, local model references, and documentation image paths were inspected. Original model and test bytes were preserved.

No warehouse connection, raw extract, or dbt run-results artifact was supplied for this packaging run. The SQL was not executed against BigQuery during packaging; this is not a claim that every supplied test has just passed.

For fresh execution evidence, run `dbt build` in the configured environment and record the date, dbt/adapter versions, source row count, and pass/fail summary. Review logs before sharing them because they may include environment details.

## Report evidence

The three images are cropped versions of supplied desktop screenshots. They are historical captures, not fresh exports after packaging. The overview retains the original source-note formatting. The competition capture was taken while its table was selected, and its original Power BI filter pane still showed an `agency_role` filter. Verify the final report configuration before replacing these with final exports.

## Added Power BI project

The supplied improved PBIP archive contains a legacy report.json report and a model.bim semantic model. The package retains their original bytes and excludes the 103,481,344-byte imported cache. JSON syntax and relative report/model paths were checked. There are three pages, nine DAX measures, four business tables, and two hidden automatic date tables. Power BI Desktop opening, rendering, refresh, and interactions remain untested here. Screenshots show the earlier layout.

## Prescriptive validation status

The [prescriptive dbt view](../models/reporting/rpt_procurement_review_queue.sql) and three rule-specific tests (output validity, synthetic boundaries, independent fact reconciliation) have **not been run against BigQuery** during this GitHub update. No agency review alerts or savings are claimed as observed outcomes. The current repository README describes a four-page PBIP including a DAX-based fourth page, while the prior packaging note above describes the earlier three-page PBIP. The four-page project has **not** been verified by opening or refreshing it in Power BI Desktop. Neither the DAX page nor its preview validates the separate dbt review queue.

## Smallest prescriptive evidence package

1. **Execution:** capture commit SHA, date, dbt and adapter versions, selected warehouse dataset, model materialization status, and sanitized `target/run_results.json` from a successful `dbt build`.
2. **Real output:** export counts by rule and priority, row count, agency count, representative real agency records (if any), and passing independent reconciliation. An empty queue must be explained by the eligibility rules, not assumed valid merely because an output-quality test passed.
3. **Boundaries:** capture passing `assert_review_queue_thresholds` results, including support gates, trigger thresholds and HIGH cutoffs. Thresholds remain illustrative, not regulatory standards.

The repository changes alone are not evidence of successful execution. Do not check in cloud credentials, raw source records, personally identifying contract data, or unsanitized warehouse logs.
