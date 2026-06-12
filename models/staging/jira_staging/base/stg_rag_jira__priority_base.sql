{{ config(enabled=(var('rag__using_jira', True) and var('rag_jira_using_priorities', True))) }}

{% if var('rag_jira_union_schemas', []) | length > 0 or var('rag_jira_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='priority',
        database_variable='rag_jira_database',
        schema_variable='rag_jira_schema',
        default_database=target.database,
        default_schema='rag_jira',
        default_variable='jira_priority',
        union_schema_variable='rag_jira_union_schemas',
        union_database_variable='rag_jira_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='rag_jira_sources',
        single_source_name='rag_jira',
        single_table_name='priority'
    )
}}

{% endif %}
