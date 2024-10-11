{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='deal', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_deal',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','deal')),
                staging_columns=get_hubspot_deal_columns()
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
        deal_name,
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