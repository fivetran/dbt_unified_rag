{{ config(enabled=var('rag__using_jira', True)) }}

with issue_comments as (

    select *
    from {{ ref('stg_rag_jira__comment') }}
),

users as ( 

    select *
    from {{ ref('stg_rag_jira__user') }}
),

comment_details as (

    select
        issue_comments.comment_id as issue_comment_id,
        issue_comments.issue_id,
        issue_comments.source_relation,
        {{ unified_rag.coalesce_cast(["users.email", "'UNKNOWN'"], dbt.type_string()) }} as commenter_email,
        {{ unified_rag.coalesce_cast(["users.user_display_name", "'UNKNOWN'"], dbt.type_string()) }} as commenter_name,
        issue_comments.created_at as comment_time,
        issue_comments.body as comment_body
    from issue_comments
    left join users
        on issue_comments.author_user_id = users.user_id
        and issue_comments.source_relation = users.source_relation
),

comment_markdowns as (
    select
        issue_comment_id,
        issue_id,
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
), 

comments_tokens as (

    select
        *,
        {{ unified_rag.count_tokens("comment_markdown") }} as comment_tokens
    from comment_markdowns
),

truncated_comments as (

    select
        issue_comment_id,
        issue_id,
        source_relation,
        comment_time,
        case when comment_tokens > {{ var('jira_max_tokens', 5000) }} then left(comment_markdown, {{ var('jira_max_tokens', 5000) }} * 4)  -- approximate 4 characters per token
            else comment_markdown
            end as comment_markdown,
        case when comment_tokens > {{ var('jira_max_tokens', 5000) }} then {{ var('jira_max_tokens', 5000) }}
            else comment_tokens
            end as comment_tokens
    from comments_tokens
)

select *
from truncated_comments