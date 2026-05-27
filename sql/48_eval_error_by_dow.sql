-- Error breakdown by day of week
WITH ts_test AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        ts_forecast_clipped         AS forecast,
        error,
        abs_pct_error,
        "DayOfWeek"
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
        abs_pct_error,
        "DayOfWeek"
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
)
SELECT
    t."DayOfWeek",
    CASE t."DayOfWeek"
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END                                 AS day_name,
    COUNT(DISTINCT t."Store")           AS num_stores,
    ROUND(AVG(t.error)::NUMERIC)        AS ts_mean_error,
    ROUND(SQRT(AVG(POWER(t.error,2)))
        ::NUMERIC)                      AS ts_rmse,
    ROUND(AVG(t.abs_pct_error)
        ::NUMERIC, 2)                   AS ts_mape,
    ROUND(AVG(m.error)::NUMERIC)        AS ma_mean_error,
    ROUND(SQRT(AVG(POWER(m.error,2)))
        ::NUMERIC)                      AS ma_rmse,
    ROUND(AVG(m.abs_pct_error)
        ::NUMERIC, 2)                   AS ma_mape,
    CASE WHEN AVG(ABS(t.error))
              < AVG(ABS(m.error))
         THEN 'Trend+Seasonal'
         ELSE 'DOW_AVG'
    END                                 AS winning_model
FROM ts_test t
JOIN ma_test m
  ON t."Store" = m."Store"
 AND t."Date"  = m."Date"
GROUP BY t."DayOfWeek"
ORDER BY t."DayOfWeek";