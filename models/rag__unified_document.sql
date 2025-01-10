{{
    config(
        materialized='table' if unified_rag.is_databricks_sql_warehouse() else 'incremental',
        partition_by = {'field': 'update_date', 'data_type': 'date'}
            if target.type not in ['spark', 'databricks'] else ['update_date'],
        cluster_by = ['update_date'],
        unique_key='unique_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta'
    )
}}

{%- set enabled_variables = ['rag__using_jira', 'rag__using_zendesk', 'rag__using_hubspot'] -%}
{%- set queries = [] -%}

{% for platform in enabled_variables %}
    {% if var(platform, true) == true -%}
        {%- set platform_name = platform | replace('rag__using_', '') -%}
        {%- set unique_key_fields = ['document_id', 'platform', 'chunk_index', 'source_relation'] -%}
        {% set select_statement = (
        "select \n" ~
        "   " ~ dbt_utils.generate_surrogate_key(unique_key_fields) ~ " as unique_id, \n" ~
        "   document_id, \n" ~
        "   title, \n" ~ 
        "   url_reference, \n" ~
        "   platform, \n" ~
        "   source_relation, \n" ~
        "   most_recent_chunk_update, \n" ~
        "   cast(most_recent_chunk_update as date) as update_date, \n" ~
        "   chunk_index, \n" ~
        "   chunk_tokens_approximate, \n" ~
        "   chunk \n" ~
        "from " ~ ref('rag_' ~ platform_name ~ '__document')) %}

        {% if is_incremental() %}
            {% set select_statement = select_statement ~
        "\n where cast(most_recent_chunk_update as date) >= (select max(update_date) from " ~ this ~ ")" %}
        {% endif %}

        {% do queries.append(select_statement) -%}
    {% endif -%}
{% endfor %}

{%- if queries | length > 1 -%}
    {{ queries | join(' union all ') }}
{%- else -%}
    {{ queries[0] }}
{%- endif %}