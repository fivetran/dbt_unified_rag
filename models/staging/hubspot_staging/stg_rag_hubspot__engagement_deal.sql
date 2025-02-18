{{ config(enabled=var('rag__using_hubspot', True)) }}

{% set base_table = ref('stg_rag_hubspot__engagement_deal_base') if var('rag_hubspot_union_schemas', []) != [] or var('rag_hubspot_union_databases', []) != [] else source('rag_hubspot', 'engagement_deal') %}

with base as (
    
    select *
    from {{ base_table }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(base_table),
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
