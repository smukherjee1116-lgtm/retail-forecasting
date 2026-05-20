-- Step 8: Create a permanent view storing the full decomposition
-- This view will be reused in feature engineering (Day 5)
CREATE OR REPLACE VIEW v_time_series_decomposition AS
WITH daily AS (
    SELECT
        "Date",
        EXTRACT(DOW   FROM "Date")::INTEGER AS day_of_week,
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        EXTRACT(YEAR  FROM "Date")::INTEGER AS year,
        SUM("Sales")     AS total_sales,
        SUM("Customers") AS total_customers,
        COUNT(DISTINCT "Store") AS num_stores
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
        total_customers,
        num_stores,
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
        total_customers,
        num_stores,
        trend_28d,
        total_sales - trend_28d AS detrended
    FROM trend
),
weekly_index AS (
    SELECT
        day_of_week,
        AVG(detrended) AS weekly_seasonal_index
    FROM detrended
    GROUP BY day_of_week
),
monthly_index AS (
    SELECT
        month,
        AVG(detrended) AS monthly_seasonal_index
    FROM detrended
    GROUP BY month
)
SELECT
    d."Date",
    d.year,
    d.month,
    d.day_of_week,
    d.total_sales,
    d.total_customers,
    d.num_stores,
    ROUND(d.trend_28d)                   AS trend,
    ROUND(w.weekly_seasonal_index)       AS weekly_seasonal,
    ROUND(m.monthly_seasonal_index)      AS monthly_seasonal,
    d.total_sales
        - ROUND(d.trend_28d)
        - ROUND(w.weekly_seasonal_index)
        - ROUND(m.monthly_seasonal_index) AS residual,
    -- Lag features (for modelling)
    LAG(d.total_sales, 7)  OVER (ORDER BY d."Date") AS lag_7,
    LAG(d.total_sales, 14) OVER (ORDER BY d."Date") AS lag_14
FROM detrended d
JOIN weekly_index  w ON d.day_of_week = w.day_of_week
JOIN monthly_index m ON d.month       = m.month;

-- Verify the view works
SELECT * FROM v_time_series_decomposition
ORDER BY "Date"
LIMIT 10;