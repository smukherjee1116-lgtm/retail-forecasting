-- Step 7: Stationarity check
-- A stationary series has constant mean and variance over time
-- We check this by comparing stats across different time periods
WITH daily AS (
    SELECT
        "Date",
        EXTRACT(YEAR  FROM "Date")::INTEGER AS year,
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
),
quarterly AS (
    SELECT
        year,
        CASE
            WHEN month BETWEEN 1 AND 3  THEN 'Q1'
            WHEN month BETWEEN 4 AND 6  THEN 'Q2'
            WHEN month BETWEEN 7 AND 9  THEN 'Q3'
            ELSE                             'Q4'
        END AS quarter,
        total_sales
    FROM daily
)
SELECT
    year,
    quarter,
    COUNT(*)                        AS num_days,
    ROUND(AVG(total_sales))         AS mean_sales,
    ROUND(STDDEV(total_sales))      AS std_dev,
    MIN(total_sales)                AS min_sales,
    MAX(total_sales)                AS max_sales,
    -- Coefficient of variation: std/mean — measures relative volatility
    ROUND(100.0 * STDDEV(total_sales)
          / NULLIF(AVG(total_sales), 0), 1) AS cv_pct
FROM quarterly
GROUP BY year, quarter
ORDER BY year, quarter;