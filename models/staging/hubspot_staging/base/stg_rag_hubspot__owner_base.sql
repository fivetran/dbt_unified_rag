{{ config(enabled=var('rag__using_hubspot', True)) }}

{% if var('rag_hubspot_union_schemas', []) | length > 0 or var('rag_hubspot_union_databases', []) | length > 0 %}

{{
    fivetran_utils.union_data(
        table_identifier='owner',
        database_variable='rag_hubspot_database',
        schema_variable='rag_hubspot_schema',
        default_database=target.database,
        default_schema='rag_hubspot',
        default_variable='hubspot_owner',
        union_schema_variable='rag_hubspot_union_schemas',
        union_database_variable='rag_hubspot_union_databases'
    )
}}

{% else %}

{{
    fivetran_utils.union_connections(
        connection_dictionary='rag_hubspot_sources',
        single_source_name='rag_hubspot',
        single_table_name='owner'
    )
}}

{% endif %}
