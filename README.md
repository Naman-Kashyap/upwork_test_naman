Meta Ads Marketing Data Pipeline

Pulls Meta Ads campaign-level daily performance into BigQuery and models it with dbt into a clean mart, with a couple of data quality checks along the way.

Running this

You'll need Python 3.10+, the gcloud CLI logged in (gcloud auth application-default login), a BigQuery project [FILL IN: your project id, region], and dbt-core + dbt-bigquery installed (pip install -r requirements.txt).

bash
pip install -r requirements.txt


cp profiles.yml.example ~/.dbt/profiles.yml   

Project ID - upwork-test-504106 
Location - EU
dbt run
dbt test
dbt source freshness
Architecture
Meta Ads API
      |
      v   Airbyte (Facebook Marketing connector)
Meta_Ads.ads_insights, campaigns, ads_insights_action_type, custom_conversions
      |
      v
staging.stg_ma_ads_insights etc
      |
      v
core.fct_ma_ads_insights — e.g. conform action types via the macro, dedup
      |
      v
marts.mrt_ma_ads_insights   -- one row per campaign per day

Staging → core → marts is the usual dbt layering: staging does the renaming/casting once so nothing downstream has to touch raw column names, core is where shared logic lives so it's not duplicated across marts, and marts is the only layer anyone outside the pipeline should query. Mostly this is about being able to tell where a bug lives when something breaks, rather than any of it being clever.

Airbyte over Fivetran mainly came down to how each handles multiple ad accounts. Airbyte's Facebook Marketing connector takes a list of account IDs in a single connection, so every client's data can land in the same raw tables, split out by account_id, without spinning up a new connection per client. Fivetran can technically do multiple accounts per connection too, but their docs recommend splitting large account lists across separate connections to avoid Meta API rate limits — so at real scale you end up managing a similar number of connections either way. Two things worth flagging from actually using it: Airbyte's conversion action data (ads_insights_action_type) isn't fully accurate, so I wouldn't lean on it if a client needs precise conversion attribution, and its LinkedIn Ads connector gets noticeably slow once you're running several connections at once, so that's one I'd reconsider if this ever extends past Meta.

BigQuery because it has native integration with GA4 and Google Ads, which matters if this pipeline ends up sitting next to those sources for the same clients down the line. It also gives direct access to INFORMATION_SCHEMA, which the schema-drift test below queries directly, and on-demand pricing fits a multi-tenant setup where query volume swings a lot from client to client.

Data quality checks

Two are wired in. Freshness runs off _airbyte_extracted_at on the raw source tables — Airbyte populates this on every sync, so there's no need for a separate load-timestamp column. It warns after 24 hours without a sync and fails after 48; check dbt_project.yml/sources.yml and adjust if your Airbyte connection runs on a different schedule than that.

The second is a schema-drift test comparing INFORMATION_SCHEMA.COLUMNS on the raw table against the columns the staging model expects. If Meta adds, renames, or drops a field on their end, this catches it before it silently breaks (or silently nulls out) something downstream, rather than someone noticing a mart looks wrong three weeks later.

What I'd harden before production

The raw load right now can overwrite the whole table on each run rather than appending incrementally with dedup on re-delivered days, which is fine for a 30-day backfill but not for ongoing daily loads. There's no orchestration either — production would need this on a scheduler (Composer, Airflow, or even just a GitHub Actions cron) running ingest, then dbt build, then dbt test, as one pipeline with failure alerting wired to Slack or email instead of just a non-zero exit code nobody sees. Local ADC auth is fine for a test task but production needs a scoped service account with keys in Secret Manager, not sitting on someone's laptop. I'd also widen test coverage past what's here — relationship tests between the core and mart layers, accepted-values checks on fields like objective and currency, and something that flags a day's row count looking abnormal compared to the trailing average, since that catches problems freshness and schema tests won't.

Making this multi-tenant

Depends on which ingestion tool is in play. With Airbyte, every client's account can go into the same connection, and you filter by account_id downstream — at the mart layer, or in whatever BI tool is consuming this, whichever fits the access model better. With Fivetran, the cleaner pattern is one schema per client with a consistent naming convention (meta_ads_client_name), same table names inside every schema, and a macro that unions them all together in staging:

sql
{% macro union_fb_clients(table_name) %}
{% set clients = var('fb_clients') %}
{% set client_cols = {} %}
{% set all_columns = [] %}
{% for client in clients %}
    {% set rel = source(client, table_name) %}
    {% set cols = adapter.get_columns_in_relation(rel) %}
    {% set col_names = cols | map(attribute='name') | list %}
    {% do client_cols.update({client: col_names}) %}
    {% for col in col_names %}
        {% if col not in all_columns %}
            {% do all_columns.append(col) %}
        {% endif %}
    {% endfor %}
{% endfor %}
{# Pass 2: build a select per client, NULL-padding any missing column #}
{% set selects = [] %}
{% for client in clients %}
    {% set rel = source(client, table_name) %}
    {% set col_names = client_cols[client] %}
    {% set select_cols = [] %}
    {% for col in all_columns %}
        {% if col in col_names %}
            {% do select_cols.append(col) %}
        {% else %}
            {% do select_cols.append('NULL AS ' ~ col) %}
        {% endif %}
    {% endfor %}
    {% do selects.append(
        "select '" ~ client ~ "' as client_name, " ~ (select_cols | join(', ')) ~ " from " ~ rel
    ) %}
{% endfor %}
{{ selects | join(' UNION ALL ') }}
{% endmacro %}

The NULL-padding is what makes this work when one client's raw schema is missing a column another client has — rather than the union breaking, that client just gets NULL for it. It's really the same idea as the schema-drift test above, just applied across clients instead of across time.

AI tools

Claude has been used for the macros