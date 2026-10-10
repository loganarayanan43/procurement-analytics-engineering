{{ config(materialized='table') }}

with bounds as (
    select
        min(action_date) as first_date,
        max(action_date) as last_date
    from {{ ref('int_contract_actions') }}
)

select
    calendar_date as date_key,
    extract(year from calendar_date) as calendar_year,
    extract(month from calendar_date) as calendar_month,
    format_date('%B', calendar_date) as month_name,
    extract(day from calendar_date) as day_of_month,
    format_date('%A', calendar_date) as weekday_name,
    extract(dayofweek from calendar_date) in (1, 7) as is_weekend
from bounds,
unnest(generate_date_array(first_date, last_date)) as calendar_date
