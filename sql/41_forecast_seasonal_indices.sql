-- Calculate seasonal indices for day-of-week and month
-- Seasonal index = avg detrended sales for that period
-- Index > 0 means above trend, < 0 means below trend
CREATE OR REPLACE VIEW v_seasonal_indices AS
WITH train_data AS (
    SELECT
        "Store",
        "Date",
        "DayOfWeek",
        month,
        detrended_sales
    FROM v_trend_model
    WHERE split = 'train'
),
-- Day of week seasonal index per store
dow_index AS (
    SELECT
        "Store",
        "DayOfWeek",
        ROUND(AVG(detrended_sales)::NUMERIC) AS dow_seasonal_index,
        COUNT(*)                             AS obs_count
    FROM train_data
    GROUP BY "Store", "DayOfWeek"
),
-- Month seasonal index per store
month_index AS (
    SELECT
        "Store",
        month,
        ROUND(AVG(detrended_sales)::NUMERIC) AS month_seasonal_index,
        COUNT(*)                             AS obs_count
    FROM train_data
    GROUP BY "Store", month
)
SELECT
    d."Store",
    d."DayOfWeek",
    d.dow_seasonal_index,
    m.month,
    m.month_seasonal_index
FROM dow_index d
JOIN month_index m ON d."Store" = m."Store"
ORDER BY d."Store", d."DayOfWeek", m.month;

-- Show seasonal indices for Store 1
SELECT
    "DayOfWeek",
    CASE "DayOfWeek"
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 7 THEN 'Sunday'
    END                                     AS day_name,
    dow_seasonal_index,
    month,
    month_seasonal_index
FROM v_seasonal_indices
WHERE "Store" = 1
ORDER BY "DayOfWeek", month;