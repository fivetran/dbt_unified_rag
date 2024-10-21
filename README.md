# Unified RAG dbt Package ([Docs](https://fivetran.github.io/dbt_unified_rag/))

<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_unified_rag/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

## What does this dbt package do?

<!--section="unified_rag_transformation_model"-->
The main focus of this dbt package is to generate an end model and [Cortex Search Service](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview) (for Snowflake destinations only) which contains the below relevant unstructured document data to be used for Retrieval Augmented Generation (RAG) applications leveraging Large Language Models (LLMs):
- [HubSpot](https://fivetran.com/docs/connectors/applications/hubspot): Deals
- [Jira](https://fivetran.com/docs/connectors/applications/jira): Issues
- [Zendesk](https://fivetran.com/docs/connectors/applications/zendesk): Tickets  

The following table provides a detailed list of all models materialized within this package by default. 
> TIP: See more details about these models in the package's [dbt docs site](https://fivetran.github.io/dbt_unified_rag/#!/overview).

| **Table**                 | **Description**                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [rag__unified_document](https://fivetran.github.io/dbt_unified_rag/#!/model/model.unified_rag.rag__unified_document)  | Each record represents a chunk of text prepared for semantic-search and additional fields for use in LLM workflows.   |

Additionally, for **Snowflake** destinations, a [Cortex Search Service](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview) will be generated as a result of this data model. The Cortex Search Service uses the results of the `rag__unified_document` and enables Snowflake users to take advantage of low-latency, high quality "fuzzy" search over their data for use in RAG applications leveraging LLMs. See the below table for details.

| **Snowflake Cortex Search Service**     | **Description**                               |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [rag__unified_search](https://github.com/fivetran/dbt_unified_rag/blob/main/macros/search_generation.sql)  |  Generates a Snowflake Cortex Search service via the [search_generation](https://github.com/fivetran/dbt_unified_rag/blob/main/macros/search_generation.sql) macro as a post-hook for Snowflake destinations. This Cortex Search Service is currently configured with a target lag of 1 day. **Please be aware that this search service will refresh automatically once a day even outside of this data model execution.** To understand more about the Cortex Search Service, you can run `SHOW CORTEX SEARCH SERVICES` in the respective Snowflake database.schema which the `rag__unified_document` is materialized. See [here](https://docs.snowflake.com/en/sql-reference/commands-cortex-search) for other relevant commands to use for understanding the nature of the Search Service, and [here](https://docs.snowflake.com/en/sql-reference/functions/search_preview-snowflake-cortex) for helpful commands to use when leveraging the results of the Cortex Search Service in your LLM applications.  |
<!--section-end-->

## How do I use the dbt package?

### Step 1: Prerequisites
To use this dbt package, you must have the following:

- At least one of the below support Fivetran connectors syncing data into your destination.
    - [HubSpot](https://fivetran.com/docs/connectors/applications/hubspot) (specifically deals)
    - [Jira](https://fivetran.com/docs/connectors/applications/jira)
    - [Zendesk Support](https://fivetran.com/docs/connectors/applications/zendesk)
- A **Snowflake**, **BigQuery**, **Databricks**, or **PostgreSQL** destination.
    - Please note, the Cortex Search Service will only be generated for Snowflake destinations.
    - Redshift destinations are not currently supported due to the stringent character limitations within string datatypes. If you would like Redshift destinations to be supported, please comment within our logged [Feature Request](https://github.com/fivetran/dbt_unified_rag/issues/3).

### Step 2: Install the package
Include the following package_display_name package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/unified_rag
    version: [">=0.1.0", "<0.2.0"] # we recommend using ranges to capture non-breaking changes automatically
```

### Step 3: Define database and schema variables
#### Single connector
By default, this package looks for your HubSpot, Jira, and/or Zendesk data in your target database. If this is not where your data is stored, add the relevant `<connector>_database` variables to your `dbt_project.yml` file (see below).

```yml
# dbt_project.yml

vars:
    rag_hubspot_schema: hubspot
    rag_hubspot_database: your_database_name

    rag_jira_schema: jira
    rag_jira_database: your_database_name

    rag_zendesk_schema: zendesk
    rag_zendesk_database: your_database_name
```
#### Union multiple connectors
If you have multiple supported connectors in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. The package will union all of the data together and pass the unioned table into the transformations. You will be able to see which source it came from in the source_relation column of each model. To use this functionality, you will need to set either the `<package_name>_union_schemas` OR `<package_name>_union_databases` variables (cannot do both) in your root `dbt_project.yml` file. Below are the variables and examples for each connector:

```yml
# dbt_project.yml

vars:
    rag_hubspot_union_schemas: ['hubspot_rag_test_one', 'hubspot_rag_test_two']
    rag_hubspot_union_databases: ['hubspot_rag_test_one', 'hubspot_rag_test_two']

    rag_jira_union_schemas: ['jira_rag_test_one', 'jira_rag_test_two']
    rag_jira_union_databases: ['jira_rag_test_one', 'jira_rag_test_two']

    rag_zendesk_union_schemas: ['zendesk_rag_test_one', 'zendesk_rag_test_two']
    rag_zendesk_union_databases: ['zendesk_rag_test_one', 'zendesk_rag_test_two']
```

The native `source.yml` connection set up in the package will not function when the union schema/database feature is utilized. Although the data will be correctly combined, you will not observe the sources linked to the package models in the Directed Acyclic Graph (DAG). This happens because the package includes only one defined `source.yml`.

To connect your multiple schema/database sources to the package models, follow the steps outlined in the [Union Data Defined Sources Configuration](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#union_data-source) section of the Fivetran Utils documentation for the union_data macro. This will ensure a proper configuration and correct visualization of connections in the DAG.

### Step 4: Enabling/Disabling Models
This package takes into consideration that not every account will have leverage every supported connector type. If you do not leverage all of the supported connector types, you are able to disable the respective dependent models using the below variables in your `dbt_project.yml`.

```yml
vars:
    rag__using_hubspot: False # by default this is assumed to be True
    rag__using_jira: False # by default this is assumed to be True
    rag__using_zendesk: False # by default this is assumed to be True
```

### (Optional) Step 5: Additional configurations
#### Customizing Chunk Size for Vectorization
The `rag__unified_document` and upstream platform specific `*__document` models were developed to limit approximate chunk sizes to 5,000 tokens, optimized for OpenAI models. However, you can adjust this limit by setting the max_tokens variable in your `dbt_project.yml`:
```yml
vars:
    document_max_tokens: 5000 # Default value
```

#### Changing the Build Schema
By default this package will build the Unified RAG staging models within a schema titled (<target_schema> + `_unified_rag_source`) and the Unified RAG final models within a schema titled (<target_schema> + `_unified_rag`) in your target database. If this is not where you want your modeled Unified RAG data to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
models:
    unified_rag:
        +schema: my_new_schema_name # leave blank for just the target_schema
        staging:
            +schema: my_new_schema_name # leave blank for just the target_schema
```

#### Change the source table references
If an individual source table has a different name than the package expects, add the table name as it appears in your destination to the respective variable:

> IMPORTANT: See this project's [`dbt_project.yml`](https://github.com/fivetran/dbt_unified_rag/blob/main/dbt_project.yml) variable declarations to see the expected names.

```yml
# dbt_project.yml

vars:
    rag_<default_source_table_name>_identifier: your_table_name 
```
</details>


### (Optional) Step 6: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/dbt#setupguide).
</details>


## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the following packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> IMPORTANT: If you have any of these dependent packages in your own `packages.yml` file, we highly recommend that you remove them from your root `packages.yml` to avoid package version conflicts.
    
```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]
```
## How is this package maintained and can I contribute?
### Package Maintenance
The Fivetran team maintaining this package _only_ maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/dbt_unified_rag/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_unified_rag/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Check out [this dbt Discourse article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package.

## Are there any resources available?
- If you have questions or want to reach out for help, refer to the [GitHub Issue](https://github.com/fivetran/dbt_unified_rag/issues/new/choose) section to find the right avenue of support for you.
- If you want to provide feedback to the dbt package team at Fivetran or want to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).