-- Create permanent views for all key analytics
-- These views will be queried directly by the Streamlit dashboard

-- View 1: Store performance summary
CREATE OR REPLACE VIEW v_store_performance AS
WITH store_stats AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        SUM("Sales")                          AS total_sales,
        ROUND(AVG("Sales"))                   AS avg_daily_sales,
        SUM("Customers")                      AS total_customers,
        ROUND(AVG("Customers"))               AS avg_daily_customers,
        COUNT(*)                              AS trading_days,
        ROUND(AVG("Sales"::NUMERIC /
              NULLIF("Customers", 0)), 2)     AS sales_per_customer,
        ROUND(STDDEV("Sales"))                AS sales_stddev
    FROM sales
    GROUP BY "Store", "StoreType", "Assortment"
)
SELECT
    *,
    DENSE_RANK() OVER (ORDER BY avg_daily_sales   DESC) AS rank_by_avg_sales,
    DENSE_RANK() OVER (ORDER BY total_sales        DESC) AS rank_by_total_sales,
    DENSE_RANK() OVER (ORDER BY sales_per_customer DESC) AS rank_by_efficiency,
    ROUND((PERCENT_RANK() OVER (
        ORDER BY avg_daily_sales))::NUMERIC * 100, 1)    AS percentile
FROM store_stats;

-- View 2: Monthly sales summary
CREATE OR REPLACE VIEW v_monthly_sales AS
SELECT
    year,
    month,
    month_name,
    SUM("Sales")             AS total_sales,
    ROUND(AVG("Sales"))      AS avg_daily_sales,
    COUNT(DISTINCT "Store")  AS active_stores,
    COUNT(*)                 AS trading_days,
    SUM("Customers")         AS total_customers,
    ROUND(AVG("Customers"))  AS avg_customers
FROM sales
GROUP BY year, month, month_name
ORDER BY year, month;

-- View 3: Inventory risk
CREATE OR REPLACE VIEW v_inventory_risk AS
WITH store_stats AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        AVG("Sales")                          AS avg_daily_sales,
        STDDEV("Sales")                       AS stddev_daily_sales,
        MAX("Sales")                          AS max_daily_sales,
        PERCENTILE_CONT(0.95) WITHIN GROUP
            (ORDER BY "Sales")                AS p95_daily_sales,
        COUNT(*)                              AS trading_days
    FROM sales
    GROUP BY "Store", "StoreType", "Assortment"
)
SELECT
    "Store",
    "StoreType",
    "Assortment",
    ROUND(avg_daily_sales)                    AS avg_daily_sales,
    ROUND(stddev_daily_sales)                 AS sales_stddev,
    ROUND(p95_daily_sales)                    AS p95_daily_sales,
    ROUND(1.65 * stddev_daily_sales
          * SQRT(3))                          AS safety_stock,
    ROUND((avg_daily_sales * 3)
        + (1.65 * stddev_daily_sales
           * SQRT(3)))                        AS reorder_point,
    ROUND((max_daily_sales - avg_daily_sales)
        / NULLIF(stddev_daily_sales, 0), 2)   AS volatility_score,
    CASE
        WHEN ((max_daily_sales - avg_daily_sales)
            / NULLIF(stddev_daily_sales,0)) > 3 THEN 'High risk'
        WHEN ((max_daily_sales - avg_daily_sales)
            / NULLIF(stddev_daily_sales,0)) > 2 THEN 'Medium risk'
        ELSE                                       'Low risk'
    END                                       AS stockout_risk
FROM store_stats;

-- View 4: Promo effectiveness
CREATE OR REPLACE VIEW v_promo_effectiveness AS
SELECT
    "StoreType",
    "Assortment",
    ROUND(AVG("Sales") FILTER
        (WHERE "Promo" = 1))                  AS avg_sales_promo,
    ROUND(AVG("Sales") FILTER
        (WHERE "Promo" = 0))                  AS avg_sales_no_promo,
    ROUND(100.0 * (
        AVG("Sales") FILTER (WHERE "Promo"=1)
      - AVG("Sales") FILTER (WHERE "Promo"=0)
    ) / NULLIF(AVG("Sales") FILTER
        (WHERE "Promo"=0), 0), 2)             AS promo_lift_pct,
    COUNT(DISTINCT "Store")                   AS num_stores
FROM sales
GROUP BY "StoreType", "Assortment"
ORDER BY promo_lift_pct DESC;

-- Verify all 4 views
SELECT 'v_store_performance'  AS view_name,
       COUNT(*) AS rows FROM v_store_performance
UNION ALL
SELECT 'v_monthly_sales',  COUNT(*) FROM v_monthly_sales
UNION ALL
SELECT 'v_inventory_risk', COUNT(*) FROM v_inventory_risk
UNION ALL
SELECT 'v_promo_effectiveness', COUNT(*) FROM v_promo_effectiveness;