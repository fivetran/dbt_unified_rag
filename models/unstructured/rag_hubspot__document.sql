{{ config(enabled=var('rag__using_hubspot', True)) }}

with deal_document as (

    select *
    from {{ ref('int_rag_hubspot__deal_document') }}
), 

grouped as (

    select *
    from {{ ref('int_rag_hubspot__deal_comment_documents_grouped') }}
), 

final as (

    select
        cast(deal_document.deal_id as {{ dbt.type_string() }}) as document_id,
        deal_document.title,
        deal_document.url_reference,
        'hubspot' as platform,
        deal_document.source_relation,
        grouped.most_recent_chunk_update,
        grouped.chunk_index,
        grouped.chunk_tokens as chunk_tokens_approximate,
        {{ dbt.concat([
            "deal_document.comment_markdown",
            "'\\n\\n## COMMENTS\\n\\n'",
            "grouped.comments_group_markdown"]) }}
            as chunk
    from deal_document
    join grouped
        on grouped.deal_id = deal_document.deal_id
        and grouped.source_relation = deal_document.source_relation
)

select *
from final