
with base as (

    {{
        fivetran_utils.union_data(
            table_identifier='ticket_comment', 
            database_variable='rag_zendesk_database', 
            schema_variable='rag_zendesk_schema', 
            default_database=target.database,
            default_schema='rag_zendesk',
            default_variable='ticket_comment',
            union_schema_variable='rag_zendesk_union_schemas',
            union_database_variable='rag_zendesk_union_databases'
        )
    }}

),

fields as (

    select
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_zendesk','ticket_comment')),
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
