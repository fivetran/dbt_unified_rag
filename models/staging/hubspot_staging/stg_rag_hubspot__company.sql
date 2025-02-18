{{ config(enabled=var('rag__using_hubspot', True)) }}

{% set base_table = ref('stg_rag_hubspot__company_base') if var('rag_hubspot_union_schemas', []) != [] or var('rag_hubspot_union_databases', []) != [] else source('rag_hubspot', 'company') %}

with base as (
    
    select *
    from {{ base_table }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(base_table),
                staging_columns=get_hubspot_company_columns()
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