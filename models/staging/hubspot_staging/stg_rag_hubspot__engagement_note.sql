{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__engagement_note_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__engagement_note_base')),
                staging_columns=get_hubspot_engagement_note_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='unified_rag') }}
    from base
),

final as (

    select
        engagement_id,
        source_relation,
        engagement_type,
        cast(created_timestamp as {{ dbt.type_timestamp() }}) as created_timestamp,
        occurred_timestamp,
        owner_id,
        team_id,
        coalesce(note_body_preview, note_body, note_body_preview_html) as body,
        'engagement_note' as title
    from fields  
)  

select *
from final