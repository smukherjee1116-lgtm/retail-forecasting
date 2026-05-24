CREATE OR REPLACE VIEW v_inventory_intelligence AS
WITH store_stats AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        competition_distance,
        COUNT(*)                                      AS total_trading_days,
        ROUND(AVG("Sales")::NUMERIC)                  AS avg_daily_sales,
        ROUND(STDDEV("Sales")::NUMERIC)               AS stddev_daily_sales,
        ROUND(MIN("Sales")::NUMERIC)                  AS min_daily_sales,
        ROUND(MAX("Sales")::NUMERIC)                  AS max_daily_sales,
        ROUND(PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY "Sales")::NUMERIC) AS median_daily_sales,
        ROUND(PERCENTILE_CONT(0.95)
            WITHIN GROUP (ORDER BY "Sales")::NUMERIC) AS p95_daily_sales,
        ROUND(AVG("Sales")
            FILTER (WHERE "Promo"=1)::NUMERIC)        AS avg_sales_promo,
        ROUND(AVG("Sales")
            FILTER (WHERE "Promo"=0)::NUMERIC)        AS avg_sales_no_promo,
        ROUND(AVG("Customers")::NUMERIC)              AS avg_daily_customers,
        ROUND(AVG("Sales"::NUMERIC /
            NULLIF("Customers",0)), 2)                AS avg_sales_per_customer
    FROM sales
    GROUP BY "Store","StoreType","Assortment",competition_distance
),
inventory_metrics AS (
    SELECT
        *,
        ROUND((1.65 * stddev_daily_sales
              * SQRT(3))::NUMERIC)                    AS safety_stock_95pct,
        ROUND(((avg_daily_sales * 3)
            + (1.65 * stddev_daily_sales
               * SQRT(3)))::NUMERIC)                  AS reorder_point_3day,
        ROUND(SQRT((2.0 * avg_daily_sales
              * 365 * 100.0)
              / NULLIF(avg_daily_sales * 0.2,
                       0))::NUMERIC)                  AS eoq_annual,
        ROUND(((max_daily_sales - avg_daily_sales)
            / NULLIF(stddev_daily_sales,0))::NUMERIC,
            2)                                        AS volatility_score,
        ROUND((100.0 * stddev_daily_sales
            / NULLIF(avg_daily_sales,0))::NUMERIC,
            1)                                        AS cv_pct
    FROM store_stats
)
SELECT
    *,
    CASE
        WHEN cv_pct > 40 THEN 'High uncertainty'
        WHEN cv_pct > 25 THEN 'Medium uncertainty'
        ELSE                  'Low uncertainty'
    END                                               AS demand_uncertainty,
    CASE
        WHEN avg_daily_sales >= 10000 THEN 'Tier 1 - Premium'
        WHEN avg_daily_sales >= 7000  THEN 'Tier 2 - High'
        WHEN avg_daily_sales >= 5000  THEN 'Tier 3 - Medium'
        ELSE                               'Tier 4 - Standard'
    END                                               AS performance_tier,
    ROUND(((avg_sales_promo - avg_sales_no_promo)
        * 100.0
        / NULLIF(avg_sales_no_promo,0))::NUMERIC,
        1)                                            AS promo_lift_pct
FROM inventory_metrics
ORDER BY avg_daily_sales DESC;

-- Verify
SELECT
    performance_tier,
    demand_uncertainty,
    COUNT(*)                        AS num_stores,
    ROUND(AVG(avg_daily_sales))     AS avg_sales,
    ROUND(AVG(cv_pct)::NUMERIC, 1)  AS avg_cv_pct
FROM v_inventory_intelligence
GROUP BY performance_tier, demand_uncertainty
ORDER BY avg_sales DESC;