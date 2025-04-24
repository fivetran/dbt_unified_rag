{% set model_enabled = (
        var('rag__using_hubspot', True)
        and not var('should_exclude_deal', False)
) %}
{{ config(enabled=model_enabled) }}

with filtered_comment_documents as (

    select *
    from {{ ref('int_rag_hubspot__deal_comment_document') }}
),

grouped_comment_documents as (
    
    select 
      deal_id,
      title,
      source_relation,
      comment_markdown,
      comment_tokens,
      comment_time,
      sum(comment_tokens) over (
        partition by deal_id 
        order by comment_time
        rows between unbounded preceding and current row
      ) as cumulative_length
    from filtered_comment_documents
),

most_recent_document as (

    select 
        deal_id, 
        source_relation,
        max(comment_time) as most_recent_chunk_update
    from grouped_comment_documents
    group by 1, 2
)

select 
    grouped_comment_documents.deal_id,
    title,
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
inner join most_recent_document
    on grouped_comment_documents.deal_id = most_recent_document.deal_id
    and grouped_comment_documents.source_relation = most_recent_document.source_relation
group by 1,2,3,4,5