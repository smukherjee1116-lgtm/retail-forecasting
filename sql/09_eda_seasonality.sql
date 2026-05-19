-- ─────────────────────────────────────────────
-- 5A. Monthly seasonality index
--     (ratio of month avg to overall avg)
-- ─────────────────────────────────────────────
WITH overall AS (
    SELECT AVG("Sales") AS grand_avg FROM sales
),
monthly AS (
    SELECT
        month,
        month_name,
        AVG("Sales") AS month_avg
    FROM sales
    GROUP BY month, month_name
)
SELECT
    m.month,
    m.month_name,
    ROUND(m.month_avg)                          AS avg_sales,
    ROUND(100.0 * m.month_avg / o.grand_avg, 1) AS seasonality_index
FROM monthly m, overall o
ORDER BY m.month;

-- ─────────────────────────────────────────────
-- 5B. 4-week rolling average sales per store
--     (sample: store 1)
-- ─────────────────────────────────────────────
SELECT
    "Store",
    "Date",
    "Sales",
    ROUND(AVG("Sales") OVER (
        PARTITION BY "Store"
        ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND CURRENT ROW
    )) AS rolling_28d_avg,
    ROUND(AVG("Sales") OVER (
        PARTITION BY "Store"
        ORDER BY "Date"
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )) AS rolling_7d_avg
FROM sales
WHERE "Store" = 1
ORDER BY "Date";

-- ─────────────────────────────────────────────
-- 5C. Week of year sales pattern
-- ─────────────────────────────────────────────
SELECT
    week_of_year,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers,
    COUNT(*)                AS num_records
FROM sales
GROUP BY week_of_year
ORDER BY week_of_year;