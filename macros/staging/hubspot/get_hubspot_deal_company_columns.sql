{% macro get_hubspot_deal_company_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "deal_id", "datatype": dbt.type_int()},
    {"name": "company_id", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}