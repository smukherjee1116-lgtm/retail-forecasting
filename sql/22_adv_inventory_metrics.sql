-- Inventory intelligence metrics
-- Reorder point, safety stock, and stockout risk per store
-- Based on sales variability and lead time assumptions
WITH store_daily_stats AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        AVG("Sales")                         AS avg_daily_sales,
        STDDEV("Sales")                      AS stddev_daily_sales,
        MAX("Sales")                         AS max_daily_sales,
        MIN("Sales")                         AS min_daily_sales,
        PERCENTILE_CONT(0.95) WITHIN GROUP
            (ORDER BY "Sales")               AS p95_daily_sales,
        COUNT(*)                             AS trading_days
    FROM sales
    GROUP BY "Store", "StoreType", "Assortment"
),
inventory_calc AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        ROUND(avg_daily_sales)               AS avg_daily_sales,
        ROUND(stddev_daily_sales)            AS stddev_daily_sales,
        ROUND(max_daily_sales)               AS max_daily_sales,
        ROUND(p95_daily_sales)               AS p95_daily_sales,
        trading_days,

        -- Lead time assumption: 3 days for replenishment
        -- Safety stock = Z * stddev * sqrt(lead_time)
        -- Z=1.65 for 95% service level
        ROUND(1.65 * stddev_daily_sales
              * SQRT(3))                     AS safety_stock_95pct,

        -- Reorder point = avg demand during lead time + safety stock
        ROUND((avg_daily_sales * 3)
            + (1.65 * stddev_daily_sales
               * SQRT(3)))                   AS reorder_point,

        -- Days of stock needed to avoid stockout (at avg sales)
        -- Assume current stock = 7 days of avg sales
        7                                    AS assumed_stock_days,

        -- Stockout risk score: how many std deviations is max from mean?
        -- Higher = more volatile = higher stockout risk
        ROUND((max_daily_sales - avg_daily_sales)
              / NULLIF(stddev_daily_sales, 0), 2) AS volatility_score
    FROM store_daily_stats
)
SELECT
    "Store",
    "StoreType",
    "Assortment",
    avg_daily_sales,
    stddev_daily_sales,
    safety_stock_95pct,
    reorder_point,
    volatility_score,
    -- Risk classification
    CASE
        WHEN volatility_score > 3.0 THEN 'High risk'
        WHEN volatility_score > 2.0 THEN 'Medium risk'
        ELSE                              'Low risk'
    END                                  AS stockout_risk,
    DENSE_RANK() OVER (
        ORDER BY volatility_score DESC
    )                                    AS risk_rank
FROM inventory_calc
ORDER BY volatility_score DESC
LIMIT 20;