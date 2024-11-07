{{ config(enabled=var('rag__using_zendesk', True)) }}

with tickets as (
    select *
    from {{ ref('stg_rag_zendesk__ticket') }}

), users as (
    select *
    from {{ ref('stg_rag_zendesk__user') }}

), ticket_details as (
    select
        tickets.ticket_id,
        replace(replace(cast(tickets.url as {{ dbt.type_string() }}), '/api/v2/tickets/', '/agent/tickets/'), '.json', '') as url_reference,
        tickets.source_relation,
        tickets.subject as ticket_name,
        {{ unified_rag.coalesce_cast(["users.name", "'UNKNOWN'"], dbt.type_string()) }} as user_name,
        {{ unified_rag.coalesce_cast(["users.email", "'UNKNOWN'"], dbt.type_string()) }} as created_by,
        tickets.created_at as created_on,
        {{ unified_rag.coalesce_cast(["tickets.status", "'UNKNOWN'"], dbt.type_string()) }} as status,
        {{ unified_rag.coalesce_cast(["tickets.priority", "'UNKNOWN'"], dbt.type_string()) }} as priority
    from tickets
    left join users
        on tickets.requester_id = users.user_id
        and tickets.source_relation = users.source_relation
    where not coalesce(tickets._fivetran_deleted, False)
        and not coalesce(users._fivetran_deleted, False)

), final as (
    select
        ticket_id,
        source_relation,
        url_reference,
        {{ dbt.concat([
            "'# Ticket : '", "ticket_name", "'\\n\\n'",
            "'Created By : '", "user_name", "' ('", "created_by", "')\\n'",
            "'Created On : '", "created_on", "'\\n'",
            "'Status : '", "status", "'\\n'",
            "'Priority : '", "priority"
        ]) }} as ticket_markdown
    from ticket_details
)

select 
    *,
    {{ unified_rag.count_tokens("ticket_markdown") }} as ticket_tokens
from final