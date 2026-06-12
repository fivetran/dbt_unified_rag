{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__company_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__company_base')),
                staging_columns=get_hubspot_company_columns()
            )
        }}

        {{ fivetran_utils.apply_source_relation(package_name='rag_hubspot') }}

    from base
),

final as (

    select
        company_id,
        source_relation,
        is_company_deleted,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        company_name,
        description,
        created_date,
        industry,
        street_address,
        street_address_2,
        city,
        state,
        country,
        company_annual_revenue 
        
    from fields

) 

select *
from final