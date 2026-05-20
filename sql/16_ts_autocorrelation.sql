-- Step 6: Manual autocorrelation analysis
-- Measures how much today's sales correlates with past days
-- Key lags to check: 1 (yesterday), 7 (last week), 30 (last month)
WITH daily AS (
    SELECT
        "Date",
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
),
with_lags AS (
    SELECT
        "Date",
        total_sales,
        LAG(total_sales, 1)  OVER (ORDER BY "Date") AS lag_1,
        LAG(total_sales, 7)  OVER (ORDER BY "Date") AS lag_7,
        LAG(total_sales, 14) OVER (ORDER BY "Date") AS lag_14,
        LAG(total_sales, 30) OVER (ORDER BY "Date") AS lag_30,
        LAG(total_sales, 90) OVER (ORDER BY "Date") AS lag_90,
        LAG(total_sales, 365)OVER (ORDER BY "Date") AS lag_365
    FROM daily
)
SELECT
    'lag_1   (yesterday)'       AS lag_period,
    ROUND(CORR(total_sales, lag_1)::NUMERIC,   4) AS correlation
FROM with_lags WHERE lag_1   IS NOT NULL
UNION ALL
SELECT
    'lag_7   (last week)',
    ROUND(CORR(total_sales, lag_7)::NUMERIC,   4)
FROM with_lags WHERE lag_7   IS NOT NULL
UNION ALL
SELECT
    'lag_14  (2 weeks ago)',
    ROUND(CORR(total_sales, lag_14)::NUMERIC,  4)
FROM with_lags WHERE lag_14  IS NOT NULL
UNION ALL
SELECT
    'lag_30  (last month)',
    ROUND(CORR(total_sales, lag_30)::NUMERIC,  4)
FROM with_lags WHERE lag_30  IS NOT NULL
UNION ALL
SELECT
    'lag_90  (last quarter)',
    ROUND(CORR(total_sales, lag_90)::NUMERIC,  4)
FROM with_lags WHERE lag_90  IS NOT NULL
UNION ALL
SELECT
    'lag_365 (last year)',
    ROUND(CORR(total_sales, lag_365)::NUMERIC, 4)
FROM with_lags WHERE lag_365 IS NOT NULL;