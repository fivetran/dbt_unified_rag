{{ config(enabled = var('rag__using_hubspot', True)) }}

WITH FINAL AS (

    SELECT
        {{ dbt_utils.star(
            from = ref('stg_rag_hubspot__company_fields'),
            except = ['id', '_fivetran_synced', 'is_deleted', 'property_name', 'property_description', 'property_createdate', 'property_industry', 'property_address', 'property_address_2', 'property_city', 'property_state', 'property_country', 'property_annualrevenue' ]
        ) }},
        id AS company_id,
        CAST(_fivetran_synced AS {{ dbt.type_timestamp() }}) AS _fivetran_synced,
        is_deleted AS is_company_deleted,
        property_name AS company_name,
        property_description AS description,
        property_createdate AS created_date,
        property_industry AS industry,
        property_address AS street_address,
        property_address_2 AS street_address_2,
        property_city AS city,
        property_state AS state,
        property_country AS country,
        property_annualrevenue AS company_annual_revenue
    FROM
        {{ ref('stg_rag_hubspot__company_fields') }}
)
SELECT
    *
FROM
    FINAL
