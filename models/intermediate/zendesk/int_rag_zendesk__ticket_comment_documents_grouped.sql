{{ config(enabled=var('rag__using_zendesk', True)) }}

with filtered_comment_documents as (
    select *
    from {{ ref('int_rag_zendesk__ticket_comment_document') }}
),

grouped_comment_documents as (
    select 
        ticket_id,
        source_relation,
        comment_markdown,
        comment_tokens,
        comment_time,
        sum(comment_tokens) over (
        partition by ticket_id 
        order by comment_time
        rows between unbounded preceding and current row
        ) as cumulative_length
    from filtered_comment_documents
),

most_recent_document as (

    select 
        ticket_id, 
        source_relation,
        max(comment_time) as most_recent_chunk_update
    from grouped_comment_documents
    group by 1, 2
)

select 
    grouped_comment_documents.ticket_id,
    grouped_comment_documents.source_relation,
    cast({{ dbt_utils.safe_divide('floor(cumulative_length - 1)', var('document_max_tokens', 5000)) }} as {{ dbt.type_int() }}) as chunk_index,
    most_recent_document.most_recent_chunk_update,
    {{ dbt.listagg(
        measure="comment_markdown",
        delimiter_text="'\\n\\n---\\n\\n'",
        order_by_clause="order by comment_time"
        ) }} as comments_group_markdown,
    sum(comment_tokens) as chunk_tokens
from grouped_comment_documents
join most_recent_document
    on grouped_comment_documents.ticket_id = most_recent_document.ticket_id
    and grouped_comment_documents.source_relation = most_recent_document.source_relation
group by 1,2,3,4