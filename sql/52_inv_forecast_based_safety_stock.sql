-- Forward-looking inventory metrics using ensemble forecast
-- Better than historical averages because it uses predicted demand
CREATE OR REPLACE VIEW v_forecast_inventory AS
WITH store_forecast_stats AS (
    SELECT
        "Store",
        -- Use ALL data (train+test) for robust statistics
        ROUND(AVG(ensemble_forecast)::NUMERIC)   AS avg_forecast,
        ROUND(STDDEV(ensemble_forecast)::NUMERIC) AS forecast_std,
        ROUND(AVG(actual_sales)::NUMERIC)        AS avg_actual,
        ROUND(STDDEV(actual_sales)::NUMERIC)     AS actual_std,
        ROUND(AVG(ensemble_ape)::NUMERIC, 2)     AS avg_forecast_error_pct,
        COUNT(*)                                 AS total_days,
        -- Forecast accuracy tier
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE ensemble_ape < 10)
            / COUNT(*), 1)                       AS pct_excellent,
        ROUND(100.0 * COUNT(*)
            FILTER (WHERE ensemble_ape > 30)
            / COUNT(*), 1)                       AS pct_poor
    FROM v_final_forecast
    GROUP BY "Store"
),
inventory_calcs AS (
    SELECT
        s.*,
        st."StoreType",
        st."Assortment",
        st.competition_distance,

        -- Lead time demand (3 days)
        ROUND((avg_forecast * 3)::NUMERIC)       AS lead_time_demand,

        -- Safety stock using forecast uncertainty
        -- Higher forecast error = more safety stock needed
        -- Z=1.65 for 95% service level
        ROUND((1.65 * forecast_std
            * SQRT(3))::NUMERIC)                 AS safety_stock_base,

        -- Adjusted safety stock accounting for forecast error
        ROUND((1.65 * (forecast_std
            + avg_forecast * avg_forecast_error_pct / 100)
            * SQRT(3))::NUMERIC)                 AS safety_stock_adjusted,

        -- Reorder point
        ROUND(((avg_forecast * 3)
            + (1.65 * forecast_std
            * SQRT(3)))::NUMERIC)                AS reorder_point,

        -- Max stock level (covers 14 days at peak demand)
        ROUND((avg_forecast * 14
            + 1.65 * forecast_std
            * SQRT(3))::NUMERIC)                 AS max_stock_level,

        -- Min stock level (safety stock)
        ROUND((1.65 * forecast_std
            * SQRT(3))::NUMERIC)                 AS min_stock_level,

        -- Optimal order quantity (covers 7 days)
        ROUND((avg_forecast * 7)::NUMERIC)       AS optimal_order_qty,

        -- Stockout probability proxy
        ROUND((100.0 * forecast_std
            / NULLIF(avg_forecast, 0))::NUMERIC,
            1)                                   AS demand_cv_pct

    FROM store_forecast_stats s
    JOIN (
        SELECT DISTINCT
            "Store",
            "StoreType",
            "Assortment",
            competition_distance
        FROM sales
    ) st ON s."Store" = st."Store"
)
SELECT
    *,
    -- Risk classification
    CASE
        WHEN demand_cv_pct > 35  THEN 'High risk'
        WHEN demand_cv_pct > 20  THEN 'Medium risk'
        ELSE                          'Low risk'
    END                              AS inventory_risk,

    -- Replenishment frequency recommendation
    CASE
        WHEN avg_forecast > 10000 THEN 'Daily'
        WHEN avg_forecast > 7000  THEN 'Every 2 days'
        WHEN avg_forecast > 5000  THEN 'Every 3 days'
        ELSE                          'Weekly'
    END                              AS replenishment_freq,

    -- Performance tier
    CASE
        WHEN pct_excellent > 50   THEN 'Highly forecastable'
        WHEN pct_poor < 15        THEN 'Forecastable'
        ELSE                          'Hard to forecast'
    END                              AS forecastability

FROM inventory_calcs
ORDER BY avg_forecast DESC;

-- Summary by risk tier
SELECT
    inventory_risk,
    forecastability,
    COUNT(*)                         AS num_stores,
    ROUND(AVG(avg_forecast))         AS avg_daily_forecast,
    ROUND(AVG(safety_stock_adjusted)) AS avg_safety_stock,
    ROUND(AVG(reorder_point))        AS avg_reorder_point,
    ROUND(AVG(demand_cv_pct)::NUMERIC,1) AS avg_cv_pct
FROM v_forecast_inventory
GROUP BY inventory_risk, forecastability
ORDER BY avg_daily_forecast DESC;