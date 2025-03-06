{% macro create_json(columns) -%}
    {% if target.type == 'bigquery' -%}
        TO_JSON_STRING(
            STRUCT(
                {%- for column in columns -%}
                    {{ column }} AS {{ column }}
                    {%- if not loop.last -%}, {% endif -%}
                {%- endfor -%}
            )
        )
    {% elif target.type == 'snowflake' -%}
        CAST(
            OBJECT_CONSTRUCT(
                {%- for column in columns -%}
                    '{{ column }}', {{ column }}
                    {%- if not loop.last -%}, {% endif -%}
                {%- endfor -%}
            )
            AS STRING
        )
    {% elif target.type == 'redshift' -%}
        json_build_object(
            {%- for column in columns -%}
                '{{ column }}', {{ column }}
                {%- if not loop.last -%}, {% endif -%}
            {%- endfor -%}
        )::VARCHAR
    {% elif target.type == 'databricks' -%}
        to_json(
            named_struct(
                {%- for column in columns -%}
                    '{{ column }}', {{ column }}
                    {%- if not loop.last -%}, {% endif -%}
                {%- endfor -%}
            )
        )
    {% endif -%}
{% endmacro -%}
