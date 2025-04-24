{% set model_enabled = (
        var('rag__using_hubspot', True)
        and not var('should_exclude_deal', False)
) %}
{{ config(enabled=model_enabled) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='deal_company', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_deal_company',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','deal_company')),
                staging_columns=get_hubspot_deal_company_columns()
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
        deal_id,
        company_id,
        source_relation
    from fields  
)  

select *
from final
