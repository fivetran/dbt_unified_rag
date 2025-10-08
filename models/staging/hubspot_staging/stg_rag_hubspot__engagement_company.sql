{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__engagement_company_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__engagement_company_base')),
                staging_columns=get_hubspot_engagement_company_columns()
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
        source_relation,
        company_id
    from fields  
)  

select *
from final