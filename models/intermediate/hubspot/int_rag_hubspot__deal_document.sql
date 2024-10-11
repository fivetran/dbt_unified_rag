{{ config(enabled=var('rag__using_hubspot', True)) }} 

with deals as (

    select *
    from {{ ref('stg_rag_hubspot__deal') }}
), 

contacts as (

    select *
    from {{ ref('stg_rag_hubspot__contact') }}
), 

companies as (

    select *
    from {{ ref('stg_rag_hubspot__company') }}
), 

engagement_companies as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_company') }}
),

engagement_contacts as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_contact') }}
),

engagement_emails as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_email') }} 
),

engagement_notes as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_note') }}
),

engagement_deals as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_deal') }}
),

engagement_details as (

    select
        deals.deal_id,
        deals.deal_name,
        {{ unified_rag.coalesce_cast(["engagement_emails.engagement_type", "engagement_notes.engagement_type", "'UNKNOWN'"], dbt.type_string()) }} as engagement_type,
        {{ dbt.concat(["'https://app.hubspot.com/contacts'", "deals.portal_id", "'/record/0-3/'", "deals.deal_id"]) }} as url_reference,
        deals.source_relation,
        {{ unified_rag.coalesce_cast(["contacts.contact_name", "'UNKNOWN'"], dbt.type_string()) }} as contact_name,
        {{ unified_rag.coalesce_cast(["contacts.email", "'UNKNOWN'"], dbt.type_string()) }} as created_by,
        {{ unified_rag.coalesce_cast(["companies.company_name", "'UNKNOWN'"], dbt.type_string()) }} as company_name,
        deals.created_date AS created_on 
    from deals
    left join engagement_deals
        on deals.deal_id = engagement_deals.deal_id
        and deals.source_relation = engagement_deals.source_relation
    left join engagement_contacts
        on engagement_deals.engagement_id = engagement_contacts.engagement_id 
        and engagement_deals.source_relation = engagement_contacts.source_relation
    left join contacts 
        on engagement_contacts.contact_id = contacts.contact_id
        and engagement_contacts.source_relation = contacts.source_relation
    left join engagement_companies
        on engagement_deals.engagement_id = engagement_companies.engagement_id 
        and engagement_deals.source_relation = engagement_companies.source_relation
    left join companies
        on engagement_companies.company_id = companies.company_id
        and engagement_companies.source_relation = companies.source_relation
    left join engagement_emails
        on engagement_deals.engagement_id = engagement_emails.engagement_id
        and engagement_deals.source_relation = engagement_emails.source_relation
    left join engagement_notes
        on engagement_deals.engagement_id = engagement_notes.engagement_id
        and engagement_deals.source_relation = engagement_notes.source_relation
), 

engagement_markdown as (

    select
        deal_id,
        source_relation,
        url_reference,
        {{ dbt.concat([
            "'Deal Name : '", "deal_name", "'\\n\\n'",
            "'Created By : '", "contact_name", "' ('", "created_by", "')\\n'",
            "'Created On : '", "created_on", "'\\n'",
            "'Company Name: '", "company_name", "'\\n'",
            "'Engagement Type: '", "engagement_type", "'\\n'"
        ]) }} as comment_markdown
    from engagement_details
),

engagement_tokens as (

select 
    *,
    {{ unified_rag.count_tokens("comment_markdown") }} as comment_tokens
from engagement_markdown
)

select *
from engagement_tokens

