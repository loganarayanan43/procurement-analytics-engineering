{{ config(materialized='view') }}

{% set raw_table = source('procurement_raw', 'contract_actions') %}

{% if execute %}
    {% set columns = adapter.get_columns_in_relation(raw_table) %}
{% else %}
    {% set columns = [] %}
{% endif %}

select
{% if columns | length > 0 %}
    {% for column in columns %}
    nullif(trim({{ adapter.quote(column.name) }}), '')
        as {{ adapter.quote(column.name) }}{% if not loop.last %},{% endif %}
    {% endfor %}
{% else %}
    *
{% endif %}
from {{ raw_table }}
