{{ config(enabled=var('rag__using_jira', True)) }}

with issues as (

    select *
        --specify the jira subdomain value in your `dbt_project.yml` to generate the proper link to your issue (for our purposes, it would be 'fivetraninc') to generate proper Fivetran Jira links.
        {% if var('jira_subdomain', default=None) %}
        ,'{{ var("jira_subdomain") }}' as jira_subdomain_value
        {% endif %}
    from {{ ref('stg_rag_jira__issue') }}
), 

users as (

    select *
    from {{ ref('stg_rag_jira__user') }}
), 

{% if var('rag_jira_using_priorities', True) %}
priorities as (

    select *
    from {{ ref('stg_rag_jira__priority') }}
),
{% endif %}

statuses as (

    select *
    from {{ ref('stg_rag_jira__status') }}
),

issue_details as (

    select
        issues.issue_id,
        issues.title,
        {% if var('jira_subdomain', default=None) %}
            {{ dbt.concat(["'https://'", "jira_subdomain_value", "'.atlassian.net/browse/'", "issues.issue_key"]) }} as url_reference,
        {% else %}
            cast(null as {{ dbt.type_string() }}) as url_reference,
        {% endif %}
        issues.source_relation,
        {{ unified_rag.coalesce_cast(["users.user_display_name", "'UNKNOWN'"], dbt.type_string()) }} as user_name,
        {{ unified_rag.coalesce_cast(["users.email", "'UNKNOWN'"], dbt.type_string()) }} as created_by,
        issues.created_at AS created_on,
        {{ unified_rag.coalesce_cast(["statuses.status_name", "issues.status_id", "'UNKNOWN'"], dbt.type_string()) }} as status,
        {% if var('jira_using_priorities', True) %}
            {{ unified_rag.coalesce_cast(["priorities.priority_name", "issues.priority_id", "'UNKNOWN'"], dbt.type_string()) }} as priority
        {% else %}
            {{ unified_rag.coalesce_cast(["issues.priority_id", "'UNKNOWN'"], dbt.type_string()) }} as priority
        {% endif %}
    from issues
    left join users
        on issues.reporter_user_id = users.user_id 
        and issues.source_relation = users.source_relation
    left join statuses
        on issues.status_id = statuses.status_id
    {% if var('jira_using_priorities', True) %}
    left join priorities 
        on issues.priority_id = priorities.priority_id
    {% endif %}
), 

final as (

    select
        issue_id,
        title,
        source_relation,
        url_reference,
        {{ dbt.concat([
            "'# issue : '", "title", "'\\n\\n'",
            "'Created By : '", "user_name", "' ('", "created_by", "')\\n'",
            "'Created On : '", "created_on", "'\\n'",
            "'Status : '", "status", "'\\n'",
            "'Priority : '", "priority"
        ]) }} as issue_markdown
    from issue_details
)

select 
    *,
    {{ unified_rag.count_tokens("issue_markdown") }} as issue_tokens
from final