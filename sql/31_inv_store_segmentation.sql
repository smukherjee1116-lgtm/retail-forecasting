-- Store segmentation using RFM-style scoring
-- Recency = how recently did sales peak
-- Frequency = how many promo days
-- Monetary = total revenue
CREATE OR REPLACE VIEW v_store_segmentation AS
WITH store_metrics AS (
    SELECT
        "Store",
        "StoreType",
        "Assortment",
        competition_distance,

        -- Monetary: total and avg sales
        SUM("Sales")                    AS total_sales,
        ROUND(AVG("Sales"))             AS avg_daily_sales,

        -- Frequency: promo engagement
        COUNT(*) FILTER
            (WHERE "Promo" = 1)         AS promo_days,
        COUNT(*)                        AS total_days,
        ROUND(100.0 *
            COUNT(*) FILTER (WHERE "Promo"=1)
            / COUNT(*), 1)              AS promo_day_pct,

        -- Volatility
        ROUND(STDDEV("Sales")::NUMERIC) AS sales_stddev,
        ROUND((100.0 * STDDEV("Sales")
            / NULLIF(AVG("Sales"),0))::NUMERIC,
            1)                          AS cv_pct,

        -- Growth: compare first half vs second half of data
        ROUND(AVG("Sales") FILTER (
            WHERE "Date" >= '2014-07-01')::NUMERIC)
                                        AS avg_sales_recent,
        ROUND(AVG("Sales") FILTER (
            WHERE "Date" <  '2014-07-01')::NUMERIC)
                                        AS avg_sales_early,

        -- Customer metrics
        ROUND(AVG("Customers"))         AS avg_customers,
        ROUND(AVG("Sales"::NUMERIC /
            NULLIF("Customers",0)), 2)  AS sales_per_customer

    FROM sales
    GROUP BY "Store","StoreType",
             "Assortment",competition_distance
),
scored AS (
    SELECT
        *,
        -- Growth rate
        ROUND(((avg_sales_recent - avg_sales_early)
            * 100.0
            / NULLIF(avg_sales_early,0))::NUMERIC,
            1)                          AS growth_pct,

        -- Percentile ranks for scoring
        NTILE(4) OVER (
            ORDER BY avg_daily_sales)   AS sales_quartile,
        NTILE(4) OVER (
            ORDER BY promo_day_pct)     AS promo_quartile,
        NTILE(4) OVER (
            ORDER BY cv_pct DESC)       AS stability_quartile
    FROM store_metrics
)
SELECT
    *,
    -- Composite score (1-12, higher = better)
    (sales_quartile + promo_quartile + stability_quartile)
                                        AS composite_score,
    -- Segment label
    CASE
        WHEN sales_quartile = 4
         AND stability_quartile >= 3    THEN 'Star'
        WHEN sales_quartile = 4        THEN 'High Volume'
        WHEN stability_quartile = 4
         AND sales_quartile >= 3       THEN 'Reliable'
        WHEN sales_quartile <= 2
         AND stability_quartile <= 2   THEN 'At Risk'
        WHEN promo_quartile = 4        THEN 'Promo Driven'
        ELSE                                'Core'
    END                                 AS store_segment
FROM scored
ORDER BY composite_score DESC,
         avg_daily_sales DESC;

-- Summary by segment
SELECT
    store_segment,
    COUNT(*)                            AS num_stores,
    ROUND(AVG(avg_daily_sales))         AS avg_daily_sales,
    ROUND(AVG(growth_pct)::NUMERIC, 1)  AS avg_growth_pct,
    ROUND(AVG(cv_pct)::NUMERIC, 1)      AS avg_cv_pct,
    ROUND(AVG(promo_day_pct)::NUMERIC,1)AS avg_promo_day_pct
FROM (SELECT * FROM v_store_segmentation) t
GROUP BY store_segment
ORDER BY avg_daily_sales DESC;