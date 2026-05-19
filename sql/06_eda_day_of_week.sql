-- ─────────────────────────────────────────────
-- 2A. Sales by day of week (1=Mon, 7=Sun)
-- ─────────────────────────────────────────────
SELECT
    "DayOfWeek",
    TRIM(day_name)          AS day_name,
    COUNT(*)                AS num_records,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers,
    SUM("Sales")            AS total_sales
FROM sales
GROUP BY "DayOfWeek", day_name
ORDER BY "DayOfWeek";

-- ─────────────────────────────────────────────
-- 2B. Best and worst day per store type
-- ─────────────────────────────────────────────
SELECT
    "StoreType",
    TRIM(day_name)          AS day_name,
    "DayOfWeek",
    ROUND(AVG("Sales"))     AS avg_sales,
    RANK() OVER (
        PARTITION BY "StoreType"
        ORDER BY AVG("Sales") DESC
    ) AS day_rank
FROM sales
GROUP BY "StoreType", day_name, "DayOfWeek"
ORDER BY "StoreType", day_rank;