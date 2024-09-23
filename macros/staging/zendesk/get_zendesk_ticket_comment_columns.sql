{% macro get_zendesk_ticket_comment_columns() %}

{% set columns = [
    {"name": "_fivetran_synced", "datatype": dbt.type_string()},
    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
    {"name": "body", "datatype": dbt.type_string()},
    {"name": "created", "datatype": dbt.type_timestamp()},
    {"name": "id", "datatype": dbt.type_int()},
    {"name": "public", "datatype": "boolean"},
    {"name": "ticket_id", "datatype": dbt.type_int()},
    {"name": "user_id", "datatype": dbt.type_int()}
] %}

{{ return(columns) }}

{% endmacro %}
