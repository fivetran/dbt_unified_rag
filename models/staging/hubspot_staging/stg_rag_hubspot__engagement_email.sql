{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='engagement_email', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_engagement_email',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','engagement_email')),
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
        email_subject,
        email_to_email,
        email_from_email,
        email_cc_email
    from fields  
)  

select *
from final