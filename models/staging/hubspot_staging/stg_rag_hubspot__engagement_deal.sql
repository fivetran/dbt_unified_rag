{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__engagement_deal_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__engagement_deal_base')),
                staging_columns=get_hubspot_engagement_deal_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='unified_rag') }}
    from base
),

final as (

    select
        engagement_id,
        deal_id,
        engagement_type,
        source_relation
    from fields  
)  

select *
from final