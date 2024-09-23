{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='issue', 
            database_variable='rag_jira_database', 
            schema_variable='rag_jira_schema', 
            default_database=target.database,
            default_schema='rag_jira',
            default_variable='jira_issue',
            union_schema_variable='rag_jira_union_schemas',
            union_database_variable='rag_jira_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_jira','issue')),
                staging_columns=get_jira_issue_columns()
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
        id as issue_id,
        source_relation,
        coalesce(original_estimate, _original_estimate) as original_estimate_seconds,
        coalesce(remaining_estimate, _remaining_estimate) as remaining_estimate_seconds,
        coalesce(time_spent, _time_spent) as time_spent_seconds,
        assignee as assignee_user_id,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        cast(resolved  as {{ dbt.type_timestamp() }}) as resolved_at,
        creator as creator_user_id,
        description as issue_description,
        due_date,
        environment,
        issue_type as issue_type_id,
        key as issue_key,
        parent_id as parent_issue_id,
        priority as priority_id,
        project as project_id,
        reporter as reporter_user_id,
        resolution as resolution_id,
        status as status_id,
        cast(status_category_changed as {{ dbt.type_timestamp() }}) as status_changed_at,
        summary as issue_name,
        cast(updated as {{ dbt.type_timestamp() }}) as updated_at,
        work_ratio,
        _fivetran_synced
    from fields
    where not coalesce(_fivetran_deleted, false)
)

select * 
from final