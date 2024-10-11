{{ config(enabled=(var('rag__using_hubspot', True) and var('rag_hubspot_sales_enabled', True) and var('rag_hubspot_engagement_enabled', True) and var('rag_hubspot_engagement_contact_enabled', True))) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='engagement_contact', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_engagement_contact',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','engagement_contact')),
                staging_columns=get_hubspot_engagement_contact_columns()
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
        contact_id,
        source_relation
    from fields  
)  

select *
from final