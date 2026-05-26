-- Which model wins per store?
-- Store-level MAPE comparison
WITH ts_store AS (
    SELECT
        "Store",
        ROUND(SQRT(AVG(
            POWER(error,2)))::NUMERIC)      AS ts_rmse,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC, 2)                   AS ts_mape,
        ROUND(AVG(error)::NUMERIC)          AS ts_bias
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
            ::NUMERIC, 2)                   AS ma_mape,
        ROUND(AVG(error)::NUMERIC)          AS ma_bias
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
    GROUP BY "Store"
),
comparison AS (
    SELECT
        t."Store",
        t.ts_rmse,
        t.ts_mape,
        t.ts_bias,
        m.ma_rmse,
        m.ma_mape,
        m.ma_bias,
        -- Which model wins on RMSE?
        CASE WHEN t.ts_rmse < m.ma_rmse
             THEN 'Trend+Seasonal'
             ELSE 'DOW_AVG'
        END                                 AS rmse_winner,
        -- RMSE improvement
        m.ma_rmse - t.ts_rmse               AS rmse_improvement,
        -- MAPE improvement
        ROUND((m.ma_mape
            - t.ts_mape)::NUMERIC, 2)       AS mape_improvement
    FROM ts_store t
    JOIN ma_store m ON t."Store" = m."Store"
)
SELECT
    rmse_winner,
    COUNT(*)                                AS num_stores,
    ROUND(AVG(ts_rmse))                     AS avg_ts_rmse,
    ROUND(AVG(ma_rmse))                     AS avg_ma_rmse,
    ROUND(AVG(ts_mape)::NUMERIC, 2)         AS avg_ts_mape,
    ROUND(AVG(ma_mape)::NUMERIC, 2)         AS avg_ma_mape,
    ROUND(AVG(rmse_improvement))            AS avg_rmse_improvement
FROM comparison
GROUP BY rmse_winner
ORDER BY num_stores DESC;