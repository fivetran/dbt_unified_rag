{{ config(enabled=(var('rag__using_jira', True) and var('rag_jira_using_priorities', True))) }}

with base as (
    
    select *
    from {{ ref('stg_rag_jira__priority_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_jira__priority_base')),
                staging_columns=get_jira_priority_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='rag_jira') }}
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