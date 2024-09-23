{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='user', 
            database_variable='rag_jira_database', 
            schema_variable='rag_jira_schema', 
            default_database=target.database,
            default_schema='rag_jira',
            default_variable='jira_user',
            union_schema_variable='rag_jira_union_schemas',
            union_database_variable='rag_jira_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_jira','user')),
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