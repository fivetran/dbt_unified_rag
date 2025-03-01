{{ config(enabled=var('rag__using_zendesk', True)) }}

with base as (

    select *
    from {{ ref('stg_rag_zendesk__user_base') }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(ref('stg_rag_zendesk__user_base')),
                staging_columns=get_zendesk_user_columns()
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
        id as user_id,
        external_id,
        _fivetran_synced,
        _fivetran_deleted,
        cast(last_login_at as {{ dbt.type_timestamp() }}) as last_login_at,
        cast(created_at as {{ dbt.type_timestamp() }}) as created_at,
        cast(updated_at as {{ dbt.type_timestamp() }}) as updated_at,
        email,
        name,
        organization_id,
        phone,
        role,
        ticket_restriction,
        time_zone,
        active as is_active,
        suspended as is_suspended,
        source_relation

    from fields
)

select * 
from final
