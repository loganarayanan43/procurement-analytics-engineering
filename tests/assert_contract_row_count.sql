with row_counts as (
    select
        (select count(*)
         from {{ source('procurement_raw', 'contract_actions') }}) as source_rows,
        (select count(*)
         from {{ ref('stg_contract_actions') }}) as staging_rows
)
select *
from row_counts
where source_rows != 500000
   or staging_rows != source_rows
