-- Comprehensive evaluation metrics for both models
-- Including error distribution analysis
WITH ts_test AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        ts_forecast_clipped        AS forecast,
        error,
        abs_pct_error
    FROM v_trend_seasonal_forecast
    WHERE split = 'test'
),
ma_test AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        forecast,
        error,
        abs_pct_error
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
),
ts_metrics AS (
    SELECT
        'Trend+Seasonal'            AS model,
        COUNT(*)                    AS n,
        -- Central tendency of errors
        ROUND(AVG(error)::NUMERIC)  AS mean_error,
        ROUND(PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS median_error,
        -- Spread of errors
        ROUND(STDDEV(error)::NUMERIC) AS error_std,
        ROUND(PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS error_q1,
        ROUND(PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS error_q3,
        -- Standard metrics
        ROUND(SQRT(AVG(
            POWER(error,2)))::NUMERIC)  AS rmse,
        ROUND(AVG(ABS(error))::NUMERIC) AS mae,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)            AS mape,
        -- Directional accuracy
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE error > 0)
            / COUNT(*), 1)          AS over_forecast_pct,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE error < 0)
            / COUNT(*), 1)          AS under_forecast_pct,
        -- Extreme error analysis
        ROUND(PERCENTILE_CONT(0.95)
            WITHIN GROUP (ORDER BY ABS(error))
            ::NUMERIC)              AS p95_abs_error,
        ROUND(PERCENTILE_CONT(0.99)
            WITHIN GROUP (ORDER BY ABS(error))
            ::NUMERIC)              AS p99_abs_error,
        MAX(ABS(error))             AS max_abs_error
    FROM ts_test
),
ma_metrics AS (
    SELECT
        'DOW_AVG'                   AS model,
        COUNT(*)                    AS n,
        ROUND(AVG(error)::NUMERIC)  AS mean_error,
        ROUND(PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS median_error,
        ROUND(STDDEV(error)::NUMERIC) AS error_std,
        ROUND(PERCENTILE_CONT(0.25)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS error_q1,
        ROUND(PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY error)
            ::NUMERIC)              AS error_q3,
        ROUND(SQRT(AVG(
            POWER(error,2)))::NUMERIC)  AS rmse,
        ROUND(AVG(ABS(error))::NUMERIC) AS mae,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)            AS mape,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE error > 0)
            / COUNT(*), 1)          AS over_forecast_pct,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE error < 0)
            / COUNT(*), 1)          AS under_forecast_pct,
        ROUND(PERCENTILE_CONT(0.95)
            WITHIN GROUP (ORDER BY ABS(error))
            ::NUMERIC)              AS p95_abs_error,
        ROUND(PERCENTILE_CONT(0.99)
            WITHIN GROUP (ORDER BY ABS(error))
            ::NUMERIC)              AS p99_abs_error,
        MAX(ABS(error))             AS max_abs_error
    FROM ma_test
)
SELECT * FROM ts_metrics
UNION ALL
SELECT * FROM ma_metrics
ORDER BY rmse;