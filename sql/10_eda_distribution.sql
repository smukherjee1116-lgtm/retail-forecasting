-- ─────────────────────────────────────────────
-- 6A. Sales distribution statistics
-- ─────────────────────────────────────────────
SELECT
    ROUND(AVG("Sales"))                                    AS mean_sales,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP
          (ORDER BY "Sales"))                              AS q1,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP
          (ORDER BY "Sales"))                              AS median_sales,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP
          (ORDER BY "Sales"))                              AS q3,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP
          (ORDER BY "Sales"))                              AS p95,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP
          (ORDER BY "Sales"))                              AS p99,
    MAX("Sales")                                           AS max_sales,
    MIN("Sales")                                           AS min_sales,
    ROUND(STDDEV("Sales"))                                 AS std_dev
FROM sales;

-- ─────────────────────────────────────────────
-- 6B. Outlier detection using IQR method
-- ─────────────────────────────────────────────
WITH stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY "Sales") AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY "Sales") AS q3
    FROM sales
),
bounds AS (
    SELECT
        q1,
        q3,
        q1 - 1.5 * (q3 - q1) AS lower_bound,
        q3 + 1.5 * (q3 - q1) AS upper_bound
    FROM stats
)
SELECT
    b.lower_bound,
    b.upper_bound,
    COUNT(*) FILTER (WHERE s."Sales" > b.upper_bound) AS upper_outliers,
    COUNT(*) FILTER (WHERE s."Sales" < b.lower_bound) AS lower_outliers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE s."Sales" > b.upper_bound)
          / COUNT(*), 2)                               AS outlier_pct
FROM sales s, bounds b
GROUP BY b.lower_bound, b.upper_bound;

-- ─────────────────────────────────────────────
-- 6C. Sales histogram buckets
-- ─────────────────────────────────────────────
SELECT
    CASE
        WHEN "Sales" < 2000  THEN '0-2K'
        WHEN "Sales" < 4000  THEN '2K-4K'
        WHEN "Sales" < 6000  THEN '4K-6K'
        WHEN "Sales" < 8000  THEN '6K-8K'
        WHEN "Sales" < 10000 THEN '8K-10K'
        WHEN "Sales" < 15000 THEN '10K-15K'
        ELSE '15K+'
    END                  AS sales_bucket,
    COUNT(*)             AS num_days,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM sales
GROUP BY sales_bucket
ORDER BY MIN("Sales");