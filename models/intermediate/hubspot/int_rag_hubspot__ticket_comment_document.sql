{% set model_enabled = (
        var('rag__using_hubspot', True)
        and var('should_include_ticket', True)
) %}
{{ config(enabled=model_enabled) }}

WITH tickets AS (

    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__ticket') }}
),
ticket_engagements AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__ticket_engagement') }}
),
engagement_details AS (
    SELECT
        *
    FROM
        {{ ref('int_rag_hubspot__engagement') }}
),
comments_tokens AS (
    SELECT
        *,
        {{ unified_rag.count_tokens("comment_markdown") }} AS comment_tokens
    FROM
        engagement_details
),
truncated_comments AS (
    SELECT
        engagement_id,
        source_relation,
        comment_time,
        CASE
            WHEN comment_tokens > {{ var(
                'document_max_tokens',
                5000
            ) }} THEN LEFT(
                comment_markdown,
                {{ var(
                    'document_max_tokens',
                    5000
                ) }} * 4
            ) -- approximate 4 characters per token
            ELSE comment_markdown
        END AS comment_markdown,
        CASE
            WHEN comment_tokens > {{ var(
                'document_max_tokens',
                5000
            ) }} THEN {{ var(
                'document_max_tokens',
                5000
            ) }}
            ELSE comment_tokens
        END AS comment_tokens
    FROM
        comments_tokens
),
comments_associated_with_ticket AS (
    SELECT
        truncated_comments.engagement_id,
        truncated_comments.comment_time,
        truncated_comments.comment_markdown,
        truncated_comments.comment_tokens,
        truncated_comments.source_relation,
        tickets.id AS ticket_id,
        tickets.property_subject AS ticket_subject
    FROM
        truncated_comments
        JOIN ticket_engagements
        ON truncated_comments.engagement_id = ticket_engagements.engagement_id
        AND truncated_comments.source_relation = ticket_engagements.source_relation
        JOIN tickets
        ON tickets.id = ticket_engagements.ticket_id
        AND tickets.source_relation = ticket_engagements.source_relation
    WHERE
        truncated_comments.comment_markdown IS NOT NULL
),
grouped_comment_documents AS (
    SELECT
        ticket_id,
        ticket_subject,
        source_relation,
        comment_markdown,
        comment_tokens,
        comment_time,
        SUM(comment_tokens) over (
            PARTITION BY ticket_id
            ORDER BY
                comment_time rows BETWEEN unbounded preceding
                AND CURRENT ROW
        ) AS cumulative_length
    FROM
        comments_associated_with_ticket
),
most_recent_document AS (
    SELECT
        ticket_id,
        source_relation,
        MAX(comment_time) AS most_recent_chunk_update
    FROM
        grouped_comment_documents
    GROUP BY
        1,
        2
)
SELECT
    grouped_comment_documents.ticket_id,
    grouped_comment_documents.ticket_subject,
    grouped_comment_documents.source_relation,
    CAST(
        {{ dbt_utils.safe_divide(
            'floor(cumulative_length - 1)',
            var(
                'document_max_tokens',
                5000
            )
        ) }} AS {{ dbt.type_int() }}
    ) AS chunk_index,
    most_recent_document.most_recent_chunk_update,
    {{ dbt.listagg(
        measure = "comment_markdown",
        delimiter_text = "'\\n\\n---\\n\\n'",
        order_by_clause = "order by comment_time"
    ) }} AS comments_group_markdown,
    SUM(comment_tokens) AS chunk_tokens
FROM
    grouped_comment_documents
    INNER JOIN most_recent_document
    ON grouped_comment_documents.ticket_id = most_recent_document.ticket_id
    AND grouped_comment_documents.source_relation = most_recent_document.source_relation
GROUP BY
    1,
    2,
    3,
    4,
    5
