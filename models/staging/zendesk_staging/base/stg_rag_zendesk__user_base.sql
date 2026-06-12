{{ config(enabled=var('rag__using_zendesk', True)) }}

{% if var('rag_zendesk_union_schemas', []) | length > 0 or var('rag_zendesk_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='user',
        database_variable='rag_zendesk_database',
        schema_variable='rag_zendesk_schema',
        default_database=target.database,
        default_schema='rag_zendesk',
        default_variable='zendesk_user',
        union_schema_variable='rag_zendesk_union_schemas',
        union_database_variable='rag_zendesk_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='rag_zendesk_sources',
        single_source_name='rag_zendesk',
        single_table_name='user'
    )
}}

{% endif %}
