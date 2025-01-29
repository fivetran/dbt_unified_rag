{{ config(enabled=var('rag__using_zendesk', True)) }}

with ticket_comments as (
    select *
    from {{ ref('stg_rag_zendesk__ticket_comment') }}

), users as (
    select *
    from {{ ref('stg_rag_zendesk__user') }}

), comment_details as (
    select 
        ticket_comments.ticket_comment_id,
        ticket_comments.ticket_id,
        ticket_comments.source_relation,
        {{ unified_rag.coalesce_cast(["users.email", "'UNKNOWN'"], dbt.type_string()) }} as commenter_email,
        {{ unified_rag.coalesce_cast(["users.name", "'UNKNOWN'"], dbt.type_string()) }} as commenter_name,
        {{ unified_rag.coalesce_cast(["ticket_comments.created_at", "'1970-01-01 00:00:00'"], dbt.type_timestamp()) }} as comment_time,
        {{ unified_rag.coalesce_cast(["ticket_comments.body", "'UNKNOWN'"], dbt.type_string()) }} as comment_body
    from ticket_comments
    left join users
        on ticket_comments.user_id = users.user_id
        and ticket_comments.source_relation = users.source_relation
    where not coalesce(ticket_comments._fivetran_deleted, False)
        and not coalesce(users._fivetran_deleted, False)

), comment_markdowns as (
    select
        ticket_comment_id,
        ticket_id,
        source_relation,
        comment_time,
        cast(
            {{ dbt.concat([
                "'### message from '", "commenter_name", "' ('", "commenter_email", "')\\n'",
                "'##### sent @ '", "comment_time", "'\\n'",
                "comment_body"
            ]) }} as {{ dbt.type_string() }})
            as comment_markdown
    from comment_details

), comments_tokens as (
    select
        *,
        {{ unified_rag.count_tokens("comment_markdown") }} as comment_tokens
    from comment_markdowns

), truncated_comments as (
    select
        ticket_comment_id,
        ticket_id,
        source_relation,
        comment_time,
        case when comment_tokens > {{ var('document_max_tokens', 5000) }} then left(comment_markdown, {{ var('document_max_tokens', 5000) }} * 4)  -- approximate 4 characters per token
            else comment_markdown
            end as comment_markdown,
        case when comment_tokens > {{ var('document_max_tokens', 5000) }} then {{ var('document_max_tokens', 5000) }}
            else comment_tokens
            end as comment_tokens
    from comments_tokens
)

select *
from truncated_comments