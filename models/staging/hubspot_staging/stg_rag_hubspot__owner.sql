{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    select *
    from {{ ref('stg_rag_hubspot__owner_base') }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_hubspot__owner_base')),
                staging_columns=get_hubspot_owner_columns()
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
        owner_id,
        source_relation,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_timestamp,
        email as owner_email,
        first_name,
        last_name, 
        portal_id,
        type as owner_type,
        cast(updated_at as {{ dbt.type_timestamp() }}) as updated_timestamp,
        trim( {{ dbt.concat(['first_name', "' '", 'last_name']) }} ) as owner_name
    from fields 
) 

select *
from final