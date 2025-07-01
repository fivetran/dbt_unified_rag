{% set model_enabled = (
        var('rag__using_hubspot', True)
        and var('should_include_ticket', True)
) %}
{{ config(enabled=model_enabled) }}

{% set hubspot_ticket_engagement_columns = [ {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()}, {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()}, {"name": "category", "datatype": dbt.type_string()}, {"name": "ticket_id", "datatype": dbt.type_int()}, {"name": "engagement_id", "datatype": dbt.type_int()}, {"name": "engagement_type", "datatype": dbt.type_string()} ] %}
WITH base AS (
    {{ fivetran_utils.union_data(
        table_identifier = 'ticket_engagement',
        database_variable = 'rag_hubspot_database',
        schema_variable = 'rag_hubspot_schema',
        default_database = target.database,
        default_schema = 'rag_hubspot',
        default_variable = 'hubspot_ticket_engagement',
        union_schema_variable = 'rag_hubspot_union_schemas',
        union_database_variable = 'rag_hubspot_union_databases'
    ) }}
),
fields AS (
    SELECT
        {{ fivetran_utils.fill_staging_columns(
            source_columns = adapter.get_columns_in_relation(source('rag_hubspot', 'ticket_engagement')),
            staging_columns = hubspot_ticket_engagement_columns
        ) }}
        {{ fivetran_utils.source_relation(
            union_schema_variable = 'rag_hubspot_union_schemas',
            union_database_variable = 'rag_hubspot_union_databases'
        ) }}
    FROM
        base
)
SELECT
    source_relation,
    category,
    ticket_id,
    engagement_id,
    engagement_type,
    _fivetran_deleted,
    CAST(_fivetran_synced AS {{ dbt.type_timestamp() }}) AS _fivetran_synced
FROM
    fields
