-- Step 5: Residual component (what's left after removing trend + seasonality)
-- Residuals should look like random noise if our decomposition is good
WITH daily AS (
    SELECT
        "Date",
        EXTRACT(DOW   FROM "Date")::INTEGER AS day_of_week,
        EXTRACT(MONTH FROM "Date")::INTEGER AS month,
        SUM("Sales") AS total_sales
    FROM sales
    GROUP BY "Date"
),
trend AS (
    SELECT
        "Date",
        day_of_week,
        month,
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
        total_sales,
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
    d.total_sales,
    ROUND(d.trend_28d)                        AS trend,
    ROUND(w.weekly_seasonal_index)            AS weekly_seasonal,
    ROUND(m.monthly_seasonal_index)           AS monthly_seasonal,
    -- Residual = actual - trend - weekly seasonal - monthly seasonal
    d.total_sales
        - ROUND(d.trend_28d)
        - ROUND(w.weekly_seasonal_index)
        - ROUND(m.monthly_seasonal_index)     AS residual,
    -- Residual as % of total sales (tells us how much is unexplained)
    ROUND(100.0 * (
        d.total_sales
        - ROUND(d.trend_28d)
        - ROUND(w.weekly_seasonal_index)
        - ROUND(m.monthly_seasonal_index)
    ) / NULLIF(d.total_sales, 0), 1)          AS residual_pct
FROM detrended d
JOIN weekly_index  w ON d.day_of_week = w.day_of_week
JOIN monthly_index m ON d.month       = m.month
ORDER BY d."Date";