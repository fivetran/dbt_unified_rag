{% macro embedding_generation(table_reference, new_table_name) -%}
    {{ return(adapter.dispatch('embedding_generation', 'unified_rag')(table_reference, new_table_name)) }}
{%- endmacro %}

{% macro default__embedding_generation(table_reference, new_table_name) %}
  -- Only support for Snowflake at this time.
{% endmacro %}

{% macro snowflake__embedding_generation(table_reference, new_table_name) %}
create cortex search service if not exists {{ this.schema }}.{{ new_table_name }}
  on chunk
  attributes document_id, chunk_index
  warehouse = {{ target.warehouse }}
  target_lag = '1 days' --Will need to align on a target lag
as (
  select * from {{ table_reference }}
)
{% endmacro %}