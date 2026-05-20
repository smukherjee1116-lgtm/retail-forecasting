-- Step 4: Monthly seasonal index
-- Shows which months are above/below the annual average
WITH daily AS (
    SELECT
        "Date",
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        TO_CHAR("Date", 'Mon') AS month_name,
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
),
trend AS (
    SELECT
        "Date",
        month,
        month_name,
        total_sales,
        AVG(total_sales) OVER (
            ORDER BY "Date"
            ROWS BETWEEN 13 PRECEDING AND 14 FOLLOWING
        ) AS trend_28d
    FROM daily
),
detrended AS (
    SELECT
        month,
        month_name,
        total_sales - trend_28d AS detrended
    FROM trend
),
monthly_seasonal AS (
    SELECT
        month,
        month_name,
        ROUND(AVG(detrended)) AS monthly_seasonal_index
    FROM detrended
    GROUP BY month, month_name
),
overall AS (
    SELECT AVG(monthly_seasonal_index) AS avg_index
    FROM monthly_seasonal
)
SELECT
    m.month,
    m.month_name,
    m.monthly_seasonal_index,
    ROUND(100.0 * m.monthly_seasonal_index /
          NULLIF(ABS(o.avg_index), 0), 1) AS relative_strength
FROM monthly_seasonal m, overall o
ORDER BY m.month;