WITH owners AS (
    SELECT
        *,
        COALESCE(
            owner_email,
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
        COALESCE({{ cast('closed_date', dbt.type_string()) }}, 'not closed yet') AS safe_close_date
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
        DISTINCT deals.deal_id,
        deals.source_relation,
        {{ dbt.concat([ "'  - {'", "'deal_name: '", "deals.title", "' // '", "'deal_owner_name: '", "owners.safe_first_name", "' '", "owners.safe_last_name", "' // '", "'deal_owner_email: '", "owners.safe_email", "' // '", "'deal_closed_date: '", "deals.safe_close_date", "'}'" ]) }} AS deal_description,
        deals.closed_date
    FROM
        deals
        JOIN owners
        ON owners.owner_id = deals.owner_id
        AND owners.source_relation = deals.source_relation
),
company_with_deal_description AS (
    SELECT
        company.company_id AS company_id,
        company.source_relation AS source_relation,
        {{ dbt.listagg(
            measure = "dd.deal_description",
            delimiter_text = "'\\n'",
            order_by_clause = "order by dd.closed_date"
        ) }} AS deal_descriptions
    FROM
        company
        LEFT JOIN deal_company dc
        ON dc.company_id = company.company_id
        AND dc.source_relation = company.source_relation
        LEFT JOIN deal_descriptions dd
        ON dd.deal_id = dc.deal_id
        AND dc.source_relation = dd.source_relation
    GROUP BY
        1,
        2
)
SELECT
    cdd.deal_descriptions AS deals,
    company.*
FROM
    company
    JOIN company_with_deal_description cdd
    ON cdd.company_id = company.company_id
    AND cdd.source_relation = company.source_relation
