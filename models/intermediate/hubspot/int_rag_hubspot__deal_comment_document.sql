{% set model_enabled = (
        var('rag__using_hubspot', True)
        and not var('should_exclude_deal', False)
) %}
{{ config(enabled=model_enabled) }}

with engagement_deals as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_deal') }}
),

deals as (

    select *
    from {{ ref('stg_rag_hubspot__deal') }}
), 

contacts as (

    select *
    from {{ ref('stg_rag_hubspot__contact') }}
), 

owners as (

    select *
    from {{ ref('stg_rag_hubspot__owner') }}
),

engagement_contacts as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_contact') }}
),

engagement_emails as (

    select 
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
        engagement_email.email_from_email as commenter_email,
        {{ fivetran_utils.string_agg(field_to_agg="contacts.contact_name", delimiter="','") }} as commenter_name
    from {{ ref('stg_rag_hubspot__engagement_email') }} engagement_email
    left join engagement_contacts
        on engagement_email.engagement_id = engagement_contacts.engagement_id 
        and engagement_email.source_relation = engagement_contacts.source_relation
    left join contacts 
        on engagement_contacts.contact_id = contacts.contact_id
        and engagement_contacts.source_relation = contacts.source_relation
    {{ dbt_utils.group_by(12)}}
),

engagement_notes as ( 

    select 
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
    from {{ ref('stg_rag_hubspot__engagement_note') }} engagement_note
    left join owners
        on engagement_note.owner_id = owners.owner_id
        and engagement_note.source_relation = owners.source_relation
),

email_comment_details as (

    select
        engagement_deals.engagement_id as deal_comment_id,
        engagement_deals.deal_id, 
        engagement_deals.source_relation,
        coalesce(deals.title, engagement_emails.title) as title,
        {{ unified_rag.coalesce_cast(["engagement_emails.commenter_email", "'UNKNOWN'"], dbt.type_string()) }} as commenter_email,
        {{ unified_rag.coalesce_cast(["engagement_emails.commenter_name", "'UNKNOWN'"], dbt.type_string()) }} as commenter_name,
        {{ unified_rag.coalesce_cast(["engagement_emails.title", "'UNKNOWN'"], dbt.type_string()) }} as email_title,
        {{ unified_rag.coalesce_cast(["engagement_emails.created_timestamp", "'1970-01-01 00:00:00'"], dbt.type_timestamp()) }} as comment_time,
        {{ unified_rag.coalesce_cast(["engagement_emails.body", "'UNKNOWN'"], dbt.type_string()) }}  as comment_body
    from engagement_deals
    left join deals
        on deals.deal_id = engagement_deals.deal_id
        and deals.source_relation = engagement_deals.source_relation
    left join engagement_emails
        on engagement_deals.engagement_id = engagement_emails.engagement_id
        and engagement_deals.source_relation = engagement_emails.source_relation
    where lower(engagement_deals.engagement_type) = 'email'
),

note_comment_details as (

    select
        engagement_deals.engagement_id as deal_comment_id,
        deals.deal_id, 
        deals.source_relation,
        coalesce(deals.title, engagement_notes.title) as title,
        {{ unified_rag.coalesce_cast(["engagement_notes.owner_email", "'UNKNOWN'"], dbt.type_string()) }} as commenter_email,
        {{ unified_rag.coalesce_cast(["engagement_notes.owner_name", "'UNKNOWN'"], dbt.type_string()) }} as commenter_name,
        engagement_notes.title as engagement_note_title,
        {{ unified_rag.coalesce_cast(["engagement_notes.created_timestamp", "'1970-01-01 00:00:00'"], dbt.type_timestamp()) }} as comment_time,
        {{ unified_rag.coalesce_cast(["engagement_notes.body", "'UNKNOWN'"], dbt.type_string()) }} as comment_body
    from engagement_deals
    left join deals
        on deals.deal_id = engagement_deals.deal_id
        and deals.source_relation = engagement_deals.source_relation
    left join engagement_notes
        on engagement_deals.engagement_id = engagement_notes.engagement_id
        and engagement_deals.source_relation = engagement_notes.source_relation
    where lower(engagement_deals.engagement_type) = 'note'
),


comment_markdowns as (
    
    select
        deal_comment_id,
        deal_id,
        title,
        source_relation,
        comment_time,
        cast(
            {{ dbt.concat([ 
                "'Email subject: '", "email_title", "'\\n'",
                "'### message from '", "commenter_name", "' ('", "commenter_email", "')\\n'",
                "'##### sent @ '", "comment_time", "'\\n'",
                "comment_body"
            ]) }} as {{ dbt.type_string() }})
            as comment_markdown
    from email_comment_details

    union all

    select
        deal_comment_id,
        deal_id,
        title,
        source_relation,
        comment_time,
        cast(
            {{ dbt.concat([
                "'Engagement type: Note'", "'\\n'",
                "'### message from '", "commenter_name", "' ('", "commenter_email", "')\\n'",
                "'##### sent @ '", "comment_time", "'\\n'",
                "comment_body"
            ]) }} as {{ dbt.type_string() }})
            as comment_markdown
    from note_comment_details
), 

comments_tokens as (

    select
        *,
        {{ unified_rag.count_tokens("comment_markdown") }} as comment_tokens
    from comment_markdowns
),

truncated_comments as (

    select
        deal_comment_id,
        deal_id,
        title,
        source_relation,
        comment_time,
        case when comment_tokens > {{ var('document_max_tokens', 5000) }} then left(comment_markdown, {{ var('document_max_tokens', 5000) }} * 4)  -- approximate 4 characters per token
            else comment_markdown
            end as comment_markdown,
        case when comment_tokens > {{ var('document_max_tokens', 5000) }} then {{ var('document_max_tokens', 5000) }}
            else comment_tokens
            end as comment_tokens
    from comments_tokens
)

select *
from truncated_comments
where comment_markdown is not null