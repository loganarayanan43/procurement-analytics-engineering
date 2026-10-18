#!/usr/bin/env python3
"""Emit a sanitized dbt run summary ONLY after a successful real dbt build.

This is a RECORDING tool, not a BigQuery runner. It rejects absent/incomplete
run_results.json and does not manufacture successful execution evidence.
"""
import argparse
import datetime as dt
import json
import pathlib
import sys

REQUIRED = {
    'model': 'rpt_procurement_review_queue',
    'review_test': 'assert_review_queue_logic',
    'threshold_test': 'assert_review_queue_thresholds',
}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--run-results',default='target/run_results.json')
    parser.add_argument('--out',default=None)
    args=parser.parse_args()
    path=pathlib.Path(args.run_results)
    if not path.is_file():
        sys.exit(f'NOT VERIFIED: {path} missing. Execute dbt build in BigQuery first.')
    data=json.loads(path.read_text(encoding='utf-8'))
    results=data.get('results') or []
    failing=[x for x in results if x.get('status') not in ('success','pass')]
    if failing:sys.exit(f'NOT VERIFIED: {len(failing)} dbt result(s) are not passing.')
    def found(name):
        return any(x.get('unique_id','').split('.')[-1].startswith(name) and x.get('status') in ('success','pass') for x in results)
    missing=[v for v in REQUIRED.values() if not found(v)]
    if missing:sys.exit('NOT VERIFIED: expected prescriptive model/test runs missing: '+', '.join(missing))
    meta=data.get('metadata') or {}
    if not meta.get('invocation_id'):
        sys.exit('NOT VERIFIED: missing invocation ID in dbt run-results metadata')
    output={
      'claim':'dbt execution succeeded according to actual dbt run_results.json; no Power BI claim',
      'generated_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
      'dbt_invocation_id':meta['invocation_id'],
      'dbt_version':meta.get('dbt_version'),
      'dbt_generated_at':meta.get('generated_at'),
      'result_count':len(results),
      'model_and_test_status':{v:'PASS' for v in REQUIRED.values()},
      'total_execution_seconds':data.get('elapsed_time'),
      'environment':'Authenticated BigQuery (confirm profile/target separately)',
      'source_row_count':'not captured; add query evidence before claiming exact source reconciliation',
      'powerbi_desktop_refresh':'not tested by this script'
    }
    target=pathlib.Path(args.out or f'validation-evidence/dbt_{meta["invocation_id"][:12]}.json')
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_text(json.dumps(output,indent=2)+'\n',encoding='utf-8')
    print(f'PASS: sanitized report created: {target}. Review before publishing.')
    return 0
if __name__=='__main__':raise SystemExit(main())
