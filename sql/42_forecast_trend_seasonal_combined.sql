-- Combine trend + seasonal indices into final forecast
-- Forecast = trend + dow_seasonal_index + month_seasonal_index
CREATE OR REPLACE VIEW v_trend_seasonal_forecast AS
WITH forecast_combined AS (
    SELECT
        t."Store",
        t."Date",
        t.actual_sales,
        t.split,
        t."DayOfWeek",
        t.month,
        t.trend_forecast,
        t.detrended_sales,
        s.dow_seasonal_index,
        s.month_seasonal_index,

        -- Combined forecast
        ROUND((
            t.trend_forecast
            + s.dow_seasonal_index
            + s.month_seasonal_index
        )::NUMERIC)                     AS ts_forecast,

        -- Ensure forecast is never negative
        GREATEST(ROUND((
            t.trend_forecast
            + s.dow_seasonal_index
            + s.month_seasonal_index
        )::NUMERIC), 0)                 AS ts_forecast_clipped

    FROM v_trend_model t
    JOIN v_seasonal_indices s
      ON t."Store"      = s."Store"
     AND t."DayOfWeek"  = s."DayOfWeek"
     AND t.month        = s.month
)
SELECT
    *,
    -- Forecast error
    actual_sales - ts_forecast_clipped  AS error,

    -- Absolute percentage error
    ROUND(ABS((actual_sales
        - ts_forecast_clipped)::NUMERIC
        / NULLIF(actual_sales, 0))
        * 100, 2)                       AS abs_pct_error,

    -- Confidence interval using residual std from training
    -- (computed inline per store)
    ROUND((ts_forecast_clipped
        + 1.96 * STDDEV(
            actual_sales - ts_forecast_clipped
          ) OVER (
            PARTITION BY "Store"
          ))::NUMERIC)                  AS upper_95,
    ROUND((ts_forecast_clipped
        - 1.96 * STDDEV(
            actual_sales - ts_forecast_clipped
          ) OVER (
            PARTITION BY "Store"
          ))::NUMERIC)                  AS lower_95

FROM forecast_combined
ORDER BY "Store", "Date";

-- Preview Store 1 test forecasts
SELECT
    "Date",
    actual_sales,
    trend_forecast,
    dow_seasonal_index,
    month_seasonal_index,
    ts_forecast_clipped     AS forecast,
    error,
    abs_pct_error,
    lower_95,
    upper_95
FROM v_trend_seasonal_forecast
WHERE "Store" = 1
  AND split   = 'test'
ORDER BY "Date"
LIMIT 15;