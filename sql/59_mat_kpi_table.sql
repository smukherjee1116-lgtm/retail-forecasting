-- Materialise KPI summary table for dashboard home page
DROP TABLE IF EXISTS t_kpi_summary;
CREATE TABLE t_kpi_summary AS
WITH overall AS (
    SELECT
        COUNT(DISTINCT "Store")         AS total_stores,
        MIN("Date")                     AS data_start,
        MAX("Date")                     AS data_end,
        SUM(actual_sales)               AS total_revenue,
        ROUND(AVG(actual_sales))        AS avg_daily_sales,
        MAX(actual_sales)               AS max_daily_sales
    FROM t_final_forecast
),
forecast_quality AS (
    SELECT
        ROUND(AVG(ape)::NUMERIC, 2)     AS overall_mape,
        ROUND(SQRT(AVG(POWER(
            ensemble_error,2)))::NUMERIC) AS overall_rmse,
        ROUND(AVG(ABS(
            ensemble_error))::NUMERIC)  AS overall_mae,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE ape < 10)
            / COUNT(*), 1)              AS pct_excellent,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE ape < 20)
            / COUNT(*), 1)              AS pct_good_or_better
    FROM t_final_forecast
    WHERE split = 'test'
),
inventory_summary AS (
    SELECT
        COUNT(*) FILTER (
            WHERE alert_level LIKE 'WARNING%'
            OR alert_level LIKE 'CRITICAL%'
        )                               AS stores_needing_reorder,
        COUNT(*) FILTER (
            WHERE alert_level LIKE 'WATCH%'
        )                               AS stores_demand_surging,
        ROUND(AVG(days_of_stock)
            ::NUMERIC, 1)               AS avg_days_of_stock,
        ROUND(AVG(safety_stock))        AS avg_safety_stock
    FROM t_store_summary
),
model_perf AS (
    SELECT
        rmse                            AS ensemble_rmse,
        mape                            AS ensemble_mape,
        mean_bias                       AS ensemble_bias
    FROM v_model_scorecard
    WHERE model = 'Ensemble (weighted)'
)
SELECT
    -- Dataset KPIs
    o.total_stores,
    o.data_start,
    o.data_end,
    o.total_revenue,
    o.avg_daily_sales,
    o.max_daily_sales,

    -- Model KPIs
    m.ensemble_rmse,
    m.ensemble_mape,
    m.ensemble_bias,
    f.overall_mape              AS test_mape,
    f.pct_excellent             AS pct_forecasts_excellent,
    f.pct_good_or_better        AS pct_forecasts_good,

    -- Inventory KPIs
    i.stores_needing_reorder,
    i.stores_demand_surging,
    i.avg_days_of_stock,
    i.avg_safety_stock,

    -- Metadata
    NOW()                       AS last_updated,
    '3 models: DOW_AVG + Trend+Seasonal + Ensemble'
                                AS models_used,
    'Rossmann Store Sales'      AS dataset_name,
    'Jan 2013 - Jul 2015'       AS data_period

FROM overall o
CROSS JOIN forecast_quality f
CROSS JOIN inventory_summary i
CROSS JOIN model_perf m;

-- Display KPIs
SELECT * FROM t_kpi_summary;