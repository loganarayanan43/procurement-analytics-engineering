# Real execution validation: BigQuery + Power BI Desktop

**Current status:** The repository's static integrity checks can run without cloud access. As of this document, there is **no verified new BigQuery `dbt build` result** for the prescriptive extension and **no independently captured Power BI Desktop render/refresh result** for page four. Do not report either as passed until the steps below are performed.

## 1. BigQuery: run the prescriptive model and tests

Requirements: access to the original 500,000-row `procurement_raw.contract_actions` extract in Google BigQuery, an authenticated Google Cloud identity allowed to run BigQuery jobs, and Python with `dbt-bigquery` installed. Set your local `profiles.yml` from `profiles.yml.example` and make sure the BigQuery source declaration matches your project. Do not commit your real profile, credentials, logs, or service-account files.

Run **from repository root**, in a terminal with your BigQuery credentials configured:

```bash
python -m pip install dbt-bigquery
# Set DBT_PROFILES_DIR if your profile is not in ~/.dbt
dbt debug
dbt build
python scripts/capture_dbt_evidence.py --run-results target/run_results.json
```

The new singular tests are:

- `tests/assert_review_queue_logic.sql`: required shape, allowed values, nonnegative evidence and unique agency/rule keys.
- `tests/assert_review_queue_thresholds.sql`: independently reconstructs eligible review signals and priorities from the existing awarding-agency summary and source fact; flags missing/extra rows, wrong priorities, evidence values and support counts. **This test does not prove that thresholds are statistically or legally justified.**

For the original data extract, also confirm row count = **500,000**, funding increases ~$135.77B, funding reductions ~$6.49B, and net obligations ~$129.28B, using your actual warehouse queries and dbt output. dbt failures must not be hidden.

`capture_dbt_evidence.py` refuses to claim success if the specified real `run_results.json` is absent, has failing nodes, or lacks the prescriptive view and both tests. The sanitized evidence summary is created under `validation-evidence/`. Inspect it before publishing. A recorded run shows execution status for that environment/data snapshot; it does **not** certify every business rule's policy appropriateness.

## 2. Power BI Desktop: native render/refresh verification

This step **requires Power BI Desktop on Windows**; checking that the `.pbip` JSON is valid is not equivalent to rendering it. Open the `powerbi/Procurement_Funding_Improved.pbip` file in Desktop **after extracting a complete working Power BI project with its report and semantic-model folders**. The public GitHub repository intentionally excludes the imported 103 MB Power BI data cache, so a user cloning GitHub must authenticate/refresh its existing four BigQuery source queries.

Record the following checks in a short checklist and capture actual Desktop screenshots:

1. The PBIP opens without data/model errors; four pages appear: Procurement Overview, Supplier Analysis, Competition & Data Quality, Prescriptive Analysis.
2. The Prescriptive Analysis page visibly renders **four KPI cards and the awarding-agency priorities table** with real values, no broken/blank-field visuals or DAX errors.
3. The awarding-agency slicer changes the row(s), severity signal and recommended next step. Verify both a high-priority agency and a no-threshold/monitor agency, if present.
4. Use **Home → Refresh** with valid BigQuery credentials. Check successful refresh completion, date range and record count. Confirm original three pages still work and remain reconciled.
5. Save and reopen the `.pbip`, confirm the fourth page persists, then capture an **actual screenshot from Power BI Desktop**, not a generated mockup.
6. Capture a small evidence note stating local Desktop version, date, dataset refresh time, whether the refresh succeeded, and which observations support the agency priority table. Do not publish account credentials or connection secrets.

The preview at `docs/images/prescriptive-analysis-preview.png` is a **design preview only**. Replace it with a genuine Desktop screenshot only after step 2 passes and label it accordingly.

## 3. Static checks available today

Run:

```bash
python scripts/validate_repository.py
```

GitHub Actions runs the same check on pushes and pull requests. This checks project file structure, all page/measure references, relationship column references, document image links and the presence of both prescriptive SQL tests. It **does not** execute BigQuery or Power BI Desktop and must not be represented as such.
