-- Dynamic reorder alerts
-- Simulates what would trigger in a real inventory system
-- Based on the last 7 days of actual vs forecast
CREATE OR REPLACE VIEW v_reorder_alerts AS
WITH recent_performance AS (
    SELECT
        "Store",
        -- Last 7 days average actual sales
        ROUND(AVG(actual_sales) FILTER (
            WHERE "Date" >= '2015-07-24'
              AND "Date" <= '2015-07-31'
        )::NUMERIC)                         AS last_7d_avg_sales,
        -- Last 7 days forecast
        ROUND(AVG(ensemble_forecast) FILTER (
            WHERE "Date" >= '2015-07-24'
              AND "Date" <= '2015-07-31'
        )::NUMERIC)                         AS last_7d_avg_forecast,
        -- Forecast accuracy last 7 days
        ROUND(AVG(ensemble_ape) FILTER (
            WHERE "Date" >= '2015-07-24'
              AND "Date" <= '2015-07-31'
        )::NUMERIC, 1)                      AS last_7d_mape
    FROM v_final_forecast
    GROUP BY "Store"
),
inventory_position AS (
    SELECT
        r."Store",
        r.last_7d_avg_sales,
        r.last_7d_avg_forecast,
        r.last_7d_mape,
        i.avg_forecast,
        i.safety_stock_adjusted,
        i.reorder_point,
        i.optimal_order_qty,
        i.inventory_risk,
        i.replenishment_freq,
        i."StoreType",
        i."Assortment",

        -- Simulate current stock (7 days of avg forecast)
        ROUND((i.avg_forecast * 7)::NUMERIC) AS simulated_stock,

        -- Days of stock remaining at recent sales rate
        ROUND((i.avg_forecast * 7 /
            NULLIF(r.last_7d_avg_sales, 0)
        )::NUMERIC, 1)                      AS days_of_stock,

        -- Velocity ratio: recent vs historical
        ROUND((r.last_7d_avg_sales::NUMERIC /
            NULLIF(i.avg_forecast, 0)
        )::NUMERIC, 2)                      AS velocity_ratio

    FROM recent_performance r
    JOIN v_forecast_inventory i
      ON r."Store" = i."Store"
    WHERE r.last_7d_avg_sales IS NOT NULL
)
SELECT
    *,
    -- Alert level
    CASE
        WHEN days_of_stock < 3          THEN 'CRITICAL - Order immediately'
        WHEN days_of_stock < 5          THEN 'WARNING  - Order within 24hrs'
        WHEN velocity_ratio > 1.3       THEN 'WATCH    - Demand surging'
        WHEN days_of_stock < 7          THEN 'MONITOR  - Reorder soon'
        ELSE                                 'OK       - Stock sufficient'
    END                                 AS alert_level,

    -- Recommended order quantity
    CASE
        WHEN days_of_stock < 3
            THEN optimal_order_qty * 2
        WHEN days_of_stock < 5
            THEN optimal_order_qty
        WHEN velocity_ratio > 1.3
            THEN ROUND(optimal_order_qty * velocity_ratio)
        ELSE
            ROUND(optimal_order_qty * 0.5)
    END                                 AS recommended_order_qty

FROM inventory_position
ORDER BY days_of_stock ASC;

-- Alert summary
SELECT
    alert_level,
    COUNT(*)                            AS num_stores,
    ROUND(AVG(days_of_stock)::NUMERIC,1) AS avg_days_of_stock,
    ROUND(AVG(velocity_ratio)::NUMERIC,2) AS avg_velocity_ratio,
    ROUND(AVG(last_7d_mape)::NUMERIC,1)  AS avg_forecast_accuracy
FROM v_reorder_alerts
GROUP BY alert_level
ORDER BY num_stores DESC;