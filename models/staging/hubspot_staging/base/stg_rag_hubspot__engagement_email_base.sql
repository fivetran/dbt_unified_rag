{{ config(enabled=var('rag__using_hubspot', True) and (var('rag_hubspot_union_schemas', []) != [] or var('rag_hubspot_union_databases', []) != [])) }}

{{
    fivetran_utils.union_data(
        table_identifier='engagement_email', 
        database_variable='rag_hubspot_database', 
        schema_variable='rag_hubspot_schema', 
        default_database=target.database,
        default_schema='rag_hubspot',
        default_variable='hubspot_engagement_email',
        union_schema_variable='rag_hubspot_union_schemas',
        union_database_variable='rag_hubspot_union_databases'
    )
}}