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
        coalesce(grouped.most_recent_chunk_update, issue_document.created_on) as most_recent_chunk_update,
        coalesce(grouped.chunk_index, 0) as chunk_index,
        coalesce(grouped.chunk_tokens, 0) as chunk_tokens_approximate,
        {{ dbt.concat([
            "issue_document.issue_markdown",
            "'\\n\\n## COMMENTS\\n\\n'",
            "coalesce(grouped.comments_group_markdown, '')"]) }}
            as chunk
    from issue_document
    left join grouped
        on grouped.issue_id = issue_document.issue_id
        and grouped.source_relation = issue_document.source_relation
)

select *
from final