{{ config(enabled=var('rag__using_hubspot', True)) }} 

WITH contacts AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__contact') }}
),
engagement_contacts AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__engagement_contact') }}
),
owners AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__owner') }}
),
engagement_emails AS (
    SELECT
        engagement_email.engagement_id,
        engagement_email.source_relation,
        engagement_email.engagement_type,
        engagement_email.created_timestamp,
        engagement_email.occurred_timestamp,
        engagement_email.owner_id,
        engagement_email.team_id,
        engagement_email.body,
        engagement_email.title,
        engagement_email.email_to_email,
        engagement_email.email_cc_email,
        engagement_email.email_from_email AS commenter_email,
        {{ fivetran_utils.string_agg(
            field_to_agg = "contacts.contact_name",
            delimiter = "','"
        ) }} AS commenter_name
    FROM
        {{ ref('stg_rag_hubspot__engagement_email') }}
        engagement_email
        LEFT JOIN engagement_contacts
        ON engagement_email.engagement_id = engagement_contacts.engagement_id
        AND engagement_email.source_relation = engagement_contacts.source_relation
        LEFT JOIN contacts
        ON engagement_contacts.contact_id = contacts.contact_id
        AND engagement_contacts.source_relation = contacts.source_relation {{ dbt_utils.group_by(12) }}
),
engagement_notes AS (
    SELECT
        engagement_note.engagement_id,
        engagement_note.source_relation,
        engagement_note.engagement_type,
        engagement_note.created_timestamp,
        engagement_note.occurred_timestamp,
        engagement_note.owner_id,
        engagement_note.team_id,
        engagement_note.title,
        engagement_note.body,
        owners.owner_name,
        owners.owner_email
    FROM
        {{ ref('stg_rag_hubspot__engagement_note') }}
        engagement_note
        LEFT JOIN owners
        ON engagement_note.owner_id = owners.owner_id
        AND engagement_note.source_relation = owners.source_relation
),
email_comment_details AS (
    SELECT
        source_relation,
        engagement_id,
        {{ unified_rag.coalesce_cast(
            ["engagement_emails.commenter_email", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS commenter_email,
        {{ unified_rag.coalesce_cast(
            ["engagement_emails.commenter_name", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS commenter_name,
        {{ unified_rag.coalesce_cast(
            ["engagement_emails.title", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS email_title,
        {{ unified_rag.coalesce_cast(
            ["engagement_emails.created_timestamp", "'1970-01-01 00:00:00'"],
            dbt.type_timestamp()
        ) }} AS comment_time,
        {{ unified_rag.coalesce_cast(
            ["engagement_emails.body", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS comment_body
    FROM
        engagement_emails
),
note_comment_details AS (
    SELECT
        source_relation,
        engagement_id,
        {{ unified_rag.coalesce_cast(
            ["engagement_notes.owner_email", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS commenter_email,
        {{ unified_rag.coalesce_cast(
            ["engagement_notes.owner_name", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS commenter_name,
        engagement_notes.title AS engagement_note_title,
        {{ unified_rag.coalesce_cast(
            ["engagement_notes.created_timestamp", "'1970-01-01 00:00:00'"],
            dbt.type_timestamp()
        ) }} AS comment_time,
        {{ unified_rag.coalesce_cast(
            ["engagement_notes.body", "'UNKNOWN'"],
            dbt.type_string()
        ) }} AS comment_body
    FROM
        engagement_notes
)
SELECT
    source_relation,
    engagement_id,
    comment_time,
    CAST(
        {{ dbt.concat([ "'Email subject: '", "email_title", "'\\n'", "'### message from '", "commenter_name", "' ('", "commenter_email", "')\\n'", "'##### sent @ '", "comment_time", "'\\n'", "comment_body" ]) }} AS {{ dbt.type_string() }}
    ) AS comment_markdown
FROM
    email_comment_details
UNION ALL
SELECT
    source_relation,
    engagement_id,
    comment_time,
    CAST(
        {{ dbt.concat([ "'Engagement type: Note'", "'\\n'", "'### message from '", "commenter_name", "' ('", "commenter_email", "')\\n'", "'##### sent @ '", "comment_time", "'\\n'", "comment_body" ]) }} AS {{ dbt.type_string() }}
    ) AS comment_markdown
FROM
    note_comment_details
