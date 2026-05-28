-- Materialise monthly aggregated forecast
-- Dashboard charts will use this instead of daily data
DROP TABLE IF EXISTS t_monthly_forecast;
CREATE TABLE t_monthly_forecast AS
SELECT
    "Store",
    EXTRACT(YEAR  FROM "Date")::INTEGER AS year,
    EXTRACT(MONTH FROM "Date")::INTEGER AS month,
    TO_CHAR("Date", 'Mon')              AS month_name,
    split,
    COUNT(*)                            AS trading_days,
    SUM(actual_sales)                   AS actual_monthly_sales,
    SUM(ensemble_forecast)              AS forecast_monthly_sales,
    ROUND(AVG(actual_sales))            AS avg_daily_actual,
    ROUND(AVG(ensemble_forecast))       AS avg_daily_forecast,
    -- Monthly error metrics
    SUM(actual_sales)
        - SUM(ensemble_forecast)        AS monthly_error,
    ROUND(ABS(
        SUM(actual_sales)
        - SUM(ensemble_forecast)
    )::NUMERIC / NULLIF(
        SUM(actual_sales), 0
    ) * 100, 2)                         AS monthly_ape,
    -- Confidence intervals (monthly)
    SUM(upper_95)                       AS upper_95_monthly,
    SUM(lower_95)                       AS lower_95_monthly,
    -- Forecast quality
    COUNT(*) FILTER (WHERE ape < 10)    AS excellent_days,
    COUNT(*) FILTER (WHERE ape > 30)    AS poor_days
FROM t_final_forecast
GROUP BY
    "Store",
    EXTRACT(YEAR  FROM "Date"),
    EXTRACT(MONTH FROM "Date"),
    TO_CHAR("Date", 'Mon'),
    split
ORDER BY "Store", year, month;

-- Add index
CREATE INDEX idx_tmf_store ON t_monthly_forecast("Store");
CREATE INDEX idx_tmf_year  ON t_monthly_forecast(year, month);

-- Overall monthly trend (all stores combined)
SELECT
    year,
    month,
    month_name,
    split,
    SUM(actual_monthly_sales)       AS total_actual,
    SUM(forecast_monthly_sales)     AS total_forecast,
    ROUND(AVG(monthly_ape)
        ::NUMERIC,2)                AS avg_store_mape,
    COUNT(DISTINCT "Store")         AS num_stores
FROM t_monthly_forecast
GROUP BY year, month, month_name, split
ORDER BY year, month;