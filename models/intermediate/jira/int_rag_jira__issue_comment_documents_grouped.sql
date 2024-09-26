{{ config(enabled=var('rag__using_jira', True)) }}

with filtered_comment_documents as (

    select *
    from {{ ref('int_rag_jira__issue_comment_document') }}
),

grouped_comment_documents as (
    
    select 
      issue_id,
      source_relation,
      comment_markdown,
      comment_tokens,
      comment_time,
      sum(comment_tokens) over (
        partition by issue_id 
        order by comment_time
        rows between unbounded preceding and current row
      ) as cumulative_length
    from filtered_comment_documents
)

select 
    issue_id,
    source_relation,
    cast({{ dbt_utils.safe_divide('floor(cumulative_length - 1)', var('jira_max_tokens', 5000)) }} as {{ dbt.type_int() }}) as chunk_index,
    max(comment_time) as most_recent_chunk_update,
    {{ dbt.listagg(
        measure="comment_markdown",
        delimiter_text="'\\n\\n---\\n\\n'",
        order_by_clause="order by comment_time"
    ) }} as comments_group_markdown,
    sum(comment_tokens) as chunk_tokens
from grouped_comment_documents
group by 1,2,3