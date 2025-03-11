{{ config(enabled=var('rag__using_hubspot', True)) }}

with base as (
    
    {{
        fivetran_utils.union_data(
            table_identifier='team', 
            database_variable='rag_hubspot_database', 
            schema_variable='rag_hubspot_schema', 
            default_database=target.database,
            default_schema='rag_hubspot',
            default_variable='hubspot_team',
            union_schema_variable='rag_hubspot_union_schemas',
            union_database_variable='rag_hubspot_union_databases'
        )
    }}
),

fields as (

    select 
        {{
            fivetran_utils.fill_staging_columns(
                source_columns=adapter.get_columns_in_relation(source('rag_hubspot','team')),
                staging_columns= [
                    {"name": "_fivetran_synced", "datatype": dbt.type_timestamp()},
                    {"name": "_fivetran_deleted", "datatype": dbt.type_boolean()},
                    {"name": "id", "datatype": dbt.type_int()},
                    {"name": "name", "datatype": dbt.type_string()}
                ]
            )
        }}

        {{ fivetran_utils.source_relation(
            union_schema_variable='rag_hubspot_union_schemas', 
            union_database_variable='rag_hubspot_union_databases') 
        }}
    from base
),

final as (

    select
        id,
        name,
        source_relation,
        _fivetran_deleted
        cast(_fivetran_synced as {{ dbt.type_timestamp() }}) as _fivetran_synced,
    from fields 
) 

select *
from final