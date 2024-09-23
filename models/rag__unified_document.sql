{{
    config(
        materialized='table' if unified_rag.is_databricks_sql_warehouse() else 'incremental',
        partition_by = {'field': 'most_recent_chunk_update', 'data_type': 'date', 'granularity': 'month'}
            if target.type not in ['spark', 'databricks'] else ['most_recent_chunk_update'],
        cluster_by = ['unique_id'],
        unique_key='unique_id',
        incremental_strategy = 'insert_overwrite' if target.type in ('bigquery', 'databricks', 'spark') else 'delete+insert',
        file_format='delta' if unified_rag.is_databricks_sql_warehouse() else 'parquet',
        post_hook=["{{ unified_rag.embedding_generation(this,'rag__unified_embedding') }}"]
    )
}}

{%- set enabled_variables = ['rag__using_jira', 'rag__using_zendesk'] -%}
{%- set queries = [] -%}

{% for platform in enabled_variables %}
    {% if var(platform) == true -%}
        {%- set platform_name = platform | replace('rag__using_', '') -%}
        {%- set unique_key_fields = ['document_id', 'platform', 'source_relation'] -%}
        {% set select_statement = (
        "select \n" ~
        "   " ~ dbt_utils.generate_surrogate_key(unique_key_fields) ~ "as unique_id, \n" ~
        "   document_id, \n" ~
        "   platform, \n" ~
        "   source_relation, \n" ~
        "   most_recent_chunk_update, \n" ~
        "   chunk_index, \n" ~
        "   chunk_tokens_approximate, \n" ~
        "   chunk \n" ~
        "from " ~ ref('rag_' ~ platform_name ~ '__document')) %}

        {% if is_incremental() %}
            {% set select_statement = select_statement ~
        "\n where most_recent_chunk_update >= (select max(most_recent_chunk_update) from " ~ this ~ ")" %}
        {% endif %}

        {% do queries.append(select_statement) -%}
    {% endif -%}
{% endfor %}

{%- if queries | length > 1 -%}
    {{ queries | join(' union all ') }}
{%- else -%}
    {{ queries[0] }}
{%- endif -%}