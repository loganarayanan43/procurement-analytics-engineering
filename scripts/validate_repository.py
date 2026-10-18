#!/usr/bin/env python3
"""Offline integrity checks. Does NOT execute dbt, DAX, BigQuery, or Power BI Desktop."""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
CHECKS: list[str] = []


def check(ok: bool, msg: str) -> None:
    if ok:
        CHECKS.append(msg)
        print('PASS:', msg)
    else:
        ERRORS.append(msg)
        print('FAIL:', msg)


def load(path: str):
    return json.loads((ROOT / path).read_text(encoding='utf-8-sig'))


def verify_dbt():
    models = {p.stem: p for p in (ROOT/'models').rglob('*.sql')}
    check(len(models) == 12, f'dbt models present: {len(models)} (expected 12)')
    singular = list((ROOT/'tests').glob('assert_*.sql'))
    check(len(singular) >= 10, f'singular tests present: {len(singular)} (expected >=10)')
    names = set(models)
    for model in models.values():
        sql = model.read_text(encoding='utf-8-sig')
        for ref in re.findall(r"ref\(\s*['\"]([^'\"]+)['\"]\s*\)", sql):
            check(ref in names, f'{model.relative_to(ROOT)} reference: {ref}')
    for test in singular:
        sql = test.read_text(encoding='utf-8-sig')
        for ref in re.findall(r"ref\(\s*['\"]([^'\"]+)['\"]\s*\)", sql):
            check(ref in names, f'{test.relative_to(ROOT)} reference: {ref}')
    check('rpt_procurement_review_queue' in names, 'prescriptive dbt view tracked')
    check((ROOT/'tests/assert_review_queue_logic.sql').exists(), 'prescriptive structural test tracked')
    check((ROOT/'tests/assert_review_queue_thresholds.sql').exists(), 'independent prescriptive trigger/threshold reconciliation test tracked')


def verify_powerbi():
    base = ROOT/'powerbi'
    pbip = load('powerbi/Procurement_Funding_Improved.pbip')
    report = load('powerbi/Procurement_Funding_Improved.Report/report.json')
    bim = load('powerbi/Procurement_Funding_Improved.SemanticModel/model.bim')
    pbir = load('powerbi/Procurement_Funding_Improved.Report/definition.pbir')
    check(bool(pbip.get('artifacts')), 'PBIP lists report artifact')
    check(pbir['datasetReference']['byPath']['path'] == '../Procurement_Funding_Improved.SemanticModel', 'report dataset relative reference intact')
    check(len(report['sections']) == 4, f'Power BI pages: {len(report["sections"])} (expected 4)')
    page_names = [s.get('displayName') for s in report['sections']]
    check(page_names == ['Procurement Overview','Supplier Analysis','Competition & Data Quality','Prescriptive Analysis'], 'Power BI page names/order match documentation')
    tables = {t['name']: t for t in bim['model']['tables']}
    actual_cols = {k: {c['name'] for c in v.get('columns', [])} for k,v in tables.items()}
    measures = {k: {m['name'] for m in v.get('measures', [])} for k,v in tables.items()}
    check(len(tables) == 6, 'Power BI model retains 6 tables (including 2 local date tables)')
    check(len(measures.get('fct_contract_actions',[])) == 17, 'Power BI model has 17 measures (9 original + 8 prescriptive)')
    required = {'Prescriptive Offer Data Gap','Prescriptive Data Coverage Severity','Prescriptive Single Offer Severity','Prescriptive Supplier Severity','Prescriptive Funding Severity','Prescriptive Review Priority','Prescriptive Primary Signal','Prescriptive Recommended Next Step'}
    check(required <= measures.get('fct_contract_actions',set()), 'all eight prescriptive DAX measures present')
    visual_total=0
    for page in report['sections']:
        p = page['displayName']
        check(int(page['width']) == 1600 and int(page['height']) == 900, f'{p}: canvas 1600x900')
        for container in page.get('visualContainers', []):
            visual_total += 1
            try:
                cfg = json.loads(container['config'])
            except (ValueError,KeyError) as err:
                check(False, f'{p}: visual config invalid: {err}')
                continue
            for bucket, items in (cfg.get('singleVisual',{}).get('projections') or {}).items():
                for x in items:
                    ref = x.get('queryRef','')
                    # Original supplier tooltip uses a supported aggregation: Min(dim_supplier.supplier_key)
                    m = re.fullmatch(r'(?:Min|Max|Sum|Count|CountNonNull)\(([^)]+)\)',ref)
                    if m: ref=m.group(1)
                    if '.' not in ref:
                        check(False,f'{p}: unrecognized {bucket} field reference {ref}')
                        continue
                    table,field = ref.split('.',1)
                    check(table in tables and field in (actual_cols.get(table,set())|measures.get(table,set())), f'{p}: resolved {table}.{field}')
    check(visual_total == 45, f'Power BI report has {visual_total} visuals (expected 45)')
    check((ROOT/'docs/images/prescriptive-analysis-preview.png').is_file(), 'prescriptive design preview image exists')
    for r in bim['model'].get('relationships',[]):
        check(r['fromColumn'] in actual_cols.get(r['fromTable'],set()) and r['toColumn'] in actual_cols.get(r['toTable'],set()),f"relationship {r['fromTable']}->{r['toTable']} resolves")


def verify_docs():
    paths=['README.md','docs/architecture-and-metrics.md','docs/prescriptive-analysis.md','docs/validation.md']
    for f in paths:
        txt=(ROOT/f).read_text(encoding='utf-8-sig')
        for relative in re.findall(r'!?(?:\[[^\]]*\])\(([^)]+)\)',txt):
            if relative.startswith(('http://','https://','#')): continue
            dest=(ROOT/f).parent/relative
            check(dest.is_file(), f'{f}: linked {relative} exists')
    source=(ROOT/'README.md').read_text(encoding='utf-8-sig')
    check('docs/images/prescriptive-analysis-preview.png' in source, 'README links prescriptive image')
    check('not a live Power BI' in source.lower() or 'not a Power BI Desktop' in source, 'README labels preview as non-live')


def main():
    verify_dbt(); verify_powerbi(); verify_docs()
    print(f'\n{len(CHECKS)} passed; {len(ERRORS)} failed. OFFLINE structural validation only.')
    if ERRORS:
        for e in ERRORS: print('ERROR:',e,file=sys.stderr)
        return 1
    print('BigQuery execution and native Power BI Desktop rendering remain separately unverified.')
    return 0

if __name__=='__main__':sys.exit(main())
