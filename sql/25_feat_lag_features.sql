-- Lag features per store per day
-- Based on Day 3 autocorrelation: lag_7 and lag_14 are strongest
SELECT
    "Store",
    "Date",
    "Sales",
    "DayOfWeek",
    "Promo",

    -- Lag features (same weekday previous weeks)
    LAG("Sales", 7)  OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_7,
    LAG("Sales", 14) OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_14,
    LAG("Sales", 21) OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_21,
    LAG("Sales", 28) OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_28,

    -- Same period last year
    LAG("Sales", 364) OVER (PARTITION BY "Store" ORDER BY "Date") AS lag_364,

    -- Lead (next day) — useful for understanding pre-event spikes
    LEAD("Sales", 1) OVER (PARTITION BY "Store" ORDER BY "Date") AS lead_1,
    LEAD("Sales", 7) OVER (PARTITION BY "Store" ORDER BY "Date") AS lead_7
FROM sales
WHERE "Store" = 1
ORDER BY "Date";