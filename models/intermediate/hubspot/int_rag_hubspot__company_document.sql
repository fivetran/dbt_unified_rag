WITH owners AS (
    SELECT
        *,
        COALESCE(
            email,
            'UNKNOWN'
        ) AS safe_email,
        COALESCE(
            first_name,
            ''
        ) AS safe_first_name,
        COALESCE(
            last_name,
            ''
        ) AS safe_last_name
    FROM
        {{ ref('stg_rag_hubspot__owner') }}
),
deals AS (
    SELECT
        *,
        COALESCE({{ cast('property_closedate', dbt.type_string()) }}, 'not closed yet') AS safe_close_date
    FROM
        {{ ref('stg_rag_hubspot__deal') }}
),
company AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__company') }}
),
deal_company AS (
    SELECT
        *
    FROM
        {{ ref('stg_rag_hubspot__deal_company') }}
),
deal_descriptions AS (
    SELECT
        DISTINCT deal.deal_id,
        {{ dbt.concat([ "'- {'", "'deal_name: '", "deals.property_dealname", "', '", "'deal_owner_name: '", "owners.safe_first_name", "' '", "owners.safe_last_name", "', '", "'deal_owner_email: '", "owners.safe_email", "', '", "'deal_closed_date: '", "deals.safe_close_date", "'}'" ]) }} AS deal_description,
        deal.property_closedate
    FROM
        deals
        JOIN owners
        ON owners.owner_id = deal.owner_id
),
company_with_deal_description AS (
    SELECT
        id,
        {{ dbt.listagg(
            measure = "dd.deal_description",
            delimiter_text = "'\\n'",
            order_by_clause = "order by dd.property_closedate"
        ) }} AS deal_descriptions
    FROM
        company
        JOIN deal_company dc
        ON dc.company_id = company.id
        JOIN deal_descriptions dd
        ON dd.deal_id = dc.deal_id
    GROUP BY
        1
)
SELECT
    cdd.deal_descriptions,
    company.*
FROM
    company
    JOIN company_with_deal_description cdd
    ON cdd.id = company.id
WHERE
    NOT company._fivetran_deleted
