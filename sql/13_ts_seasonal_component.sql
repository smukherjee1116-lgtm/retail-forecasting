-- Step 3: Seasonal component
-- Calculate the average sales for each day-of-week and month
-- to isolate repeating seasonal patterns
WITH daily AS (
    SELECT
        "Date",
        EXTRACT(DOW FROM "Date")::INTEGER AS day_of_week,
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        EXTRACT(YEAR FROM "Date")::INTEGER AS year,
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
),
trend AS (
    SELECT
        "Date",
        day_of_week,
        month,
        year,
        total_sales,
        AVG(total_sales) OVER (
            ORDER BY "Date"
            ROWS BETWEEN 13 PRECEDING AND 14 FOLLOWING
        ) AS trend_28d
    FROM daily
),
detrended AS (
    SELECT
        "Date",
        day_of_week,
        month,
        year,
        total_sales,
        trend_28d,
        total_sales - trend_28d AS detrended
    FROM trend
),
-- Weekly seasonal index: avg detrended value per day-of-week
weekly_seasonal AS (
    SELECT
        day_of_week,
        ROUND(AVG(detrended)) AS weekly_seasonal_index
    FROM detrended
    GROUP BY day_of_week
),
-- Monthly seasonal index
monthly_seasonal AS (
    SELECT
        month,
        ROUND(AVG(detrended)) AS monthly_seasonal_index
    FROM detrended
    GROUP BY month
)
SELECT
    w.day_of_week,
    CASE w.day_of_week
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END                          AS day_name,
    w.weekly_seasonal_index
FROM weekly_seasonal w
ORDER BY w.day_of_week;