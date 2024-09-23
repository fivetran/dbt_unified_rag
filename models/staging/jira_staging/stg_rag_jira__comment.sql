{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
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
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_jira','comment')),
                staging_columns=get_jira_comment_columns()
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
        author_id as author_user_id,
        source_relation,
        body,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        id as comment_id,
        issue_id,
        is_public,
        update_author_id as last_update_user_id,
        cast(updated as {{ dbt.type_timestamp() }}) as last_updated_at,
        _fivetran_synced
    from fields
)

select * 
from final