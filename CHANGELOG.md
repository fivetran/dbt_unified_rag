# dbt_unified_rag v0.2.0
[PR #31](https://github.com/fivetran/dbt_unified_rag/pull/31) includes the following updates:

### dbt Fusion Compatibility Updates
- Updated package to maintain compatibility with dbt-core versions both before and after v1.10.6, which introduced a breaking change to multi-argument test syntax (e.g., `unique_combination_of_columns`).
- Temporarily removed unsupported tests to avoid errors and ensure smoother upgrades across different dbt-core versions. These tests will be reintroduced once a safe migration path is available.
  - Removed all `dbt_utils.unique_combination_of_columns` tests.
  - Removed all `accepted_values` tests.
  - Moved `loaded_at_field: _fivetran_synced` under the `config:` block in `src_unified_rag.yml`.

# dbt_unified_rag v0.1.0-a8

[PR #28](https://github.com/fivetran/dbt_unified_rag/pull/28) includes the following updates:

## Breaking Change for dbt Core < 1.9.6

> *Note: This is not relevant to Fivetran Quickstart users.*

Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core. This will resolve the following deprecation warning that users running dbt >= 1.9.6 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `rag_hubspot` in file
`models/staging/hubspot_staging/src_rag_hubspot.yml`. The `freshness` top-level property should be moved
into the `config` of `rag_hubspot`.
```

**IMPORTANT:** Users running dbt Core < 1.9.6 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.6 and want to continue running Unified RAG freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.6
  2. Do not upgrade your installed version of the `unified_rag` package. Pin your dependency on v0.1.0-a7 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's sources and apply freshness via the previous release top-level property route.

## Under the Hood
- Updates to ensure integration tests use latest version of dbt.

# dbt_unified_rag v0.1.0-a7
This release introduces the following updates that **require a full refresh**.

## Bug Fixes 
- Fixed an issue in which [unioned](https://github.com/fivetran/dbt_unified_rag?tab=readme-ov-file#union-multiple-connections) source connections were producing null models. ([#25](https://github.com/fivetran/dbt_unified_rag/pull/25))
  - The solution required the addition of a base staging model layer. For each staging model, there is a `*_base` counterpart in which we are running our `union_data` macro. This framework is necessary to the cooperation of our unioning and column-filling macros, which ensure the models do not fail if you are missing an expected column.
  - For each connector type, this adds:
    - **10 more models if Hubspot is enabled**
    - **5 more models if Jira is enabled**
    - **3 more models if Zendsk is enabled**
- Updated `stg_rag_hubspot__owner` to correctly find columns from the owner source. Previously, this erroneously looked at the columns from the HubSpot `contact` table. ([#23](https://github.com/fivetran/dbt_unified_rag/pull/23))

## Feature Updates
- Adjusted joins to persist records without any comments to each document model ([#25](https://github.com/fivetran/dbt_unified_rag/pull/25)). This may increase the volume of data in each model:
  - `rag_hubspot__document`: HubSpot deals without comments are now included.
  - `rag_jira__document`: Jira issues without comments are now included.
  - `rag_zendesk__document`: Zendesk tickets without comments are now included.
  - `rag__unified_document`: Includes all of the above.
- For each record without any comments, the `most_recent_chunk_update` and `update_date` fields will reflect the deal/issue/ticket creation date. The `chunk_index` and `chunk_tokens_approximate` fields will be `0`. ([#25](https://github.com/fivetran/dbt_unified_rag/pull/25))

## Under the Hood
- Added the `created_on` field to the following intermediate models to support the above inclusion of comment-less document records. ([#25](https://github.com/fivetran/dbt_unified_rag/pull/25))
  - `int_rag_hubspot__deal_document`
  - `int_rag_jira__issue_document`
  - `int_rag_zendesk__ticket_document`
  
## Contributors
- [@levonkorganyan](https://github.com/levonkorganyan) ([#23](https://github.com/fivetran/dbt_unified_rag/pull/23))

# dbt_unified_rag v0.1.0-a6

## Bug Fixes (requires `--full-refresh`)
- Applied `coalesce_cast` macro to all relevant fields that are being concatenated into `comment_markdown`, as any concatenation in Snowflake with a null value returns null. We coalesced 'UNKNOWN' on a string field, and '1970-01-01 00:00:00' on a timestamp field to ensure Snowflake returns chunks of texts for all comments with null components.
- Fields are now coalesced in these intermediate models:
  - Hubspot
    - `int_rag_hubspot__deal_comment_document`: 
      - `email_title` (string) 
      - `body` (string)
      - `comment_time` (timestamp)
    - `int_rag_hubspot__deal_document`: 
      - `title` (string)
      - `created_on` (timestamp)
  - Jira
    - `int_rag_jira__issue_comment_document`:
      - `comment_body` (string)
      - `comment_time` (timestamp)
    - `int_rag_jira__issue_document`: 
      - `title` (string)
      - `created_on` (timestamp)
  - Zendesk
    - `int_rag_zendesk__ticket_comment_document`: 
      - `comment_body` (string)
      - `comment_time` (timestamp)
    - `int_rag_zendesk__ticket_document`:
      - `title` (string) 
      - `created_on` (timestamp)

- Corrected syntax errors for the `default_variable` in `stg_rag_hubspot__engagement_email` and `stg_rag_hubspot__engagement_note`.
- Updated joins to ensure `engagement_deal` is the base in the `int_rag_hubspot__deal_comment_document` CTEs.
- Added `most_recent_document` CTE to `int_rag_*__deal_comment_documents_grouped` models in Hubspot, Jira and Zendesk to correctly bring in the `most_recent_chunk_update` by document.
- Brought in `engagement_type` from the Hubspot `engagement_deal` source to produce proper chunk records in the `rag__unified_document`. 
- Added filters on `email` and `note` types in `int_rag_hubspot__deal_comment_document` when creating email and note chunk records.

## Under the Hood
- Updated Hubspot seed files to ensure proper joins on end models.

# dbt_unified_rag v0.1.0-a5

## Breaking Changes (requires `--full-refresh`)
- Added `title` field to the `rag__unified_document` model and the individual HubSpot, Jira, and Zendesk unstructured `rag_<source>__document` models. ([#17](https://github.com/fivetran/dbt_unified_rag/pull/17))
- This field draws from other pre-existing fields. Its addition therefore includes the following **breaking changes** in upstream staging and intermediate models:
  - Zendesk:
    - `stg_rag_zendesk__ticket`: The ticket `subject` field has been renamed to `title`.
    - `int_rag_zendesk__ticket_document`: The ticket `subject` field has been renamed to `title`.
  - Jira:
    - `stg_rag_jira__issue`: The `issue_name` field (aliased from `summary`) has been renamed to `title`.
    - `int_rag_jira__issue_document`: The `issue_name` field has been renamed to `title`.
  - HubSpot:
    - `stg_rag_hubspot__deal`: The `deal_name` field has been renamed to `title`.
    - `int_rag_hubspot__deal_document`: The `deal_name` field has been renamed to `title`.
    - `stg_rag_hubspot__engagement_email`: The `email_subject` field has been renamed to `title`.
    - `int_rag_hubspot__deal_comment_document`: The `email_subject` field has been renamed to `title`.
    - `stg_rag_hubspot__engagement_note`: The `title` field (value=`"engagement_note"`) has been added.
    - `int_rag_hubspot__deal_comment_documents_grouped`: The `title` (value=`"engagement_note"`) field has been added.

## Bug Fix
- Fixed the HubSpot `url_reference` field to create a valid URL. Previously, we were missing a crucial `/` and therefore created an invalid URL. ([#17](https://github.com/fivetran/dbt_unified_rag/pull/17))

## Under the Hood
- (Maintainers only) Added consistency data validation test for the `rag__unified_document` model. ([#17](https://github.com/fivetran/dbt_unified_rag/pull/17))
 
 ## Documentation
- Added Quickstart model counts to README. ([#18](https://github.com/fivetran/dbt_unified_rag/pull/18))
- Corrected references to connectors and connections in the README. ([#18](https://github.com/fivetran/dbt_unified_rag/pull/18))

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
