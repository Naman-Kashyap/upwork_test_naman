with
    src_ad_insights as (
        select
            account_id,
            account_name,
            date(date_start) as date,
            campaign_id,
            campaign_name,
            objective as campaign_objective,
            spend,
            clicks,
            impressions,
            account_currency,
            row_number() over (
                partition by account_id, ad_id, date_start order by impressions desc
            ) as rn,
            {{ extract_form_metrics('conversions') }}
        from {{ source("Meta_Ads", "ads_insights") }}
    )

select *

from src_ad_insights
where rn = 1