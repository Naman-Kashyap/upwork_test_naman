with
    camps as (
        select
            date,
            safe_cast(campaign_id as int64) as campaign_id,
            campaign_name,
            account_id,
            account_name,
            account_currency,
            campaign_status,
            campaign_objective,
            daily_budget,
            sum(impressions) as impressions,
            sum(clicks) as clicks,
            sum(spend) as spend

        from {{ ref("fct_ma_ads_insights") }}
        group by
            date,
            campaign_id,
            campaign_name,
            account_id,
            account_name,
            account_currency,
            campaign_status,
            campaign_objective,
            daily_budget
    ),

    actions as (
        select
            safe_cast(campaign_id as int64) as campaign_id,
            date,
            sum(landing_page_view) as landing_page_view,
            sum(onsite_conversion_post_save) as onsite_conversion_post_save,
            sum(page_engagement) as page_engagement,
            sum(post_engagement) as post_engagement,
            sum(like_action) as like_action,
            sum(post_reaction) as post_reaction,
            sum(link_click) as link_click,
            sum(video_view) as video_view,
            sum(photo_view) as photo_view,
            sum(post) as post,
            sum(comment) as comment,
            sum(onsite_conversion_lead_grouped) as onsite_conversion_lead_grouped,
            sum(lead) as lead,
            sum(
                offsite_conversion_fb_pixel_custom
            ) as offsite_conversion_fb_pixel_custom,
            sum(onsite_web_lead) as onsite_web_lead,
            sum(offsite_conversion_fb_pixel_lead) as offsite_conversion_fb_pixel_lead

        from {{ ref("fct_ma_ads_insights_action_types") }}
        group by campaign_id, date
    )

select
    coalesce(cam.date, act.date) as date,
    coalesce(cam.campaign_id, act.campaign_id) as campaign_id,
    campaign_name,
    account_id,
    account_name,
    account_currency,
    campaign_status,
    campaign_objective,
    impressions,
    clicks,
    spend,
    landing_page_view,
    onsite_conversion_post_save,
    page_engagement,
    post_engagement,
    like_action,
    post_reaction,
    link_click,
    video_view,
    photo_view,
    post,
    comment,
    onsite_conversion_lead_grouped,
    lead,
    offsite_conversion_fb_pixel_custom,
    onsite_web_lead,
    offsite_conversion_fb_pixel_lead

from camps as cam
full join actions as act on cam.campaign_id = act.campaign_id and cam.date = act.date
