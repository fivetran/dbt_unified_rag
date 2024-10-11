{% macro get_hubspot_engagement_email_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "type", "datatype": dbt.type_string(), "alias": "engagement_type"},
    {"name": "engagement_id", "datatype": dbt.type_int()},
    {"name": "property_hs_createdate", "datatype": dbt.type_timestamp(), "alias": "created_timestamp"},
    {"name": "property_hs_timestamp", "datatype": dbt.type_timestamp(), "alias": "occurred_timestamp"},
    {"name": "property_hubspot_owner_id", "datatype": dbt.type_int(), "alias": "owner_id"},
    {"name": "property_hubspot_team_id", "datatype": dbt.type_int(), "alias": "team_id"},
    {"name": "property_hs_email_text", "datatype": dbt.type_string(), "alias": "email_text"},
    {"name": "property_hs_email_html", "datatype": dbt.type_string(), "alias": "email_html"},
    {"name": "property_hs_body_preview", "datatype": dbt.type_string(), "alias": "body_preview"},
    {"name": "property_hs_body_preview_html", "datatype": dbt.type_string(), "alias": "body_preview_html"},
    {"name": "property_hs_email_subject", "datatype": dbt.type_string(), "alias": "email_subject"},
    {"name": "property_hs_email_to_email", "datatype": dbt.type_string(), "alias": "email_to_email"}, 
    {"name": "property_hs_email_from_email", "datatype": dbt.type_string(), "alias": "email_from_email"}, 
    {"name": "property_hs_email_cc_email", "datatype": dbt.type_string(), "alias": "email_cc_email"}
] %}

{{ return(columns) }}

{% endmacro %}
