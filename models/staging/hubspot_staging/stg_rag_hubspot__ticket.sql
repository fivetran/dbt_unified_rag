{{ config(enabled = var('rag__using_hubspot', True)) }}

WITH base AS (
    {{ fivetran_utils.union_data(
        table_identifier = 'ticket',
        database_variable = 'rag_hubspot_database',
        schema_variable = 'rag_hubspot_schema',
        default_database = target.database,
        default_schema = 'rag_hubspot',
        default_variable = 'hubspot_ticket',
        union_schema_variable = 'rag_hubspot_union_schemas',
        union_database_variable = 'rag_hubspot_union_databases'
    ) }}
),
fields AS (
    SELECT
		*
        {{ fivetran_utils.source_relation(
            union_schema_variable = 'rag_hubspot_union_schemas',
            union_database_variable = 'rag_hubspot_union_databases'
        ) }}
    FROM
        base
),
FINAL AS (
    SELECT
        *
    FROM
        fields
)
SELECT
    *
FROM
    FINAL
