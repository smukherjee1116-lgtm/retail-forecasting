-- Master feature table combining all features
-- This is what Prophet and XGBoost will consume
CREATE OR REPLACE VIEW v_features AS
WITH base AS (
    SELECT
        "Store",
        "Date",
        "Sales",
        "DayOfWeek",
        "Promo",
        "StateHoliday",
        "SchoolHoliday",
        "StoreType",
        "Assortment",
        "Promo2",
        competition_distance,
        year,
        month,
        day,
        week_of_year,
        month_name
    FROM sales
),
lag_features AS (
    SELECT
        "Store",
        "Date",
        "Sales",
        LAG("Sales", 7)   OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_7,
        LAG("Sales", 14)  OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_14,
        LAG("Sales", 28)  OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_28,
        LAG("Sales", 364) OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_364,
        ROUND(AVG("Sales") OVER (
            PARTITION BY "Store" ORDER BY "Date"
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        )) AS rolling_avg_7d,
        ROUND(AVG("Sales") OVER (
            PARTITION BY "Store" ORDER BY "Date"
            ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
        )) AS rolling_avg_28d,
        ROUND(STDDEV("Sales") OVER (
            PARTITION BY "Store" ORDER BY "Date"
            ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
        )) AS rolling_std_28d,
        MAX("Sales") OVER (
            PARTITION BY "Store" ORDER BY "Date"
            ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
        ) AS rolling_max_28d,
        MIN("Sales") OVER (
            PARTITION BY "Store" ORDER BY "Date"
            ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
        ) AS rolling_min_28d
    FROM sales
)
SELECT
    b."Store",
    b."Date",
    b."Sales",

    -- Categorical encodings
    CASE WHEN b."StoreType"  = 'a' THEN 1 ELSE 0 END AS store_type_a,
    CASE WHEN b."StoreType"  = 'b' THEN 1 ELSE 0 END AS store_type_b,
    CASE WHEN b."StoreType"  = 'c' THEN 1 ELSE 0 END AS store_type_c,
    CASE WHEN b."StoreType"  = 'd' THEN 1 ELSE 0 END AS store_type_d,
    CASE WHEN b."Assortment" = 'a' THEN 1 ELSE 0 END AS assortment_a,
    CASE WHEN b."Assortment" = 'b' THEN 1 ELSE 0 END AS assortment_b,
    CASE WHEN b."Assortment" = 'c' THEN 1 ELSE 0 END AS assortment_c,
    CASE WHEN b."StateHoliday" = '0' THEN 0
         WHEN b."StateHoliday" = 'a' THEN 1
         WHEN b."StateHoliday" = 'b' THEN 2
         WHEN b."StateHoliday" = 'c' THEN 3
    END                                               AS state_holiday_encoded,

    -- Binary flags
    b."Promo"         AS is_promo,
    b."SchoolHoliday" AS is_school_holiday,
    b."Promo2"        AS is_promo2,

    -- Competition
    CASE
        WHEN b.competition_distance < 500   THEN 1
        WHEN b.competition_distance < 1000  THEN 2
        WHEN b.competition_distance < 5000  THEN 3
        WHEN b.competition_distance < 10000 THEN 4
        ELSE 5
    END AS competition_bucket,
    b.competition_distance,

    -- Cyclical time features
    ROUND(SIN(2 * PI() * b.month      / 12.0)::NUMERIC, 4) AS month_sin,
    ROUND(COS(2 * PI() * b.month      / 12.0)::NUMERIC, 4) AS month_cos,
    ROUND(SIN(2 * PI() * b."DayOfWeek"/ 7.0 )::NUMERIC, 4) AS dow_sin,
    ROUND(COS(2 * PI() * b."DayOfWeek"/ 7.0 )::NUMERIC, 4) AS dow_cos,
    ROUND(SIN(2 * PI() * b.week_of_year/52.0)::NUMERIC, 4) AS week_sin,
    ROUND(COS(2 * PI() * b.week_of_year/52.0)::NUMERIC, 4) AS week_cos,

    -- Raw time features
    b.year,
    b.month,
    b.day,
    b.week_of_year,
    b."DayOfWeek",
    b.month_name,

    -- Lag features
    l.lag_7,
    l.lag_14,
    l.lag_28,
    l.lag_364,

    -- Rolling features
    l.rolling_avg_7d,
    l.rolling_avg_28d,
    l.rolling_std_28d,
    l.rolling_max_28d,
    l.rolling_min_28d,

    -- Momentum
    ROUND(b."Sales" - l.rolling_avg_28d) AS momentum_28d,

    -- Is weekend flag
    CASE WHEN b."DayOfWeek" IN (6,7) THEN 1 ELSE 0 END AS is_weekend,

    -- Is December flag (Christmas season)
    CASE WHEN b.month = 12 THEN 1 ELSE 0 END AS is_december,

    -- Is start of month
    CASE WHEN b.day <= 7  THEN 1 ELSE 0 END AS is_start_of_month,

    -- Is end of month
    CASE WHEN b.day >= 24 THEN 1 ELSE 0 END AS is_end_of_month

FROM base b
JOIN lag_features l
  ON b."Store" = l."Store"
 AND b."Date"  = l."Date";

-- Verify
SELECT
    COUNT(*)                      AS total_rows,
    COUNT(DISTINCT "Store")       AS num_stores,
    COUNT(*)  FILTER (WHERE lag_7  IS NOT NULL) AS rows_with_lag7,
    COUNT(*)  FILTER (WHERE lag_14 IS NOT NULL) AS rows_with_lag14,
    COUNT(DISTINCT year || '-' || month)        AS num_months
FROM v_features;