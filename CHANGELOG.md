# dbt_unified_rag v0.1.0

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