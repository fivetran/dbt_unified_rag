{{ config(enabled=var('rag__using_jira', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_jira__status_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_jira__status_base')),
                staging_columns=get_jira_status_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='unified_rag') }}
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