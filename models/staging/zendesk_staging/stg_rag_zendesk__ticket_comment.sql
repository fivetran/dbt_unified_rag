{{ config(enabled=var('rag__using_zendesk', True)) }}

with base as (

    select *
    from {{ ref('stg_rag_zendesk__ticket_comment_base') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_zendesk__ticket_comment_base')),
                staging_columns=get_zendesk_ticket_comment_columns()
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='rag_zendesk_union_schemas', 
            union_database_variable='rag_zendesk_union_databases') 
        }}
        
    from base
),

final as (
    
    select 
        id as ticket_comment_id,
        _fivetran_synced,
        _fivetran_deleted,
        body,
        cast(created as {{ dbt.type_timestamp() }}) as created_at,
        public as is_public,
        ticket_id,
        user_id,
        source_relation
    from fields
)

select * 
from final
