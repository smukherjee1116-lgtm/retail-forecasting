-- Step 1: Daily aggregated sales across all stores
-- This gives us the "total market" time series we will decompose
SELECT
    "Date",
    SUM("Sales")            AS total_sales,
    ROUND(AVG("Sales"))     AS avg_sales,
    COUNT(DISTINCT "Store") AS num_stores,
    SUM("Customers")        AS total_customers
FROM sales
GROUP BY "Date"
ORDER BY "Date";