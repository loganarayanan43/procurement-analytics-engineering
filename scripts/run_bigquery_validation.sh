#!/usr/bin/env bash
set -euo pipefail
# Uses the operator's existing dbt-bigquery credentials and profile; never checks credentials into Git.
dbt debug
dbt build
python scripts/capture_dbt_evidence.py --run-results target/run_results.json
printf '\nNow inspect results and reconcile the reported metrics to the 500,000-action extract.\n'
