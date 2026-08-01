with
    src_ads_insights as (
        select * from {{ source("Meta_Ads", "ads_insights_action_type") }}
    ),
    deduplicated_ads as (
        select
            date_start,
            account_id,
            campaign_id,
            actions,
            row_number() over (partition by ad_id, date_start order by date_start desc) as rn
        from src_ads_insights
        where actions is not null
    ),
    actions_extract as (
        select
            -- -------- dates
            date_start as date,
            -- -------- numeric
            safe_cast(account_id as int) as account_id,
            safe_cast(campaign_id as int) as campaign_id,
            -- -------- JSON
            json_value(action_detail, '$.action_type') as action_type,
            json_value(action_detail, '$.value') as value
        from
            deduplicated_ads,
            unnest(json_extract_array(actions)) as action_detail
        where rn = 1
    ),
    data_agg as (
        select
            date,
            account_id,
            campaign_id,
            action_type,
            sum(safe_cast(value as int)) as action_value
        from actions_extract
        group by date, account_id, campaign_id, action_type
    )
select
    date,
    account_id,
    campaign_id,
    {{ generate_action_type_cases([
    'comment',
    'landing_page_view',
    'lead',
    'like',
    'link_click',
    'offsite_conversion.fb_pixel_custom',
    'offsite_conversion.fb_pixel_lead',
    'offsite_conversion.fb_pixel_purchase',
    'omni_landing_page_view',
    'omni_purchase',
    'onsite_conversion.lead_grouped',
    'onsite_conversion.post_save',
    'onsite_web_app_purchase',
    'onsite_web_lead',
    'onsite_web_purchase',
    'page_engagement',
    'photo_view',
    'post',
    'post_engagement',
    'post_reaction',
    'purchase',
    'video_view',
    'web_app_in_store_purchase',
    'web_in_store_purchase'
]) }}
from data_agg
group by date, account_id, campaign_id