-- Final model scorecard for the dashboard
-- One-row summary of each model for display
CREATE OR REPLACE VIEW v_model_scorecard AS
WITH ensemble_stats AS (
    SELECT
        'Ensemble (weighted)'           AS model,
        ROUND(SQRT(AVG(POWER(
            ensemble_error,2)))::NUMERIC) AS rmse,
        ROUND(AVG(ABS(ensemble_error))
            ::NUMERIC)                  AS mae,
        ROUND(AVG(ABS(
            ensemble_error::NUMERIC /
            NULLIF(actual_sales,0)))
            *100,2)                     AS mape,
        ROUND(AVG(ensemble_error)
            ::NUMERIC)                  AS mean_bias,
        ROUND(100.0 * SUM(within_95)
            / COUNT(*),1)               AS coverage_95
    FROM v_final_forecast
    WHERE split = 'test'
),
ts_stats AS (
    SELECT
        'Trend+Seasonal'                AS model,
        ROUND(SQRT(AVG(POWER(
            error,2)))::NUMERIC)        AS rmse,
        ROUND(AVG(ABS(error))
            ::NUMERIC)                  AS mae,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)                AS mape,
        ROUND(AVG(error)::NUMERIC)      AS mean_bias,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE actual_sales
                BETWEEN lower_95 AND upper_95)
            / COUNT(*),1)               AS coverage_95
    FROM v_trend_seasonal_forecast
    WHERE split = 'test'
),
ma_stats AS (
    SELECT
        'DOW_AVG (baseline)'            AS model,
        ROUND(SQRT(AVG(POWER(
            error,2)))::NUMERIC)        AS rmse,
        ROUND(AVG(ABS(error))
            ::NUMERIC)                  AS mae,
        ROUND(AVG(abs_pct_error)
            ::NUMERIC,2)                AS mape,
        ROUND(AVG(error)::NUMERIC)      AS mean_bias,
        ROUND(100.0 * SUM(within_95)
            / COUNT(*),1)               AS coverage_95
    FROM v_ma_forecast_all_stores
    WHERE split = 'test'
)
SELECT
    model,
    rmse,
    mae,
    mape,
    mean_bias,
    coverage_95,
    -- Rank models
    RANK() OVER (ORDER BY rmse)         AS rmse_rank,
    RANK() OVER (ORDER BY mape)         AS mape_rank,
    -- Overall score (lower is better)
    RANK() OVER (ORDER BY rmse)
    + RANK() OVER (ORDER BY mape)       AS overall_rank
FROM (
    SELECT * FROM ensemble_stats
    UNION ALL
    SELECT * FROM ts_stats
    UNION ALL
    SELECT * FROM ma_stats
) combined
ORDER BY overall_rank;

-- Display the scorecard
SELECT * FROM v_model_scorecard;