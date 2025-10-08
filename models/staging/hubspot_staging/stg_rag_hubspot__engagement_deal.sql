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

        {{ fivetran_utils.source_relation(
            union_schema_variable='rag_hubspot_union_schemas', 
            union_database_variable='rag_hubspot_union_databases') 
        }}
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
