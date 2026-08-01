select
    date,
    account_id,
    safe_cast(campaign_id as int64) as campaign_id,
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
    sum(offsite_conversion_fb_pixel_custom) as offsite_conversion_fb_pixel_custom,
    sum(onsite_web_lead) as onsite_web_lead,
    sum(offsite_conversion_fb_pixel_lead) as offsite_conversion_fb_pixel_lead

from {{ ref("stg_ma_ads_insights_action_types") }}
group by date, account_id, campaign_id
