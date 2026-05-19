-- ─────────────────────────────────────────────
-- 3A. Impact of promotions on sales
SELECT
    "Promo",
    COUNT(*)                AS num_days,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers
FROM sales
GROUP BY "Promo"
ORDER BY "Promo";

-- 3B. Promo lift by store type
SELECT
    "StoreType",
    ROUND(AVG("Sales") FILTER (WHERE "Promo" = 1)) AS avg_sales_with_promo,
    ROUND(AVG("Sales") FILTER (WHERE "Promo" = 0)) AS avg_sales_no_promo,
    ROUND(
        100.0 *
        (AVG("Sales") FILTER (WHERE "Promo" = 1) -
         AVG("Sales") FILTER (WHERE "Promo" = 0))
        / AVG("Sales") FILTER (WHERE "Promo" = 0)
    , 2)                    AS promo_lift_pct
FROM sales
GROUP BY "StoreType"
ORDER BY promo_lift_pct DESC;

-- 3C. State holiday effect
SELECT
    "StateHoliday",
    CASE "StateHoliday"
        WHEN '0' THEN 'No holiday'
        WHEN 'a' THEN 'Public holiday'
        WHEN 'b' THEN 'Easter'
        WHEN 'c' THEN 'Christmas'
    END                     AS holiday_type,
    COUNT(*)                AS num_days,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers
FROM sales
GROUP BY "StateHoliday"
ORDER BY avg_sales DESC;

-- 3D. School holiday effect
SELECT
    "SchoolHoliday",
    COUNT(*)                AS num_days,
    ROUND(AVG("Sales"))     AS avg_sales,
    ROUND(AVG("Customers")) AS avg_customers
FROM sales
GROUP BY "SchoolHoliday"
ORDER BY "SchoolHoliday";