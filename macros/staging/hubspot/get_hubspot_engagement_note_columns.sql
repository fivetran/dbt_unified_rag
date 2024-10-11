{% macro get_hubspot_engagement_note_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "body", "datatype": dbt.type_string(), "alias": "note"},
    {"name": "type", "datatype": dbt.type_string(), "alias": "engagement_type"},
    {"name": "engagement_id", "datatype": dbt.type_int()},
    {"name": "property_hs_createdate", "datatype": dbt.type_timestamp(), "alias": "created_timestamp"},
    {"name": "property_hs_timestamp", "datatype": dbt.type_timestamp(), "alias": "occurred_timestamp"},
    {"name": "property_hubspot_owner_id", "datatype": dbt.type_int(), "alias": "owner_id"},
    {"name": "property_hubspot_team_id", "datatype": dbt.type_int(), "alias": "team_id"},
    {"name": "property_hs_body_preview", "datatype": dbt.type_string(), "alias": "note_body_preview"},
    {"name": "property_hs_note_body", "datatype": dbt.type_string(), "alias": "note_body"},
    {"name": "property_hs_body_preview_html", "datatype": dbt.type_string(), "alias": "note_body_preview_html"}
] %}

{{ return(columns) }}

{% endmacro %}
