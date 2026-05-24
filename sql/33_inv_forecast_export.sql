-- Forecast-ready export table
-- This is the exact table Prophet and XGBoost will read
-- Covers all 1,115 stores with clean features
CREATE OR REPLACE VIEW v_forecast_ready AS
WITH ranked AS (
    SELECT
        f.*,
        -- Store-level percentile for normalisation
        ROUND((PERCENT_RANK() OVER (
            PARTITION BY f."Date"
            ORDER BY f."Sales"
        ) * 100)::NUMERIC, 1)           AS store_daily_percentile,

        -- Previous year same date sales
        LAG(f."Sales", 364) OVER (
            PARTITION BY f."Store"
            ORDER BY f."Date"
        )                               AS same_day_last_year,

        -- Flag: is this a high sales day?
        CASE WHEN f."Sales" > f.rolling_avg_28d * 1.2
             THEN 1 ELSE 0
        END                             AS is_high_sales_day,

        -- Flag: is this a low sales day?
        CASE WHEN f."Sales" < f.rolling_avg_28d * 0.8
             THEN 1 ELSE 0
        END                             AS is_low_sales_day

    FROM v_features f
    WHERE f.lag_7  IS NOT NULL
      AND f.lag_14 IS NOT NULL
)
SELECT
    -- Identity
    "Store",
    "Date",
    "Sales"                             AS actual_sales,

    -- Time features
    year,
    month,
    day,
    week_of_year,
    "DayOfWeek",
    month_sin,
    month_cos,
    dow_sin,
    dow_cos,
    week_sin,
    week_cos,
    is_weekend,
    is_december,
    is_start_of_month,
    is_end_of_month,

    -- Store features
    store_type_a,
    store_type_b,
    store_type_c,
    store_type_d,
    assortment_a,
    assortment_b,
    assortment_c,
    competition_distance,
    competition_bucket,

    -- Event features
    is_promo,
    is_promo2,
    is_school_holiday,
    state_holiday_encoded,

    -- Lag features
    lag_7,
    lag_14,
    lag_28,
    rolling_avg_7d,
    rolling_avg_28d,
    rolling_std_28d,
    rolling_max_28d,
    rolling_min_28d,
    momentum_28d,

    -- Derived flags
    store_daily_percentile,
    same_day_last_year,
    is_high_sales_day,
    is_low_sales_day,

    -- Target variable (log-transformed for modelling)
    ROUND(LN("Sales"::NUMERIC), 6)      AS log_sales

FROM ranked
ORDER BY "Store", "Date";

-- Final verification
SELECT
    COUNT(*)                            AS total_rows,
    COUNT(DISTINCT "Store")             AS num_stores,
    MIN("Date")                         AS date_from,
    MAX("Date")                         AS date_to,
    COUNT(*) FILTER
        (WHERE log_sales IS NULL)       AS null_log_sales,
    COUNT(*) FILTER
        (WHERE is_high_sales_day = 1)   AS high_sales_days,
    COUNT(*) FILTER
        (WHERE is_low_sales_day  = 1)   AS low_sales_days,
    ROUND(AVG(actual_sales))            AS overall_avg_sales
FROM v_forecast_ready;