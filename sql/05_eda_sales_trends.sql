-- ─────────────────────────────────────────────
-- 1A. Monthly sales trend across all stores
-- ─────────────────────────────────────────────
SELECT
    year,
    month,
    month_name,
    SUM("Sales")            AS total_sales,
    ROUND(AVG("Sales"))     AS avg_daily_sales,
    COUNT(DISTINCT "Store") AS active_stores,
    COUNT(*)                AS trading_days
FROM sales
GROUP BY year, month, month_name
ORDER BY year, month;

-- ─────────────────────────────────────────────
-- 1B. Yearly summary
-- ─────────────────────────────────────────────
SELECT
    year,
    SUM("Sales")            AS total_sales,
    ROUND(AVG("Sales"))     AS avg_daily_sales,
    COUNT(DISTINCT "Store") AS active_stores,
    COUNT(*)                AS trading_days
FROM sales
GROUP BY year
ORDER BY year;

-- ─────────────────────────────────────────────
-- 1C. Year-over-year growth
-- ─────────────────────────────────────────────
WITH yearly AS (
    SELECT
        year,
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY year
)
SELECT
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year)  AS prev_year_sales,
    ROUND(
        100.0 * (total_sales - LAG(total_sales) OVER (ORDER BY year))
              / LAG(total_sales) OVER (ORDER BY year),
        2
    ) AS yoy_growth_pct
FROM yearly
ORDER BY year;