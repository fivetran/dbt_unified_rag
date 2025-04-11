{{ config(enabled = var('rag__using_hubspot', True)) }}

{% set hubspot_ticket_company_columns = [ {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()}, {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()}, {"name": "category", "datatype": dbt.type_string()}, {"name": "ticket_id", "datatype": dbt.type_int()}, {"name": "company_id", "datatype": dbt.type_int()} ] %}
WITH base AS (
    {{ fivetran_utils.union_data(
        table_identifier = 'ticket_company',
        database_variable = 'rag_hubspot_database',
        schema_variable = 'rag_hubspot_schema',
        default_database = target.database,
        default_schema = 'rag_hubspot',
        default_variable = 'hubspot_ticket_company',
        union_schema_variable = 'rag_hubspot_union_schemas',
        union_database_variable = 'rag_hubspot_union_databases'
    ) }}
),
fields AS (
    SELECT
        {{ fivetran_utils.fill_staging_columns(
            source_columns = adapter.get_columns_in_relation(source('rag_hubspot', 'ticket_company')),
            staging_columns = hubspot_ticket_company_columns
        ) }}
        {{ fivetran_utils.source_relation(
            union_schema_variable = 'rag_hubspot_union_schemas',
            union_database_variable = 'rag_hubspot_union_databases'
        ) }}
    FROM
        base
)
SELECT
    DISTINCT source_relation,
    category,
    ticket_id,
    company_id,
    _fivetran_deleted,
    CAST(_fivetran_synced AS {{ dbt.type_timestamp() }}) AS _fivetran_synced
FROM
    fields
