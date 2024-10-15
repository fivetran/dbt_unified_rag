{% macro search_generation(table_reference, new_search_name) -%}
    {{ return(adapter.dispatch('search_generation', 'unified_rag')(table_reference, new_search_name)) }}
{%- endmacro %}

{% macro default__search_generation(table_reference, new_search_name) %}
  -- Only support for Snowflake at this time.
{% endmacro %}

{% macro snowflake__search_generation(table_reference, new_search_name) %}
create cortex search service if not exists {{ this.schema }}.{{ new_search_name }}
  on chunk
  attributes unique_id
  warehouse = {{ target.warehouse }}
  target_lag = '1 days' --Will need to align on a target lag
as (
  select * from {{ table_reference }}
)
{% endmacro %}