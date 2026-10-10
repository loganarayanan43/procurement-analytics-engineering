select
    'Agency' as report_name,
    concat(agency_role, ':', agency_key) as duplicate_key,
    count(*) as record_count
from {{ ref('rpt_agency_summary') }}
group by agency_role, agency_key
having count(*) > 1

union all

select
    'Industry',
    industry_key,
    count(*)
from {{ ref('rpt_industry_summary') }}
group by industry_key
having count(*) > 1
