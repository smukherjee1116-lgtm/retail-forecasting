-- Build ensemble forecast using store-level blend weights
-- Ensemble = ts_weight * ts_forecast + ma_weight * ma_forecast
CREATE OR REPLACE VIEW v_ensemble_forecast AS
WITH blend_weights AS (
    SELECT
        "Store",
        ts_blend_weight,
        ma_blend_weight
    FROM v_ts_store_ranking
    -- Note: v_ts_store_ranking was built in Day 8
    -- query 45_forecast_ts_store_ranking
),
forecasts AS (
    SELECT
        t."Store",
        t."Date",
        t.actual_sales,
        t.split,
        t.ts_forecast_clipped       AS ts_forecast,
        m.forecast                  AS ma_forecast,
        b.ts_blend_weight,
        b.ma_blend_weight
    FROM v_trend_seasonal_forecast t
    JOIN v_ma_forecast_all_stores m
      ON t."Store" = m."Store"
     AND t."Date"  = m."Date"
    JOIN blend_weights b
      ON t."Store" = b."Store"
)
SELECT
    "Store",
    "Date",
    actual_sales,
    split,
    ts_forecast,
    ma_forecast,
    ts_blend_weight,
    ma_blend_weight,

    -- Weighted ensemble forecast
    ROUND((
        ts_blend_weight * ts_forecast
        + ma_blend_weight * ma_forecast
    )::NUMERIC)                         AS ensemble_forecast,

    -- Simple average ensemble (equal weights)
    ROUND((
        ts_forecast + ma_forecast
    ) / 2.0)                            AS simple_avg_forecast,

    -- Ensemble error
    actual_sales - ROUND((
        ts_blend_weight * ts_forecast
        + ma_blend_weight * ma_forecast
    )::NUMERIC)                         AS ensemble_error,

    -- Simple average error
    actual_sales - ROUND((
        ts_forecast + ma_forecast
    ) / 2.0)                            AS simple_avg_error

FROM forecasts
ORDER BY "Store", "Date";

-- Evaluate all 4 models on test set
WITH eval AS (
    SELECT
        actual_sales,
        split,
        ts_forecast,
        ma_forecast,
        ensemble_forecast,
        simple_avg_forecast,
        ensemble_error,
        simple_avg_error,
        actual_sales - ts_forecast  AS ts_error,
        actual_sales - ma_forecast  AS ma_error
    FROM v_ensemble_forecast
    WHERE split = 'test'
)
SELECT
    model,
    ROUND(SQRT(AVG(POWER(error,2)))
        ::NUMERIC)                  AS rmse,
    ROUND(AVG(ABS(error))
        ::NUMERIC)                  AS mae,
    ROUND(AVG(ABS(error::NUMERIC /
        NULLIF(actual_sales,0)))
        * 100, 2)                   AS mape,
    ROUND(AVG(error)::NUMERIC)      AS mean_bias
FROM (
    SELECT 'Trend+Seasonal' AS model,
           ts_error AS error, actual_sales FROM eval
    UNION ALL
    SELECT 'DOW_AVG',
           ma_error, actual_sales FROM eval
    UNION ALL
    SELECT 'Ensemble (weighted)',
           ensemble_error, actual_sales FROM eval
    UNION ALL
    SELECT 'Ensemble (simple avg)',
           simple_avg_error, actual_sales FROM eval
) t
GROUP BY model
ORDER BY rmse;