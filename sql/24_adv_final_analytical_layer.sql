-- Final analytical layer: one row per store per month
-- This is the master table for forecasting feature engineering (Day 5)
CREATE OR REPLACE VIEW v_store_monthly_features AS
SELECT
    s."Store",
    s."StoreType",
    s."Assortment",
    s.year,
    s.month,
    s.month_name,
    s.competition_distance,
    s."Promo2",

    -- Sales metrics
    SUM(s."Sales")                            AS monthly_sales,
    ROUND(AVG(s."Sales"))                     AS avg_daily_sales,
    ROUND(STDDEV(s."Sales"))                  AS sales_stddev,
    MAX(s."Sales")                            AS max_daily_sales,
    MIN(s."Sales")                            AS min_daily_sales,

    -- Customer metrics
    SUM(s."Customers")                        AS monthly_customers,
    ROUND(AVG(s."Customers"))                 AS avg_daily_customers,

    -- Promo metrics
    COUNT(*) FILTER (WHERE s."Promo" = 1)     AS promo_days,
    COUNT(*) FILTER (WHERE s."Promo" = 0)     AS non_promo_days,
    COUNT(*)                                  AS total_trading_days,

    -- Holiday metrics
    COUNT(*) FILTER (WHERE s."SchoolHoliday"=1) AS school_holiday_days,
    COUNT(*) FILTER (WHERE s."StateHoliday"<>'0') AS state_holiday_days,

    -- Efficiency metric
    ROUND(AVG(s."Sales"::NUMERIC /
          NULLIF(s."Customers", 0)), 2)       AS sales_per_customer,

    -- Month over month sales change (per store)
    SUM(s."Sales") - LAG(SUM(s."Sales")) OVER (
        PARTITION BY s."Store"
        ORDER BY s.year, s.month
    )                                         AS mom_sales_change,

    -- Rolling 3-month average (per store)
    ROUND(AVG(SUM(s."Sales")) OVER (
        PARTITION BY s."Store"
        ORDER BY s.year, s.month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ))                                        AS rolling_3m_avg

FROM sales s
GROUP BY
    s."Store", s."StoreType", s."Assortment",
    s.year, s.month, s.month_name,
    s.competition_distance, s."Promo2"
ORDER BY s."Store", s.year, s.month;

-- Verify
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT "Store") AS num_stores,
       COUNT(DISTINCT year || '-' || month) AS num_months
FROM v_store_monthly_features;