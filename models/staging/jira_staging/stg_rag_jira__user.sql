{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_jira__user_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_jira__user_base')),
                staging_columns=get_jira_user_columns()
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
        id as user_id,
        source_relation,
        email,
        locale,
        name as user_display_name,
        time_zone,
        username,
        _fivetran_synced
    from fields
)

select * 
from final