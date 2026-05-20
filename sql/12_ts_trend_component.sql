-- Step 2: Trend component using centered moving average
-- A 28-day window smooths out weekly seasonality (4 complete weeks)
WITH daily AS (
    SELECT
        "Date",
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
)
SELECT
    "Date",
    total_sales,
    ROUND(AVG(total_sales) OVER (
        ORDER BY "Date"
        ROWS BETWEEN 13 PRECEDING AND 14 FOLLOWING
    )) AS trend_28d,
    ROUND(AVG(total_sales) OVER (
        ORDER BY "Date"
        ROWS BETWEEN 6 PRECEDING AND 7 FOLLOWING
    )) AS trend_14d,
    total_sales - ROUND(AVG(total_sales) OVER (
        ORDER BY "Date"
        ROWS BETWEEN 13 PRECEDING AND 14 FOLLOWING
    )) AS detrended_sales
FROM daily
ORDER BY "Date";