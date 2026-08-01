with
    ma_ad_insights as (
        select
            account_id,
            account_name,
            date,
            campaign_id,
            campaign_name,
            campaign_objective,
            sum(spend) as spend,
            sum(clicks) as clicks,
            sum(impressions) as impressions,
            max(account_currency) as account_currency,
            sum(form_submit) as form_submit,
            sum(form_interaction) as form_interaction

        from {{ ref("stg_ma_ads_insights") }}
        group by
            account_id,
            account_name,
            date,
            campaign_id,
            campaign_name,
            campaign_objective
    ),

    campaigns as (
        select distinct
            campaign_id,
            campaign_name,
            campaign_status,
            campaign_objective,
            daily_budget

        from {{ ref("stg_ma_campaigns") }}
    )

select
    date,
    cam.campaign_status,
    spend,
    clicks,
    impressions,
    account_currency,
    daily_budget,
    account_id,
    account_name,
    coalesce(cam.campaign_id, ai.campaign_id) as campaign_id,
    coalesce(cam.campaign_name, ai.campaign_name) as campaign_name,
    coalesce(cam.campaign_objective, ai.campaign_objective) as campaign_objective,
    form_submit,
    form_interaction

from ma_ad_insights as ai
left join campaigns as cam on ai.campaign_id = cam.campaign_id
