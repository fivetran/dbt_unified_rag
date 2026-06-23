<!--section="unified-rag_transformation_model"-->
# Unified RAG dbt Package

This dbt package transforms data from Fivetran's Unified RAG connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 40
- Connector documentation
  - [HubSpot](https://fivetran.com/docs/connectors/applications/hubspot#hubspot)
  - [Jira](https://fivetran.com/docs/connectors/applications/jira#jira)
  - [Zendesk](https://fivetran.com/docs/connectors/applications/zendesk#zendesksupport)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_unified_rag)
  - [dbt Docs](https://fivetran.github.io/dbt_unified_rag/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_unified_rag/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_unified_rag/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package enables you to generate unstructured document data for Retrieval Augmented Generation (RAG) applications and combine data from HubSpot deals, Jira issues, and Zendesk tickets. It creates enriched models with metrics focused on text chunks prepared for semantic search and LLM workflows.

Note: Redshift destinations are not currently supported due to the stringent character limitations within string datatypes. If you would like Redshift destinations to be supported, please comment within our logged [Feature Request](https://github.com/fivetran/dbt_unified_rag/issues/3).

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_unified_rag
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [rag__unified_document](https://fivetran.github.io/dbt_unified_rag/#!/model/model.unified_rag.rag__unified_document) | Prepares text content from multiple data sources into searchable chunks that enable natural language queries through AI chatbots, making your data easily accessible through conversational questions. <br></br>**Example Analytics Questions:**<ul><li>What features are customers requesting most frequently?</li><li>What topics are mentioned most during sales or deal discussions?</li><li>What common issues or themes appear across support conversations?</li></ul>|

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites
To use this dbt package, you must have the following:

- At least one of the below support Fivetran connections syncing data into your destination.
    - [HubSpot](https://fivetran.com/docs/connectors/applications/hubspot) (specifically deals)
    - [Jira](https://fivetran.com/docs/connectors/applications/jira)
    - [Zendesk Support](https://fivetran.com/docs/connectors/applications/zendesk)
- A **Snowflake**, **BigQuery**, **Databricks**, or **PostgreSQL** destination.
    - Redshift destinations are not currently supported due to the stringent character limitations within string datatypes. If you would like Redshift destinations to be supported, please comment within our logged [Feature Request](https://github.com/fivetran/dbt_unified_rag/issues/3).

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_unified_rag/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the package
Include the following package_display_name package version in your `packages.yml` file:
> TIP: Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/unified_rag
    version: [">=0.3.0", "<0.4.0"]
```

### Define database and schema variables
#### Option A: Single connection
By default, this package runs using your destination and the `unified_rag` schema. If this is not where your Unified RAG data is (for example, if your Unified RAG schema is named `unified_rag_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    unified_rag_database: your_destination_name
    unified_rag_schema: your_schema_name
```

#### Option B: Union multiple connections
If you have multiple Unified RAG connections in Fivetran and would like to use this package on all of them simultaneously, we have provided functionality to do so. For each source table, the package will union all of the data together and pass the unioned table into the transformations. The `source_relation` column in each model indicates the origin of each record.

To use this functionality, you will need to set the `unified_rag_sources` variable in your root `dbt_project.yml` file:

```yml
# dbt_project.yml

vars:
  rag_hubspot_sources:
    - database: connection_1_destination_name # Required
      schema: connection_1_schema_name # Required
      name: connection_1_source_name # Required only if following the step in the following subsection

    - database: connection_2_destination_name
      schema: connection_2_schema_name
      name: connection_2_source_name

  rag_jira_sources:
    - database: connection_1_destination_name # Required
      schema: connection_1_schema_name # Required
      name: connection_1_source_name # Required only if following the step in the following subsection

    - database: connection_2_destination_name
      schema: connection_2_schema_name
      name: connection_2_source_name

  rag_zendesk_sources:
    - database: connection_1_destination_name # Required
      schema: connection_1_schema_name # Required
      name: connection_1_source_name # Required only if following the step in the following subsection

    - database: connection_2_destination_name
      schema: connection_2_schema_name
      name: connection_2_source_name
```

> Previous versions of this package employed two separate, mutually exclusive variables for unioning: `rag_*_union_schemas` and `rag_*_union_databases`. While these variables are still supported, `rag_*_sources` is the recommended variable to configure.

#### Optional: Incorporate unioned sources into DAG

If you use [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore) and are unioning multiple Unified RAG connections, you can define your sources in a property `.yml` file. Set the variable `has_defined_sources: true` under the Unified RAG namespace in your `dbt_project.yml`. Otherwise, your Unified RAG connections won't appear in your DAG. See the `union_connections` macro [documentation](https://github.com/fivetran/dbt_fivetran_utils/tree/releases/v0.4.latest#optional-union-connections-defined-sources-configuration) for full configuration details.

### Enabling/Disabling Models
This package takes into consideration that not every account will have leverage every supported connector type. If you do not leverage all of the supported connector types, you are able to disable the respective dependent models using the below variables in your `dbt_project.yml`.

```yml
vars:
    rag__using_hubspot: False # by default this is assumed to be True
    rag__using_jira: False # by default this is assumed to be True
    rag__using_zendesk: False # by default this is assumed to be True
```

### (Optional) Additional configurations
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

#### Source casing for case-sensitive destinations
By default, the package applies case-insensitive comparisons when resolving `source_relation` values. If your destination is case-sensitive and you want downstream transformations to respect the exact casing of your source database and schema names, set the following variable:

```yml
vars:
    fivetran_using_source_casing: true
```
</details>

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement). Learn how to set up your project for orchestration through Fivetran in our [Transformations for dbt Core setup guides](https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement#setupguide).
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

<!--section="unified-rag_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/unified_rag/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_unified_rag/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you have questions or want to reach out for help, refer to the [GitHub Issue](https://github.com/fivetran/dbt_unified_rag/issues/new/choose) section to find the right avenue of support for you.
- If you want to provide feedback to the dbt package team at Fivetran or want to request a new dbt package, fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).