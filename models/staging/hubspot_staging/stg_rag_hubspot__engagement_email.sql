{{ config(enabled=var('rag__using_hubspot', True)) }}

{% set base_table = ref('stg_rag_hubspot__engagement_email_base') if var('rag_hubspot_union_schemas', []) != [] or var('rag_hubspot_union_databases', []) != [] else source('rag_hubspot', 'engagement_email') %}

with base as (
    
    select *
    from {{ base_table }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(base_table),
                staging_columns=get_hubspot_engagement_email_columns()
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
        engagement_type,
        cast(created_timestamp as {{ dbt.type_timestamp() }}) as created_timestamp,
        occurred_timestamp,
        owner_id,
        team_id,
        coalesce(body_preview, body_preview_html, email_text, email_html) as body,
        email_subject as title,
        email_to_email,
        email_from_email,
        email_cc_email
    from fields  
)  

select *
from final