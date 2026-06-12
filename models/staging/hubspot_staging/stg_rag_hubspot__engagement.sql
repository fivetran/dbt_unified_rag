{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__engagement_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__engagement_base')),
                staging_columns=get_hubspot_engagement_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='rag_hubspot') }}
    from base
),

final as (

    select
        id as engagement_id,
        created_timestamp,
        occurred_timestamp,
        owner_id,
        source_relation,
        portal_id,
        engagement_type,
        is_active
    from fields  
)  

select *
from final