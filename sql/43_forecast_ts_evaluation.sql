-- Evaluate trend+seasonal model vs MA baseline
-- Compare on test set across all stores
WITH ts_metrics AS (
    SELECT
        split,
        COUNT(*)                            AS total_rows,
        COUNT(DISTINCT "Store")             AS num_stores,
        ROUND(SQRT(AVG(
            POWER(error, 2)))::NUMERIC)     AS rmse,
        ROUND(AVG(
            ABS(error))::NUMERIC)           AS mae,
        ROUND(AVG(
            abs_pct_error)::NUMERIC, 2)     AS mape,
        ROUND(AVG(error)::NUMERIC)          AS mean_bias,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE actual_sales
                BETWEEN lower_95 AND upper_95)
            / COUNT(*), 1)                  AS coverage_95_pct
    FROM v_trend_seasonal_forecast
    GROUP BY split
),
ma_metrics AS (
    SELECT
        split,
        COUNT(*)                            AS total_rows,
        COUNT(DISTINCT "Store")             AS num_stores,
        ROUND(SQRT(AVG(
            POWER(error, 2)))::NUMERIC)     AS rmse,
        ROUND(AVG(
            ABS(error))::NUMERIC)           AS mae,
        ROUND(AVG(
            abs_pct_error)::NUMERIC, 2)     AS mape,
        ROUND(AVG(error)::NUMERIC)          AS mean_bias,
        ROUND(100.0 * SUM(within_95)
            / COUNT(*), 1)                  AS coverage_95_pct
    FROM v_ma_forecast_all_stores
    GROUP BY split
)
SELECT
    'Trend+Seasonal' AS model,
    split,
    total_rows,
    rmse,
    mae,
    mape,
    mean_bias,
    coverage_95_pct
FROM ts_metrics
UNION ALL
SELECT
    'DOW_AVG (baseline)',
    split,
    total_rows,
    rmse,
    mae,
    mape,
    mean_bias,
    coverage_95_pct
FROM ma_metrics
ORDER BY split DESC, rmse;