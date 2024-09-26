{{ config(enabled=(var('rag__using_jira', True) and var('rag_jira_using_priorities', True))) }}

with base as (
    
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
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_jira','priority')),
                staging_columns=get_jira_priority_columns()
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='rag_jira_union_schemas', 
            union_database_variable='rag_jira_union_databases') 
        }}
    from base
),

final as (
    
    select 
        description as priority_description,
        id as priority_id,
        source_relation,
        name as priority_name,
        _fivetran_synced
    from fields
)

select * 
from final