-- Identify which stores benefit most from Trend+Seasonal
-- and which are better served by DOW_AVG
-- This drives the ensemble blending weights on Day 10
WITH ts_store AS (
    SELECT
        "Store",
        ROUND(SQRT(AVG(
            POWER(error,2)))::NUMERIC)      AS ts_rmse,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)                    AS ts_mape
    FROM v_trend_seasonal_forecast
    WHERE split = 'test'
    GROUP BY "Store"
),
ma_store AS (
    SELECT
        "Store",
        ROUND(SQRT(AVG(
            POWER(error,2)))::NUMERIC)      AS ma_rmse,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)                    AS ma_mape
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
    GROUP BY "Store"
),
ranked AS (
    SELECT
        t."Store",
        t.ts_rmse,
        t.ts_mape,
        m.ma_rmse,
        m.ma_mape,
        -- Relative improvement of TS over MA
        ROUND(((m.ma_rmse - t.ts_rmse)::NUMERIC
            / NULLIF(m.ma_rmse,0))*100,1)   AS ts_improvement_pct,
        -- Best model label
        CASE WHEN t.ts_rmse < m.ma_rmse
             THEN 'Trend+Seasonal'
             ELSE 'DOW_AVG'
        END                                 AS best_model,
        -- Optimal blend weight for TS model
        -- Higher improvement = higher TS weight
        ROUND(GREATEST(0, LEAST(1,
            0.5 + ((m.ma_rmse - t.ts_rmse)::NUMERIC
            / NULLIF(m.ma_rmse + t.ts_rmse, 0))
        ))::NUMERIC, 3)                     AS ts_blend_weight
    FROM ts_store t
    JOIN ma_store m ON t."Store" = m."Store"
)
SELECT
    *,
    ROUND(1 - ts_blend_weight, 3)           AS ma_blend_weight
FROM ranked
ORDER BY ts_improvement_pct DESC;