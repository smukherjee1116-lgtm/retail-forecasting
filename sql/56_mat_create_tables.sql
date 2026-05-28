-- Materialise heavy views into physical tables
-- This makes dashboard queries run in milliseconds
-- instead of seconds by pre-computing all joins

-- ── 1. Materialise the final forecast ────────────────────────────────────────
DROP TABLE IF EXISTS t_final_forecast;
CREATE TABLE t_final_forecast AS
SELECT
    "Store",
    "Date",
    actual_sales,
    split,
    ts_forecast,
    ma_forecast,
    ensemble_forecast,
    ts_blend_weight,
    ma_blend_weight,
    ensemble_error,
    ABS(ensemble_error)                 AS abs_error,
    ROUND(ABS(ensemble_error::NUMERIC /
        NULLIF(actual_sales,0))*100,2)  AS ape,
    ROUND((ensemble_forecast + 1.96 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS upper_95,
    ROUND((ensemble_forecast - 1.96 *
        STDDEV(ensemble_error) OVER (
            PARTITION BY "Store"
        ))::NUMERIC)                    AS lower_95
FROM v_ensemble_forecast
ORDER BY "Store", "Date";

-- Add indexes for fast dashboard queries
CREATE INDEX idx_tff_store   ON t_final_forecast("Store");
CREATE INDEX idx_tff_date    ON t_final_forecast("Date");
CREATE INDEX idx_tff_split   ON t_final_forecast(split);

SELECT 'Final forecast table' AS table_name,
       COUNT(*)               AS rows,
       COUNT(DISTINCT "Store") AS stores
FROM t_final_forecast;