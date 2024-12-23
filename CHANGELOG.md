# dbt_unified_rag v0.next.version

## Under the Hood
Addition of the `version: 2` tag within the `src_rag_hubspot.yml` file. ([#16](https://github.com/fivetran/dbt_unified_rag/pull/16))

# dbt_unified_rag v0.1.0-a4
[PR #13](https://github.com/fivetran/dbt_unified_rag/pull/13) includes the following updates: 

## Breaking Changes
- Added the hubspot `engagement` source table to the package and made the following updates:
    - Added `stg_rag_hubspot__engagement` model as part of the hubspot staging models and updated relevant documentation.
    - Updated `int_rag_hubspot__deal_document` joins so that `stg_rag_hubspot__engagement` table joins first over the `stg_rag_hubspot__engagement_contact` and `stg_rag_hubspot__engagement_company` tables to bring in all necessary engagement records.
    - Updated `int_rag_hubspot__deal_document` to retrieve `engagement_type` from the hubspot `engagement` table, as opposed to the `engagement_email` and `engagement_note` tables. As such, removes their respective references as they are no longer used in this model.

## Bug Fix (`--full-refresh` required when upgrading)
- Updated the `unique_id` in `rag__unified_document` to include `chunk_index`. Previously, the unique key was a combination of only `document_id`, `platform`, and `source_relation`, which was potentially inaccurate if there were multiple chunks associated with a document.

## Under the Hood
- Updated the *hubspot_x* seed data and *get_hubspot_x_columns* macros with the new `category` field where relevant.
- Updated missing field descriptions in the Hubspot documentation.

# dbt_unified_rag v0.1.0-a3
[PR #9](https://github.com/fivetran/dbt_unified_rag/pull/9) includes the following updates: 

## Bug Fix (`--full-refresh` required when upgrading)
- Updated the `url` logic in `stg_rag_zendesk__ticket` to provide the proper clickable URL to Zendesk tickets. This way, the `url_reference` in the `rag__unified_document` properly generates a hyperlink for Zendesk documents.
    - As this is updating underlying data flowing into the incremental model, a full refresh is required.
    
# dbt_unified_rag v0.1.0-a2

[PR #7](https://github.com/fivetran/dbt_unified_rag/pull/7) includes the following updates: 

## Bug Fixes
- For Snowflake destinations, we have removed the post-hook from the `rag__unified_document` which generated the `rag__unified_search` Cortex Search Service. 
    - While the Search Service worked when deployed locally, there were issues identified when deploying and running via Fivetran Quickstart. In order to ensure Snowflake users are still able to take advantage of the `rag__unified_document` end model, we have removed the Search Service from execution until we are able to verify it works as expected on all supported orchestration methods.
    - If you would like, you can generate your own Snowflake Cortex Search Service by following the [Create Cortex Search Service](https://docs.snowflake.com/en/sql-reference/sql/create-cortex-search) guidelines provided by Snowflake. For additional assistance, you can structure your Cortex Search Service off of the below query to effectively leverage the `rag__unified_document` generated from this data model.
    ```sql
    -- Cortex Search Service created using the rag__unified_document model
    
    create cortex search service if not exists <your_schema>.<your_new_search_service_name>
        on chunk
        attributes unique_id
        warehouse = <your_warehouse>
        target_lag = '1 days' --You can specify this to your liking
        as (
            select * from rag__unified_document
        )
    ```

## Under the Hood
- Adjusted the `cluster_by` configuration within the `dbt__unified_rag` to cluster by the `update_date` (previously `unique_id`) for improved Snowflake performance.

# dbt_unified_rag v0.1.0-a1

This is the initial release of the Unified RAG dbt package!

## What does this dbt package do?

The main focus of this dbt package is to generate an end model and [Cortex Search Service](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview) (for Snowflake destinations only) which contains the below relevant unstructured document data to be used for Retrieval Augmented Generation (RAG) applications leveraging Large Language Models (LLMs):
- [HubSpot](https://fivetran.com/docs/connectors/applications/hubspot): Deals
- [Jira](https://fivetran.com/docs/connectors/applications/jira): Issues
- [Zendesk](https://fivetran.com/docs/connectors/applications/zendesk): Tickets  

The following table provides a detailed list of all models materialized within this package by default. 
> TIP: See more details about these models in the package's [dbt docs site](https://fivetran.github.io/dbt_unified_rag/#!/overview/package_name_here).

| **Table**                 | **Description**                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [rag__unified_document](https://github.com/fivetran/dbt_unified_rag/blob/main/models/rag__unified_document.sql)  | Each record represents a chunk of text prepared for semantic-search and additional fields for use in LLM workflows.   |

Additionally, for **Snowflake** destinations, a [Cortex Search Service](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview) will be generated as a result of this data model. The Cortex Search Service uses the results of the `rag__unified_document` and enables Snowflake users to take advantage of low-latency, high quality "fuzzy" search over their data for use in RAG applications leveraging LLMs. See the below table for details.

| **Snowflake Cortex Search Service**     | **Description**                               |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [rag__unified_search](https://github.com/fivetran/dbt_unified_rag/blob/main/macros/search_generation.sql)  |  Generates a Snowflake Cortex Search service via the [search_generation](https://github.com/fivetran/dbt_unified_rag/blob/main/macros/search_generation.sql) macro as a post-hook for Snowflake destinations. This Cortex Search Service is currently configured with a target lag of 1 day. **Please be aware that this search service will refresh automatically once a day even outside of this data model execution.** To understand more about the Cortex Search Service, you can run `SHOW CORTEX SEARCH SERVICES` in the respective Snowflake database.schema which the `rag__unified_document` is materialized. See [here](https://docs.snowflake.com/en/sql-reference/commands-cortex-search) for other relevant commands to use for understanding the nature of the Search Service, and [here](https://docs.snowflake.com/en/sql-reference/functions/search_preview-snowflake-cortex) for helpful commands to use when leveraging the results of the Cortex Search Service in your LLM applications.  |
