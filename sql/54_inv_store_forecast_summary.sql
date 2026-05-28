-- Complete store forecast summary
-- One row per store with all metrics the dashboard needs
CREATE OR REPLACE VIEW v_store_forecast_summary AS
SELECT
    f."Store",
    f."StoreType",
    f."Assortment",
    f.competition_distance,
    f.inventory_risk,
    f.forecastability,
    f.replenishment_freq,

    -- Forecast metrics
    f.avg_forecast              AS avg_daily_forecast,
    f.forecast_std              AS forecast_volatility,
    f.avg_forecast_error_pct    AS avg_mape,
    f.pct_excellent,
    f.pct_poor,

    -- Inventory levels
    f.safety_stock_adjusted     AS safety_stock,
    f.reorder_point,
    f.min_stock_level,
    f.max_stock_level,
    f.optimal_order_qty,
    f.demand_cv_pct,

    -- Alert status
    a.alert_level,
    a.days_of_stock,
    a.velocity_ratio,
    a.recommended_order_qty,
    a.last_7d_avg_sales,
    a.last_7d_mape,

    -- Store performance ranking
    DENSE_RANK() OVER (
        ORDER BY f.avg_forecast DESC
    )                           AS sales_rank,
    DENSE_RANK() OVER (
        ORDER BY f.avg_forecast_error_pct
    )                           AS accuracy_rank,

    -- Segment
    CASE
        WHEN f.avg_forecast >= 10000 THEN 'Premium'
        WHEN f.avg_forecast >= 7000  THEN 'High'
        WHEN f.avg_forecast >= 5000  THEN 'Medium'
        ELSE                              'Standard'
    END                         AS store_segment

FROM v_forecast_inventory f
JOIN v_reorder_alerts a ON f."Store" = a."Store"
ORDER BY f.avg_forecast DESC;

-- Verify
SELECT
    store_segment,
    inventory_risk,
    COUNT(*)                    AS num_stores,
    ROUND(AVG(avg_daily_forecast)) AS avg_forecast,
    ROUND(AVG(avg_mape)::NUMERIC,1) AS avg_mape,
    ROUND(AVG(days_of_stock)::NUMERIC,1) AS avg_days_stock
FROM v_store_forecast_summary
GROUP BY store_segment, inventory_risk
ORDER BY avg_forecast DESC;