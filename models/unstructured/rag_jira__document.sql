{{ config(enabled=var('rag__using_jira', True)) }}

with issue_document as (

    select *
    from {{ ref('int_rag_jira__issue_document') }}
), 

grouped as (

    select *
    from {{ ref('int_rag_jira__issue_comment_documents_grouped') }}
), 

final as (

    select
        cast(issue_document.issue_id as {{ dbt.type_string() }}) as document_id,
        issue_document.title,
        issue_document.url_reference,
        'jira' as platform,
        issue_document.source_relation,
        grouped.most_recent_chunk_update,
        grouped.chunk_index,
        grouped.chunk_tokens as chunk_tokens_approximate,
        {{ dbt.concat([
            "issue_document.issue_markdown",
            "'\\n\\n## COMMENTS\\n\\n'",
            "grouped.comments_group_markdown"]) }}
            as chunk
    from issue_document
    inner join grouped
        on grouped.issue_id = issue_document.issue_id
        and grouped.source_relation = issue_document.source_relation
)

select *
from final