-- Fit linear trend using SQL's built-in regression functions
-- REGR_SLOPE and REGR_INTERCEPT fit y = a + b*x
-- where x = day number (1, 2, 3...) and y = actual sales
CREATE OR REPLACE VIEW v_trend_model AS
WITH numbered AS (
    SELECT
        "Store",
        "Date",
        actual_sales,
        "DayOfWeek",
        month,
        year,
        CASE WHEN "Date" < '2015-01-01'
             THEN 'train' ELSE 'test'
        END                             AS split,
        -- Convert date to integer day number
        -- Day 1 = first trading day per store
        ROW_NUMBER() OVER (
            PARTITION BY "Store"
            ORDER BY "Date"
        )                               AS day_num
    FROM v_forecast_ready
),
regression AS (
    SELECT
        "Store",
        -- Slope: how much sales change per day
        REGR_SLOPE(actual_sales, day_num)       AS slope,
        -- Intercept: baseline sales at day 0
        REGR_INTERCEPT(actual_sales, day_num)   AS intercept,
        -- R-squared: how well trend fits
        REGR_R2(actual_sales, day_num)          AS r_squared,
        -- Average sales (used for detrending)
        AVG(actual_sales)                       AS mean_sales
    FROM numbered
    WHERE split = 'train'
    GROUP BY "Store"
)
SELECT
    n."Store",
    n."Date",
    n.actual_sales,
    n.day_num,
    n.split,
    n."DayOfWeek",
    n.month,
    n.year,
    ROUND(r.slope::NUMERIC, 4)          AS slope,
    ROUND(r.intercept::NUMERIC, 2)      AS intercept,
    ROUND(r.r_squared::NUMERIC, 4)      AS r_squared,
    -- Trend forecast = intercept + slope * day_num
    ROUND((r.intercept
        + r.slope * n.day_num)::NUMERIC) AS trend_forecast,
    -- Detrended sales = actual - trend
    ROUND((n.actual_sales
        - (r.intercept
        + r.slope * n.day_num))::NUMERIC) AS detrended_sales
FROM numbered n
JOIN regression r ON n."Store" = r."Store"
ORDER BY n."Store", n."Date";

-- Check trend stats for sample stores
SELECT
    "Store",
    ROUND(AVG(slope)::NUMERIC, 4)       AS daily_slope,
    ROUND(AVG(r_squared)::NUMERIC, 4)   AS r_squared,
    ROUND(AVG(actual_sales))            AS avg_sales,
    -- Annualised trend
    ROUND((AVG(slope) * 365)::NUMERIC)  AS annual_trend
FROM v_trend_model
GROUP BY "Store"
ORDER BY r_squared DESC
LIMIT 10;