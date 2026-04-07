-- ============================================================
--  Improvado Technical Assignment – BigQuery Setup
--  Dataset: marketing_analysis
--  Author : Gustavo Muñoz
-- ============================================================
 
-- ────────────────────────────────────────────────────────────
-- 1. SOURCE TABLES 
-- ────────────────────────────────────────────────────────────
 
CREATE OR REPLACE TABLE `improvado-marketing.marketing_analysis.facebook_ads` (
  date               DATE,
  campaign_id        STRING,
  campaign_name      STRING,
  ad_set_id          STRING,
  ad_set_name        STRING,
  impressions        INT64,
  clicks             INT64,
  spend              FLOAT64,
  conversions        INT64,
  video_views        INT64,
  engagement_rate    FLOAT64,
  reach              INT64,
  frequency          FLOAT64
);
 
CREATE OR REPLACE TABLE `improvado-marketing.marketing_analysis.google_ads` (
  date                      DATE,
  campaign_id               STRING,
  campaign_name             STRING,
  ad_group_id               STRING,
  ad_group_name             STRING,
  impressions               INT64,
  clicks                    INT64,
  cost                      FLOAT64,
  conversions               INT64,
  conversion_value          FLOAT64,
  ctr                       FLOAT64,
  avg_cpc                   FLOAT64,
  quality_score             INT64,
  search_impression_share   FLOAT64
);
 
CREATE OR REPLACE TABLE `improvado-marketing.marketing_analysis.tiktok_ads` (
  date              DATE,
  campaign_id       STRING,
  campaign_name     STRING,
  adgroup_id        STRING,
  adgroup_name      STRING,
  impressions       INT64,
  clicks            INT64,
  cost              FLOAT64,
  conversions       INT64,
  video_views       INT64,
  video_watch_25    INT64,
  video_watch_50    INT64,
  video_watch_75    INT64,
  video_watch_100   INT64,
  likes             INT64,
  shares            INT64,
  comments          INT64
);
 
 
-- ────────────────────────────────────────────────────────────
-- 2. TABLA DE REFERENCIA: objetivos de campaña
--
--    El objetivo de cada campaña es un hecho del negocio,
--    no una decisión de presentación — va en el SQL.
--
--    Usamos una tabla de referencia explícita.
-- ────────────────────────────────────────────────────────────
 
CREATE OR REPLACE TABLE `improvado-marketing.marketing_analysis.campaign_objectives` (
  campaign_name      STRING,
  campaign_objective STRING,   -- Awareness | Traffic | Conversion | Engagement
  funnel_stage       STRING    -- top | mid | bottom
);
 
INSERT INTO `improvado-marketing.marketing_analysis.campaign_objectives` VALUES
  -- Facebook
  ('Brand_Awareness_Q1',      'Awareness',   'top'),
  ('Video_Views_Campaign',    'Awareness',   'top'),
  ('Traffic_Drive_Jan',       'Traffic',     'mid'),
  ('Conversions_Retargeting', 'Conversion',  'bottom'),
  -- Google
  ('Search_Brand_Terms',      'Awareness',   'top'),
  ('Search_Generic_Terms',    'Traffic',     'mid'),
  ('Shopping_All_Products',   'Conversion',  'bottom'),
  ('Display_Remarketing',     'Conversion',  'bottom'),
  -- TikTok
  ('Awareness_GenZ',          'Awareness',   'top'),
  ('Traffic_Campaign',        'Traffic',     'mid'),
  ('Conversion_Focus',        'Conversion',  'bottom'),
  ('Influencer_Collab',       'Engagement',  'mid');
 
 
-- ────────────────────────────────────────────────────────────
-- 3. UNIFIED TABLE  (máxima granularidad: 1 fila por fecha +
--    plataforma + campaña + ad group)
-- ────────────────────────────────────────────────────────────
 
CREATE OR REPLACE TABLE `improvado-marketing.marketing_analysis.unified_ads` AS
 
WITH raw_unified AS (
 
  -- ── FACEBOOK ──────────────────────────────────────────────
  SELECT
    date,
    'Facebook'                                        AS platform,
    campaign_id,
    campaign_name,
    ad_set_id                                         AS ad_group_id,
    ad_set_name                                       AS ad_group_name,
    FORMAT_DATE('%A', date)                             AS day_of_week,
    EXTRACT(DAYOFWEEK FROM date)                      AS day_of_week_num,
    impressions,
    clicks,
    spend                                             AS cost,
    conversions,
    ROUND(SAFE_DIVIDE(clicks, impressions) * 100, 4)  AS ctr,
    ROUND(SAFE_DIVIDE(spend, clicks), 4)              AS avg_cpc,
    ROUND(SAFE_DIVIDE(conversions, clicks) * 100, 4)  AS cvr,
    ROUND(SAFE_DIVIDE(spend, conversions), 4)         AS cpa,
    ROUND(SAFE_DIVIDE(spend, impressions) * 1000, 4)  AS cpm,
    video_views,
    ROUND(SAFE_DIVIDE(video_views, impressions) * 100, 4) AS video_view_rate,
    reach,
    frequency,
    engagement_rate,
    CAST(NULL AS FLOAT64)                             AS conversion_value,
    CAST(NULL AS FLOAT64)                             AS roas,
    CAST(NULL AS INT64)                               AS quality_score,
    CAST(NULL AS FLOAT64)                             AS search_impression_share,
    CAST(NULL AS INT64)                               AS video_watch_25,
    CAST(NULL AS INT64)                               AS video_watch_50,
    CAST(NULL AS INT64)                               AS video_watch_75,
    CAST(NULL AS INT64)                               AS video_watch_100,
    CAST(NULL AS FLOAT64)                             AS video_completion_rate,
    CAST(NULL AS INT64)                               AS likes,
    CAST(NULL AS INT64)                               AS shares,
    CAST(NULL AS INT64)                               AS comments,
    CAST(NULL AS FLOAT64)                             AS social_engagement_rate
  FROM `improvado-marketing.marketing_analysis.facebook_ads`
 
  UNION ALL
 
  -- ── GOOGLE ADS ────────────────────────────────────────────
  SELECT
    date,
    'Google'                                          AS platform,
    campaign_id,
    campaign_name,
    ad_group_id,
    ad_group_name,
    FORMAT_DATE('%A', date)                             AS day_of_week,
    EXTRACT(DAYOFWEEK FROM date)                      AS day_of_week_num,
    impressions,
    clicks,
    cost,
    conversions,
    ROUND(SAFE_DIVIDE(clicks, impressions) * 100, 4)  AS ctr,
    ROUND(avg_cpc, 4)                                 AS avg_cpc,
    ROUND(SAFE_DIVIDE(conversions, clicks) * 100, 4)  AS cvr,
    ROUND(SAFE_DIVIDE(cost, conversions), 4)          AS cpa,
    ROUND(SAFE_DIVIDE(cost, impressions) * 1000, 4)   AS cpm,
    CAST(NULL AS INT64)                               AS video_views,
    CAST(NULL AS FLOAT64)                             AS video_view_rate,
    CAST(NULL AS INT64)                               AS reach,
    CAST(NULL AS FLOAT64)                             AS frequency,
    CAST(NULL AS FLOAT64)                             AS engagement_rate,
    conversion_value,
    ROUND(SAFE_DIVIDE(conversion_value, cost), 4)     AS roas,
    quality_score,
    search_impression_share,
    CAST(NULL AS INT64)                               AS video_watch_25,
    CAST(NULL AS INT64)                               AS video_watch_50,
    CAST(NULL AS INT64)                               AS video_watch_75,
    CAST(NULL AS INT64)                               AS video_watch_100,
    CAST(NULL AS FLOAT64)                             AS video_completion_rate,
    CAST(NULL AS INT64)                               AS likes,
    CAST(NULL AS INT64)                               AS shares,
    CAST(NULL AS INT64)                               AS comments,
    CAST(NULL AS FLOAT64)                             AS social_engagement_rate
  FROM `improvado-marketing.marketing_analysis.google_ads`
 
  UNION ALL
 
  -- ── TIKTOK ADS ────────────────────────────────────────────
  SELECT
    date,
    'TikTok'                                          AS platform,
    campaign_id,
    campaign_name,
    adgroup_id                                        AS ad_group_id,
    adgroup_name                                      AS ad_group_name,
    FORMAT_DATE('%A', date)                             AS day_of_week,
    EXTRACT(DAYOFWEEK FROM date)                      AS day_of_week_num,
    impressions,
    clicks,
    cost,
    conversions,
    ROUND(SAFE_DIVIDE(clicks, impressions) * 100, 4)  AS ctr,
    ROUND(SAFE_DIVIDE(cost, clicks), 4)               AS avg_cpc,
    ROUND(SAFE_DIVIDE(conversions, clicks) * 100, 4)  AS cvr,
    ROUND(SAFE_DIVIDE(cost, conversions), 4)          AS cpa,
    ROUND(SAFE_DIVIDE(cost, impressions) * 1000, 4)   AS cpm,
    video_views,
    ROUND(SAFE_DIVIDE(video_views, impressions) * 100, 4)     AS video_view_rate,
    CAST(NULL AS INT64)                               AS reach,
    CAST(NULL AS FLOAT64)                             AS frequency,
    CAST(NULL AS FLOAT64)                             AS engagement_rate,
    CAST(NULL AS FLOAT64)                             AS conversion_value,
    CAST(NULL AS FLOAT64)                             AS roas,
    CAST(NULL AS INT64)                               AS quality_score,
    CAST(NULL AS FLOAT64)                             AS search_impression_share,
    video_watch_25,
    video_watch_50,
    video_watch_75,
    video_watch_100,
    ROUND(SAFE_DIVIDE(video_watch_100, video_views) * 100, 4) AS video_completion_rate,
    likes,
    shares,
    comments,
    ROUND(SAFE_DIVIDE(likes + shares + comments, impressions) * 100, 4) AS social_engagement_rate
  FROM `improvado-marketing.marketing_analysis.tiktok_ads`
 
)
 
-- JOIN con la tabla de referencia para agregar objetivo y etapa de funnel
SELECT
  r.*,
  o.campaign_objective,
  o.funnel_stage
FROM raw_unified r
LEFT JOIN `improvado-marketing.marketing_analysis.campaign_objectives` o
  ON r.campaign_name = o.campaign_name
;
 
 
-- ────────────────────────────────────────────────────────────
-- 4. VALIDATION QUERIES 
-- ────────────────────────────────────────────────────────────
 
-- Conteo de filas por plataforma (esperado: 110 cada una)
SELECT platform, COUNT(*) AS rows
FROM `improvado-marketing.marketing_analysis.unified_ads`
GROUP BY 1
ORDER BY 1;
 
-- Totales por plataforma
SELECT
  platform,
  ROUND(SUM(cost), 2)                                AS total_cost,
  SUM(impressions)                                   AS total_impressions,
  SUM(conversions)                                   AS total_conversions,
  ROUND(SAFE_DIVIDE(SUM(cost), SUM(conversions)), 2) AS blended_cpa
FROM `improvado-marketing.marketing_analysis.unified_ads`
GROUP BY 1
ORDER BY 1;
 
-- Rango de fechas
SELECT
  platform,
  MIN(date)            AS first_date,
  MAX(date)            AS last_date,
  COUNT(DISTINCT date) AS active_days
FROM `improvado-marketing.marketing_analysis.unified_ads`
GROUP BY 1;
 
-- Verificar que todos los objetivos quedaron asignados (no debe haber NULLs)
SELECT
  campaign_name,
  campaign_objective,
  funnel_stage,
  COUNT(*) AS rows
FROM `improvado-marketing.marketing_analysis.unified_ads`
GROUP BY 1, 2, 3
ORDER BY campaign_objective, campaign_name;