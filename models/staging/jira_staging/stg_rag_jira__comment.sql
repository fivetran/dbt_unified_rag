{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_jira__comment_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_jira__comment_base')),
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