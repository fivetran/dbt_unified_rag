{{ config(enabled=var('rag__using_hubspot', True)) }}
    
{{
    fivetran_utils.union_data(
        table_identifier='contact', 
        database_variable='rag_hubspot_database', 
        schema_variable='rag_hubspot_schema', 
        default_database=target.database,
        default_schema='rag_hubspot',
        default_variable='hubspot_contact',
        union_schema_variable='rag_hubspot_union_schemas',
        union_database_variable='rag_hubspot_union_databases'
    )
}}