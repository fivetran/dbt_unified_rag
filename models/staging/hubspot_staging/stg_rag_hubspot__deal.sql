{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__deal_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__deal_base')),
                staging_columns=get_hubspot_deal_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='rag_hubspot') }}
    from base
),

final as (

    select
        deal_name as title,
        source_relation,
        cast(closed_date as {{ dbt.type_timestamp() }}) as closed_date,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        is_deal_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        deal_id,
        cast(deal_pipeline_id as {{ dbt.type_string() }}) as deal_pipeline_id,
        cast(deal_pipeline_stage_id as {{ dbt.type_string() }}) as deal_pipeline_stage_id,
        owner_id,
        portal_id,
        description,
        amount

    from fields  

) 

select *
from final