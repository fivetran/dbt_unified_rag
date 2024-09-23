{% macro get_zendesk_user_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "active", "datatype": "boolean"},
    {"name": "created_at", "datatype": dbt.type_timestamp()},
    {"name": "updated_at", "datatype": dbt.type_timestamp()},
    {"name": "email", "datatype": dbt.type_string()},
    {"name": "external_id", "datatype": dbt.type_int()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "last_login_at", "datatype": dbt.type_timestamp()},
    {"name": "name", "datatype": dbt.type_string()},
    {"name": "organization_id", "datatype": dbt.type_int()},
    {"name": "phone", "datatype": dbt.type_string()},
    {"name": "role", "datatype": dbt.type_string()},
    {"name": "suspended", "datatype": "boolean"},
    {"name": "ticket_restriction", "datatype": dbt.type_string()},
    {"name": "time_zone", "datatype": dbt.type_string()}
] %}

{{ return(columns) }}

{% endmacro %}
