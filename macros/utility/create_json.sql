{% macro create_json(columns) %}
    {%- if not execute -%}
        {%- set json_function = {
            'bigquery': 'TO_JSON_STRING',
            'snowflake': 'OBJECT_CONSTRUCT',
            'redshift': 'json_build_object',
            'databricks': 'to_json'
        }[target.type] -%}
        {%- set json_expression = json_function + '(' -%}
        {%- for column in columns -%}
            {%- set json_expression = json_expression + "'" + column + "', " + column -%}
            {%- if not loop.last -%}
                {%- set json_expression = json_expression + ', ' -%}
            {%- endif -%}
        {%- endfor -%}
        {%- set json_expression = json_expression + ')' -%}

        {%- if target.type == 'snowflake' -%}
            CAST({{ json_expression }} AS STRING)
        {%- elif target.type == 'redshift' -%}
            {{ json_expression }}::VARCHAR
        {%- else -%}
            {{ json_expression }}
        {%- endif -%}
    {%- endif -%}
{% endmacro %}
