-- Rolling average features per store
-- Captures short and medium term momentum
SELECT
    "Store",
    "Date",
    "Sales",

    -- Short term momentum
    ROUND(AVG("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
    )) AS rolling_avg_7d,

    -- Medium term momentum
    ROUND(AVG("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 13 PRECEDING AND 1 PRECEDING
    )) AS rolling_avg_14d,

    ROUND(AVG("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
    )) AS rolling_avg_28d,

    -- Rolling standard deviation (captures volatility)
    ROUND(STDDEV("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
    )) AS rolling_std_28d,

    -- Rolling max and min (captures range)
    MAX("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
    ) AS rolling_max_28d,

    MIN("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
    ) AS rolling_min_28d,

    -- Sales momentum: current vs 28d average
    ROUND("Sales" - AVG("Sales") OVER (
        PARTITION BY "Store" ORDER BY "Date"
        ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
    )) AS momentum_28d

FROM sales
WHERE "Store" = 1
ORDER BY "Date";