-- Running totals and cumulative metrics by store
-- Shows how sales accumulate over time — useful for target tracking
WITH monthly_store AS (
    SELECT
        "Store",
        "StoreType",
        year,
        month,
        month_name,
        SUM("Sales")        AS monthly_sales,
        SUM("Customers")    AS monthly_customers,
        COUNT(*)            AS trading_days
    FROM sales
    GROUP BY "Store", "StoreType", year, month, month_name
)
SELECT
    "Store",
    "StoreType",
    year,
    month,
    month_name,
    monthly_sales,
    trading_days,
    -- Running total within each store
    SUM(monthly_sales) OVER (
        PARTITION BY "Store"
        ORDER BY year, month
        ROWS UNBOUNDED PRECEDING
    )                               AS cumulative_sales,
    -- Running total within each store type
    SUM(monthly_sales) OVER (
        PARTITION BY "StoreType", year
        ORDER BY month
        ROWS UNBOUNDED PRECEDING
    )                               AS cumulative_sales_by_type,
    -- Month over month growth per store
    monthly_sales - LAG(monthly_sales) OVER (
        PARTITION BY "Store"
        ORDER BY year, month
    )                               AS mom_sales_change,
    ROUND(100.0 * (
        monthly_sales - LAG(monthly_sales) OVER (
            PARTITION BY "Store"
            ORDER BY year, month
        )
    ) / NULLIF(LAG(monthly_sales) OVER (
            PARTITION BY "Store"
            ORDER BY year, month
    ), 0), 1)                       AS mom_growth_pct
FROM monthly_store
WHERE "Store" IN (1, 2, 3)   -- sample 3 stores for readability
ORDER BY "Store", year, month;