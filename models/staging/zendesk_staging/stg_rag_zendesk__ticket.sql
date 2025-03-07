{{ config(enabled=var('rag__using_zendesk', True)) }}

with base as (

    select *
    from {{ ref('stg_rag_zendesk__ticket_base') }}
),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_zendesk__ticket_base')),
                staging_columns=get_zendesk_ticket_columns()
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
        id as ticket_id,
        _fivetran_synced,
        _fivetran_deleted,
        assignee_id,
        brand_id,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
        description,
        due_at,
        group_id,
        external_id,
        is_public,
        organization_id,
        priority,
        recipient,
        requester_id,
        status,
        subject as title,
        problem_id,
        submitter_id,
        ticket_form_id,
        type,
        url,
        via_channel as created_channel,
        via_source_from_id as source_from_id,
        via_source_from_title as source_from_title,
        via_source_rel as source_rel,
        via_source_to_address as source_to_address,
        via_source_to_name as source_to_name,
        source_relation

    from fields
)

select * 
from final
