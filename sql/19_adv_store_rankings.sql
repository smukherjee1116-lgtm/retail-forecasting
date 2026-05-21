-- Store performance rankings using window functions
-- DENSE_RANK ensures no gaps if two stores tie
WITH store_stats AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        SUM("Sales")                     AS total_sales,
        ROUND(AVG("Sales"))              AS avg_daily_sales,
        SUM("Customers")                 AS total_customers,
        ROUND(AVG("Customers"))          AS avg_daily_customers,
        COUNT(*)                         AS trading_days,
        ROUND(AVG("Sales"::NUMERIC /
              NULLIF("Customers", 0)), 2) AS sales_per_customer
    FROM sales
    GROUP BY "Store", "StoreType", "Assortment"
)
SELECT
    "Store",
    "StoreType",
    "Assortment",
    total_sales,
    avg_daily_sales,
    avg_daily_customers,
    sales_per_customer,
    trading_days,
    -- Global rank across all stores
    DENSE_RANK() OVER (ORDER BY total_sales      DESC) AS rank_by_total_sales,
    DENSE_RANK() OVER (ORDER BY avg_daily_sales  DESC) AS rank_by_avg_sales,
    DENSE_RANK() OVER (ORDER BY sales_per_customer DESC) AS rank_by_efficiency,
    -- Rank within store type
    DENSE_RANK() OVER (
        PARTITION BY "StoreType"
        ORDER BY avg_daily_sales DESC
    ) AS rank_within_store_type,
    -- Percentile: what % of stores does this store beat?
    ROUND(100.0 * PERCENT_RANK() OVER (
        ORDER BY avg_daily_sales
    ), 1) AS percentile
FROM store_stats
ORDER BY rank_by_avg_sales
LIMIT 20;