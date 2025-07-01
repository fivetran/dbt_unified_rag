{% set model_enabled = (
        var('rag__using_hubspot', True)
        and var('should_include_ticket', True)
) %}
{{ config(enabled=model_enabled) }}

WITH tickets AS (

    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__ticket') }}
),
ticket_companies AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__ticket_company') }}
),
companies AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__company') }}
),
ticket_with_companies AS (
    SELECT
        tickets.id,
        tickets.source_relation,
        companies.company_name
    FROM
        tickets
        LEFT JOIN ticket_companies
        ON tickets.id = ticket_companies.ticket_id
        AND tickets.source_relation = ticket_companies.source_relation
        LEFT JOIN companies
        ON companies.company_id = ticket_companies.company_id
        AND companies.source_relation = ticket_companies.source_relation
),
aggregated AS (
    SELECT
        id,
        source_relation,
        {{ dbt.listagg(
            'company_name',
            "', '"
        ) }} AS company_names
    FROM
        ticket_with_companies
    GROUP BY
        id,
        source_relation
)
SELECT
    COALESCE(
        aggregated.company_names,
        '<NO COMPANY>'
    ) AS company_names,
    tickets.*
FROM
    tickets
    LEFT JOIN aggregated
    ON tickets.id = aggregated.id
    AND tickets.source_relation = aggregated.source_relation
