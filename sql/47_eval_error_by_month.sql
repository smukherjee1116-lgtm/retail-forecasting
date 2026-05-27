WITH ts_test AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        ts_forecast_clipped         AS forecast,
        error,
        abs_pct_error,
        month,
        TO_CHAR("Date", 'Mon')      AS month_name,
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
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        TO_CHAR("Date", 'Mon')              AS month_name,
        "DayOfWeek"
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
)
SELECT
    t.month,
    t.month_name,
    ROUND(AVG(t.error)::NUMERIC)        AS ts_mean_error,
    ROUND(AVG(t.abs_pct_error)
        ::NUMERIC, 2)                   AS ts_mape,
    ROUND(AVG(m.error)::NUMERIC)        AS ma_mean_error,
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
GROUP BY t.month, t.month_name
ORDER BY t.month;