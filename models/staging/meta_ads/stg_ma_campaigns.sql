WITH src_campaigns AS (SELECT * FROM {{ source("Meta_Ads", "campaigns") }})

SELECT
  id AS campaign_id,
  name AS campaign_name,
  status as campaign_status,
  objective as campaign_objective,
  -- account_id,
  safe_divide(daily_budget,100) as daily_budget

FROM src_campaigns