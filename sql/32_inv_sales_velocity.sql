-- Sales velocity scoring per store
-- Velocity = how fast a store sells relative to its peers
-- Used for dynamic reorder triggering in the dashboard
CREATE OR REPLACE VIEW v_sales_velocity AS
WITH daily_store AS (
    SELECT
        "Store",
        "Date",
        "Sales",
        "Customers",
        "Promo",
        year,
        month,
        "DayOfWeek",
        -- 7-day trailing average (excludes current day)
        AVG("Sales") OVER (
            PARTITION BY "Store"
            ORDER BY "Date"
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        )                               AS trailing_7d_avg,
        -- 28-day trailing average
        AVG("Sales") OVER (
            PARTITION BY "Store"
            ORDER BY "Date"
            ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING
        )                               AS trailing_28d_avg
    FROM sales
),
velocity_scored AS (
    SELECT
        "Store",
        "Date",
        "Sales",
        "Customers",
        "Promo",
        year,
        month,
        ROUND(trailing_7d_avg::NUMERIC)  AS trailing_7d_avg,
        ROUND(trailing_28d_avg::NUMERIC) AS trailing_28d_avg,

        -- Velocity ratio: current vs recent average
        ROUND(("Sales"::NUMERIC /
            NULLIF(trailing_7d_avg, 0)), 2)  AS velocity_ratio_7d,
        ROUND(("Sales"::NUMERIC /
            NULLIF(trailing_28d_avg, 0)), 2) AS velocity_ratio_28d,

        -- Acceleration: is velocity increasing?
        ROUND((trailing_7d_avg -
            trailing_28d_avg)::NUMERIC /
            NULLIF(trailing_28d_avg, 0)
            * 100, 1)                    AS acceleration_pct,

        -- Percentile rank on this day
        ROUND((PERCENT_RANK() OVER (
            PARTITION BY "Date"
            ORDER BY "Sales"
        ) * 100)::NUMERIC, 1)            AS daily_percentile
    FROM daily_store
    WHERE trailing_7d_avg IS NOT NULL
)
SELECT
    *,
    -- Velocity classification
    CASE
        WHEN velocity_ratio_7d >= 1.3  THEN 'Surging'
        WHEN velocity_ratio_7d >= 1.1  THEN 'Above trend'
        WHEN velocity_ratio_7d >= 0.9  THEN 'On trend'
        WHEN velocity_ratio_7d >= 0.7  THEN 'Below trend'
        ELSE                                'Declining'
    END                                  AS velocity_status,

    -- Reorder urgency flag
    CASE
        WHEN velocity_ratio_7d >= 1.2
         AND "Promo" = 1               THEN 'Urgent reorder'
        WHEN velocity_ratio_7d >= 1.1  THEN 'Monitor closely'
        WHEN velocity_ratio_7d <= 0.8  THEN 'Reduce order'
        ELSE                                'Normal'
    END                                  AS reorder_action

FROM velocity_scored
ORDER BY "Store", "Date";

-- Summary: velocity distribution
SELECT
    velocity_status,
    reorder_action,
    COUNT(*)                            AS num_observations,
    ROUND(AVG("Sales"))                 AS avg_sales,
    ROUND(AVG(velocity_ratio_7d)::NUMERIC, 2) AS avg_velocity
FROM v_sales_velocity
GROUP BY velocity_status, reorder_action
ORDER BY avg_velocity DESC;