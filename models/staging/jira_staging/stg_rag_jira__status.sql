{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='status', 
            database_variable='rag_jira_database', 
            schema_variable='rag_jira_schema', 
            default_database=target.database,
            default_schema='rag_jira',
            default_variable='jira_status',
            union_schema_variable='rag_jira_union_schemas',
            union_database_variable='rag_jira_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_jira','status')),
                staging_columns=get_jira_status_columns()
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
        description as status_description,
        id as status_id,
        source_relation,
        name as status_name,
        status_category_id,
        _fivetran_synced
    from fields
)

select * 
from final