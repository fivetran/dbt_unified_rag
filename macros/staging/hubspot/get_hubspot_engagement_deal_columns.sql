{% macro get_hubspot_engagement_deal_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "deal_id", "datatype": dbt.type_int()},
    {"name": "engagement_id", "datatype": dbt.type_int()},
    {"name": "category", "datatype": dbt.type_string()},
    {"name": "engagement_type", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
