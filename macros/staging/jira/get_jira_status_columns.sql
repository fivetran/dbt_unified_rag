{% macro get_jira_status_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "description", "datatype": dbt.type_string()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "status_category_id", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
