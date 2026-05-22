-- Correlation of each feature with Sales
-- Tells us which features are most predictive before modelling
WITH sample AS (
    SELECT *
    FROM v_features
    WHERE lag_7 IS NOT NULL
      AND lag_14 IS NOT NULL
)
SELECT
    'lag_7'             AS feature,
    ROUND(CORR("Sales", lag_7)::NUMERIC,          4) AS correlation_with_sales
FROM sample
UNION ALL
SELECT 'lag_14',
    ROUND(CORR("Sales", lag_14)::NUMERIC,         4) FROM sample
UNION ALL
SELECT 'lag_28',
    ROUND(CORR("Sales", lag_28)::NUMERIC,         4) FROM sample WHERE lag_28 IS NOT NULL
UNION ALL
SELECT 'rolling_avg_7d',
    ROUND(CORR("Sales", rolling_avg_7d)::NUMERIC, 4) FROM sample
UNION ALL
SELECT 'rolling_avg_28d',
    ROUND(CORR("Sales", rolling_avg_28d)::NUMERIC,4) FROM sample
UNION ALL
SELECT 'is_promo',
    ROUND(CORR("Sales", is_promo)::NUMERIC,       4) FROM sample
UNION ALL
SELECT 'competition_distance',
    ROUND(CORR("Sales", competition_distance)::NUMERIC, 4) FROM sample
UNION ALL
SELECT 'is_school_holiday',
    ROUND(CORR("Sales", is_school_holiday)::NUMERIC, 4) FROM sample
UNION ALL
SELECT 'month_sin',
    ROUND(CORR("Sales", month_sin)::NUMERIC,      4) FROM sample
UNION ALL
SELECT 'month_cos',
    ROUND(CORR("Sales", month_cos)::NUMERIC,      4) FROM sample
UNION ALL
SELECT 'dow_sin',
    ROUND(CORR("Sales", dow_sin)::NUMERIC,        4) FROM sample
UNION ALL
SELECT 'dow_cos',
    ROUND(CORR("Sales", dow_cos)::NUMERIC,        4) FROM sample
UNION ALL
SELECT 'is_december',
    ROUND(CORR("Sales", is_december)::NUMERIC,    4) FROM sample
UNION ALL
SELECT 'is_weekend',
    ROUND(CORR("Sales", is_weekend)::NUMERIC,     4) FROM sample
UNION ALL
SELECT 'store_type_b',
    ROUND(CORR("Sales", store_type_b)::NUMERIC,   4) FROM sample
ORDER BY ABS(correlation_with_sales) DESC;