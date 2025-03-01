{{ config(enabled=var('rag__using_jira', True)) }}

{{
    fivetran_utils.union_data(
        table_identifier='comment', 
        database_variable='rag_jira_database', 
        schema_variable='rag_jira_schema', 
        default_database=target.database,
        default_schema='rag_jira',
        default_variable='jira_comment',
        union_schema_variable='rag_jira_union_schemas',
        union_database_variable='rag_jira_union_databases'
    )
}}