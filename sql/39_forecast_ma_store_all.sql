-- Scale the best model (DOW_AVG) to ALL 1,115 stores
-- Train on 2013-2014, forecast Jan-Jul 2015
CREATE OR REPLACE VIEW v_ma_forecast_all_stores AS
WITH combined AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        "DayOfWeek",
        CASE WHEN "Date" < '2015-01-01'
             THEN 'train' ELSE 'test'
        END                             AS split
    FROM v_forecast_ready
),
dow_avg AS (
    SELECT
        "Store",
        "DayOfWeek",
        AVG(actual_sales)               AS dow_mean,
        STDDEV(actual_sales)            AS dow_std
    FROM combined
    WHERE split = 'train'
    GROUP BY "Store", "DayOfWeek"
),
forecast AS (
    SELECT
        c."Store",
        c."Date",
        c.actual_sales,
        c.split,
        c."DayOfWeek",
        ROUND(d.dow_mean)               AS forecast,
        ROUND(d.dow_std)                AS forecast_std,

        -- Confidence intervals
        ROUND(d.dow_mean
            - 1.96 * d.dow_std)         AS lower_95,
        ROUND(d.dow_mean
            + 1.96 * d.dow_std)         AS upper_95,

        -- Error
        c.actual_sales
            - ROUND(d.dow_mean)         AS error,

        -- Within interval flag
        CASE WHEN c.actual_sales BETWEEN
            ROUND(d.dow_mean - 1.96 * d.dow_std)
            AND
            ROUND(d.dow_mean + 1.96 * d.dow_std)
            THEN 1 ELSE 0
        END                             AS within_95
    FROM combined c
    JOIN dow_avg d
      ON c."Store"    = d."Store"
     AND c."DayOfWeek"= d."DayOfWeek"
)
SELECT
    *,
    -- MAPE per row
    ROUND(ABS(error::NUMERIC /
        NULLIF(actual_sales, 0))
        * 100, 2)                       AS abs_pct_error
FROM forecast
ORDER BY "Store", "Date";

-- Evaluate across ALL stores on test set
SELECT
    split,
    COUNT(*)                            AS total_rows,
    COUNT(DISTINCT "Store")             AS num_stores,
    ROUND(SQRT(AVG(
        POWER(error, 2)))::NUMERIC)     AS rmse,
    ROUND(AVG(
        ABS(error))::NUMERIC)           AS mae,
    ROUND(AVG(abs_pct_error)::NUMERIC,
        2)                              AS mape,
    ROUND(AVG(error)::NUMERIC)          AS mean_bias,
    ROUND(100.0 * SUM(within_95)
        / COUNT(*), 1)                  AS coverage_95_pct
FROM v_ma_forecast_all_stores
GROUP BY split
ORDER BY split DESC;