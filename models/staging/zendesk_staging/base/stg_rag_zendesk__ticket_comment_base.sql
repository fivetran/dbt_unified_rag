{{ config(enabled=var('rag__using_zendesk', True)) }}

{{
    fivetran_utils.union_data(
        table_identifier='ticket_comment', 
        database_variable='rag_zendesk_database', 
        schema_variable='rag_zendesk_schema', 
        default_database=target.database,
        default_schema='rag_zendesk',
        default_variable='zendesk_ticket_comment',
        union_schema_variable='rag_zendesk_union_schemas',
        union_database_variable='rag_zendesk_union_databases'
    )
}}