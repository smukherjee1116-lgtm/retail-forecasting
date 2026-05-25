-- Add confidence intervals to the best model (DOW_AVG)
-- Intervals based on historical prediction error distribution
CREATE OR REPLACE VIEW v_ma_forecast_final AS
WITH test_errors AS (
    SELECT
        STDDEV(error_dow)               AS error_std,
        AVG(error_dow)                  AS error_mean
    FROM v_ma_forecast
    WHERE split = 'train'
      AND error_dow IS NOT NULL
),
forecast AS (
    SELECT
        f."Date",
        f.actual_sales,
        f.split,
        f.dow_avg                       AS forecast,
        f.error_dow                     AS forecast_error,
        e.error_std,
        e.error_mean
    FROM v_ma_forecast f
    CROSS JOIN test_errors e
    WHERE f.dow_avg IS NOT NULL
)
SELECT
    "Date",
    actual_sales,
    split,
    ROUND(forecast)                     AS forecast,
    forecast_error,

    -- 80% confidence interval (Z = 1.28)
    ROUND(forecast + error_mean
        - 1.28 * error_std)             AS lower_80,
    ROUND(forecast + error_mean
        + 1.28 * error_std)             AS upper_80,

    -- 95% confidence interval (Z = 1.96)
    ROUND(forecast + error_mean
        - 1.96 * error_std)             AS lower_95,
    ROUND(forecast + error_mean
        + 1.96 * error_std)             AS upper_95,

    -- Is actual within interval?
    CASE WHEN actual_sales BETWEEN
        ROUND(forecast + error_mean - 1.96 * error_std)
        AND
        ROUND(forecast + error_mean + 1.96 * error_std)
        THEN 1 ELSE 0
    END                                 AS within_95,

    CASE WHEN actual_sales BETWEEN
        ROUND(forecast + error_mean - 1.28 * error_std)
        AND
        ROUND(forecast + error_mean + 1.28 * error_std)
        THEN 1 ELSE 0
    END                                 AS within_80

FROM forecast
ORDER BY "Date";

-- Coverage check
SELECT
    split,
    COUNT(*)                            AS total_rows,
    SUM(within_95)                      AS within_95_count,
    ROUND(100.0 * SUM(within_95)
        / COUNT(*), 1)                  AS coverage_95_pct,
    SUM(within_80)                      AS within_80_count,
    ROUND(100.0 * SUM(within_80)
        / COUNT(*), 1)                  AS coverage_80_pct
FROM v_ma_forecast_final
GROUP BY split
ORDER BY split DESC;