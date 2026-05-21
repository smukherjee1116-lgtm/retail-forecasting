-- Cohort analysis: stores grouped by when they first ran a promotion
-- Shows whether early adopters of promotions perform better long term
WITH store_first_promo AS (
    SELECT
        "Store",
        "StoreType",
        MIN(CASE WHEN "Promo" = 1 THEN "Date" END) AS first_promo_date,
        MIN("Date")                                  AS first_trading_date
    FROM sales
    GROUP BY "Store", "StoreType"
),
store_cohort AS (
    SELECT
        "Store",
        "StoreType",
        first_trading_date,
        first_promo_date,
        CASE
            WHEN first_promo_date IS NULL THEN 'Never promoted'
            WHEN EXTRACT(MONTH FROM first_promo_date) <= 3
             AND EXTRACT(YEAR  FROM first_promo_date) = 2013
                                          THEN 'Early adopter (Q1 2013)'
            WHEN EXTRACT(YEAR  FROM first_promo_date) = 2013
                                          THEN 'Mid adopter (2013)'
            ELSE                               'Late adopter (2014+)'
        END AS promo_cohort
    FROM store_first_promo
),
cohort_performance AS (
    SELECT
        c.promo_cohort,
        c."StoreType",
        COUNT(DISTINCT s."Store")        AS num_stores,
        ROUND(AVG(s."Sales"))            AS avg_daily_sales,
        ROUND(AVG(s."Customers"))        AS avg_daily_customers,
        ROUND(AVG(s."Sales"::NUMERIC /
              NULLIF(s."Customers",0)),2) AS sales_per_customer,
        SUM(s."Sales")                   AS total_sales
    FROM sales s
    JOIN store_cohort c ON s."Store" = c."Store"
    GROUP BY c.promo_cohort, c."StoreType"
)
SELECT
    promo_cohort,
    "StoreType",
    num_stores,
    avg_daily_sales,
    avg_daily_customers,
    sales_per_customer,
    -- Rank cohorts within each store type
    DENSE_RANK() OVER (
        PARTITION BY "StoreType"
        ORDER BY avg_daily_sales DESC
    ) AS cohort_rank
FROM cohort_performance
ORDER BY "StoreType", cohort_rank;