-- 1. Date range and overall stats
SELECT
    MIN("Date")             AS start_date,
    MAX("Date")             AS end_date,
    COUNT(DISTINCT "Store") AS num_stores,
    COUNT(*)                AS total_rows,
    ROUND(AVG("Sales"))     AS avg_daily_sales,
    MAX("Sales")            AS max_daily_sales,
    MIN("Sales")            AS min_daily_sales
FROM sales;

-- 2. Top 5 stores by total revenue
SELECT
    "Store",
    SUM("Sales")        AS total_sales,
    ROUND(AVG("Sales")) AS avg_daily_sales,
    COUNT(*)            AS trading_days
FROM sales
GROUP BY "Store"
ORDER BY total_sales DESC
LIMIT 5;

-- 3. Missing value check — all must be 0
SELECT
    COUNT(*) FILTER (WHERE competition_distance IS NULL) AS missing_comp_dist,
    COUNT(*) FILTER (WHERE "StoreType"          IS NULL) AS missing_store_type,
    COUNT(*) FILTER (WHERE "Sales"              IS NULL) AS missing_sales,
    COUNT(*) FILTER (WHERE "Date"               IS NULL) AS missing_date
FROM sales;

-- 4. Store type distribution
SELECT
    "StoreType",
    COUNT(DISTINCT "Store") AS num_stores,
    ROUND(AVG("Sales"))     AS avg_sales
FROM sales
GROUP BY "StoreType"
ORDER BY avg_sales DESC;