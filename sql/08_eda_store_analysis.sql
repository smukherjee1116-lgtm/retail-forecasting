-- ─────────────────────────────────────────────
-- 4A. Store type vs assortment matrix
-- ─────────────────────────────────────────────
SELECT
    "StoreType",
    "Assortment",
    COUNT(DISTINCT "Store") AS num_stores,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers,
    ROUND(AVG(competition_distance)) AS avg_comp_distance
FROM sales
GROUP BY "StoreType", "Assortment"
ORDER BY "StoreType", avg_sales DESC;

-- ─────────────────────────────────────────────
-- 4B. Top 10 and bottom 10 stores by avg sales
-- ─────────────────────────────────────────────
WITH store_avg AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        ROUND(AVG("Sales"))     AS avg_sales,
        COUNT(*)                AS trading_days
    FROM sales
    GROUP BY "Store", "StoreType", "Assortment"
)
SELECT *, 'Top 10' AS category
FROM store_avg
ORDER BY avg_sales DESC
LIMIT 10;

-- ─────────────────────────────────────────────
-- 4C. Competition distance vs sales
-- ─────────────────────────────────────────────
SELECT
    CASE
        WHEN competition_distance < 500   THEN '0-500m'
        WHEN competition_distance < 1000  THEN '500m-1km'
        WHEN competition_distance < 5000  THEN '1km-5km'
        WHEN competition_distance < 10000 THEN '5km-10km'
        ELSE '10km+'
    END                     AS distance_bucket,
    COUNT(DISTINCT "Store") AS num_stores,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers
FROM sales
GROUP BY distance_bucket
ORDER BY MIN(competition_distance);