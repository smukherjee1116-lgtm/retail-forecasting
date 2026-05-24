-- Master dashboard summary view
-- Single query the Streamlit dashboard home page will call
CREATE OR REPLACE VIEW v_dashboard_summary AS
SELECT
    -- Overall KPIs
    COUNT(DISTINCT "Store")             AS total_stores,
    COUNT(*)                            AS total_trading_days,
    SUM("Sales")                        AS total_revenue,
    ROUND(AVG("Sales"))                 AS avg_daily_sales,
    MAX("Sales")                        AS max_single_day_sales,
    MIN("Date")                         AS data_from,
    MAX("Date")                         AS data_to,

    -- Promo stats
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE "Promo" = 1)
        / COUNT(*), 1)                  AS promo_day_pct,
    ROUND(AVG("Sales")
        FILTER (WHERE "Promo"=1)::NUMERIC)  AS avg_sales_on_promo,
    ROUND(AVG("Sales")
        FILTER (WHERE "Promo"=0)::NUMERIC)  AS avg_sales_off_promo,

    -- Holiday stats
    ROUND(100.0 * COUNT(*)
        FILTER (WHERE "SchoolHoliday"=1)
        / COUNT(*), 1)                  AS school_holiday_pct,

    -- Store type breakdown
    COUNT(DISTINCT "Store")
        FILTER (WHERE "StoreType"='a')  AS stores_type_a,
    COUNT(DISTINCT "Store")
        FILTER (WHERE "StoreType"='b')  AS stores_type_b,
    COUNT(DISTINCT "Store")
        FILTER (WHERE "StoreType"='c')  AS stores_type_c,
    COUNT(DISTINCT "Store")
        FILTER (WHERE "StoreType"='d')  AS stores_type_d,

    -- Performance tiers
    COUNT(DISTINCT "Store")
        FILTER (WHERE "Sales" >= 10000) AS premium_store_days,
    ROUND(STDDEV("Sales")::NUMERIC)     AS sales_std_dev,

    -- Year breakdown
    SUM("Sales")
        FILTER (WHERE year=2013)        AS revenue_2013,
    SUM("Sales")
        FILTER (WHERE year=2014)        AS revenue_2014,
    SUM("Sales")
        FILTER (WHERE year=2015)        AS revenue_2015

FROM sales;

-- Run it
SELECT * FROM v_dashboard_summary;