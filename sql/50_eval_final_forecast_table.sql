-- Create the final permanent forecast table
-- This is what the Streamlit dashboard reads
CREATE OR REPLACE VIEW v_final_forecast AS
SELECT
    "Store",
    "Date",
    actual_sales,
    split,
    ts_forecast,
    ma_forecast,
    ensemble_forecast,
    ts_blend_weight,
    ma_blend_weight,

    -- Errors
    ensemble_error,
    ABS(ensemble_error)                 AS abs_ensemble_error,
    ROUND(ABS(ensemble_error::NUMERIC /
        NULLIF(actual_sales, 0))
        * 100, 2)                       AS ensemble_ape,

    -- Confidence intervals (based on ensemble error std)
    ROUND((ensemble_forecast + 1.96 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS upper_95,
    ROUND((ensemble_forecast - 1.96 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS lower_95,
    ROUND((ensemble_forecast + 1.28 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS upper_80,
    ROUND((ensemble_forecast - 1.28 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS lower_80,

    -- Within interval flags
    CASE WHEN actual_sales BETWEEN
        ROUND((ensemble_forecast - 1.96 *
            STDDEV(ensemble_error) OVER (
                PARTITION BY "Store"
            ))::NUMERIC)
        AND
        ROUND((ensemble_forecast + 1.96 *
            STDDEV(ensemble_error) OVER (
                PARTITION BY "Store"
            ))::NUMERIC)
        THEN 1 ELSE 0
    END                                 AS within_95,

    -- Performance label
    CASE
        WHEN ABS(ensemble_error::NUMERIC /
            NULLIF(actual_sales,0)) < 0.10
             THEN 'Excellent (<10%)'
        WHEN ABS(ensemble_error::NUMERIC /
            NULLIF(actual_sales,0)) < 0.20
             THEN 'Good (10-20%)'
        WHEN ABS(ensemble_error::NUMERIC /
            NULLIF(actual_sales,0)) < 0.30
             THEN 'Fair (20-30%)'
        ELSE      'Poor (>30%)'
    END                                 AS forecast_quality

FROM v_ensemble_forecast
ORDER BY "Store", "Date";

-- Final summary stats
SELECT
    split,
    COUNT(*)                            AS total_rows,
    COUNT(DISTINCT "Store")             AS num_stores,
    ROUND(SQRT(AVG(POWER(
        ensemble_error,2)))::NUMERIC)   AS ensemble_rmse,
    ROUND(AVG(ABS(ensemble_error))
        ::NUMERIC)                      AS ensemble_mae,
    ROUND(AVG(ensemble_ape)
        ::NUMERIC,2)                    AS ensemble_mape,
    ROUND(AVG(ensemble_error)
        ::NUMERIC)                      AS mean_bias,
    ROUND(100.0 * SUM(within_95)
        / COUNT(*),1)                   AS coverage_95_pct,
    -- Forecast quality distribution
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE forecast_quality
            = 'Excellent (<10%)')
        / COUNT(*), 1)                  AS excellent_pct,
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE forecast_quality
            = 'Good (10-20%)')
        / COUNT(*), 1)                  AS good_pct,
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE forecast_quality
            = 'Fair (20-30%)')
        / COUNT(*), 1)                  AS fair_pct,
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE forecast_quality
            = 'Poor (>30%)')
        / COUNT(*), 1)                  AS poor_pct
FROM v_final_forecast
GROUP BY split
ORDER BY split DESC;