{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='contact', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_contact',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','contact')),
                staging_columns=get_hubspot_contact_columns()
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
        contact_id,
        source_relation,
        is_contact_deleted,
        calculated_merged_vids, -- will be null for BigQuery users until v3 api is rolled out to them
        email,
        contact_company,
        first_name,
        last_name,
        trim( {{ dbt.concat(['first_name', "' '", 'last_name']) }} ) as contact_name,
        cast(created_date as {{ dbt.type_timestamp() }}) as created_date,
        job_title,
        company_annual_revenue,
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced
        
    from fields  

) 

select *
from final