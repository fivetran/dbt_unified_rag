{{ config(enabled=var('rag__using_zendesk', True)) }}

with ticket_document as (
    select *
    from {{ ref('int_rag_zendesk__ticket_document') }}

), grouped as (
    select *
    from {{ ref('int_rag_zendesk__ticket_comment_documents_grouped') }}

), final as (
    select
        cast(ticket_document.ticket_id as {{ dbt.type_string() }}) as document_id,
        ticket_document.title,
        ticket_document.url_reference,
        'zendesk' as platform,
        ticket_document.source_relation,
        grouped.most_recent_chunk_update,
        grouped.chunk_index,
        grouped.chunk_tokens as chunk_tokens_approximate,
        {{ dbt.concat([
            "ticket_document.ticket_markdown",
            "'\\n\\n## COMMENTS\\n\\n'",
            "grouped.comments_group_markdown"]) }}
            as chunk
    from ticket_document
    join grouped
        on grouped.ticket_id = ticket_document.ticket_id
        and grouped.source_relation = ticket_document.source_relation
)

select *
from final