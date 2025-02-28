{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='engagement', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_engagement',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','engagement')),
                staging_columns=get_hubspot_engagement_columns()
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