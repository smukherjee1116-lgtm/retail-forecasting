-- Materialise store summary for dashboard
DROP TABLE IF EXISTS t_store_summary;
CREATE TABLE t_store_summary AS
SELECT
    s."Store",
    s."StoreType",
    s."Assortment",
    s.competition_distance,
    s.inventory_risk,
    s.forecastability,
    s.replenishment_freq,
    s.store_segment,
    s.avg_daily_forecast,
    s.forecast_volatility,
    s.avg_mape,
    s.pct_excellent,
    s.pct_poor,
    s.safety_stock,
    s.reorder_point,
    s.min_stock_level,
    s.max_stock_level,
    s.optimal_order_qty,
    s.demand_cv_pct,
    s.alert_level,
    s.days_of_stock,
    s.velocity_ratio,
    s.recommended_order_qty,
    s.last_7d_avg_sales,
    s.last_7d_mape,
    s.sales_rank,
    s.accuracy_rank,

    -- Add historical performance from v_store_performance
    p.total_sales,
    p.avg_daily_sales       AS historical_avg_sales,
    p.total_customers,
    p.avg_daily_customers,
    p.sales_per_customer,
    p.trading_days,
    p.rank_by_avg_sales,
    p.rank_by_total_sales,
    p.rank_by_efficiency,
    p.percentile,

    -- Add segmentation info
    seg.promo_day_pct,
    seg.growth_pct,
    seg.cv_pct              AS historical_cv_pct,
    seg.store_segment       AS rfm_segment,
    seg.composite_score

FROM v_store_forecast_summary s
JOIN v_store_performance p
  ON s."Store" = p."Store"
JOIN v_store_segmentation seg
  ON s."Store" = seg."Store"
ORDER BY s.avg_daily_forecast DESC;

-- Add index
CREATE INDEX idx_tss_store ON t_store_summary("Store");

-- Verify
SELECT
    store_segment,
    COUNT(*)                        AS num_stores,
    ROUND(AVG(avg_daily_forecast))  AS avg_forecast,
    ROUND(AVG(avg_mape)::NUMERIC,1) AS avg_mape,
    ROUND(AVG(safety_stock))        AS avg_safety_stock,
    ROUND(AVG(days_of_stock)
        ::NUMERIC,1)                AS avg_days_stock
FROM t_store_summary
GROUP BY store_segment
ORDER BY avg_forecast DESC;