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

engagements as (
    select *
    from {{ ref('stg_rag_hubspot__engagement') }}
),

engagement_companies as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_company') }}
),

engagement_contacts as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_contact') }}
),

engagement_deals as (

    select *
    from {{ ref('stg_rag_hubspot__engagement_deal') }}
),

engagement_detail_prep as (

    select
        deals.deal_id,
        deals.title,
        {{ unified_rag.coalesce_cast(["engagements.engagement_type", "'UNKNOWN'"], dbt.type_string()) }} as engagement_type,
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
    left join engagements
        on engagement_deals.engagement_id = engagements.engagement_id
        and engagement_deals.source_relation = engagements.source_relation
    left join engagement_contacts
        on engagements.engagement_id = engagement_contacts.engagement_id 
        and engagements.source_relation = engagement_contacts.source_relation
    left join engagement_companies
        on engagements.engagement_id = engagement_companies.engagement_id 
        and engagements.source_relation = engagement_companies.source_relation
    left join contacts 
        on engagement_contacts.contact_id = contacts.contact_id
        and engagement_contacts.source_relation = contacts.source_relation
    left join companies
        on engagement_companies.company_id = companies.company_id
        and engagement_companies.source_relation = companies.source_relation
), 

engagement_details as (
    select
        deal_id,
        title,
        url_reference,
        created_on,
        source_relation,
        {{ fivetran_utils.string_agg(field_to_agg="distinct engagement_type", delimiter="', '") }} as engagement_type,
        {{ fivetran_utils.string_agg(field_to_agg="distinct contact_name", delimiter="', '") }} as contact_name,
        {{ fivetran_utils.string_agg(field_to_agg="distinct created_by", delimiter="', '") }} as created_by,
        {{ fivetran_utils.string_agg(field_to_agg="distinct company_name", delimiter="', '") }} as company_name
    from engagement_detail_prep
    group by 1,2,3,4,5
),

engagement_markdown as (

    select
        deal_id,
        title,
        source_relation,
        url_reference,
        {{ dbt.concat([
            "'Deal Name : '", "title", "'\\n\\n'",
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

