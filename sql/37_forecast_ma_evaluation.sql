-- Evaluate all moving average models on the test set
-- RMSE, MAE, MAPE for each model
WITH test_forecasts AS (
    SELECT *
    FROM v_ma_forecast
    WHERE split = 'test'
      AND ma_7   IS NOT NULL
      AND ma_14  IS NOT NULL
      AND ma_28  IS NOT NULL
      AND wma_28 IS NOT NULL
      AND dow_avg IS NOT NULL
)
SELECT
    -- MA 7
    'MA_7'                              AS model,
    COUNT(*)                            AS test_rows,
    ROUND(SQRT(AVG(
        POWER(error_ma7, 2)
    ))::NUMERIC)                        AS rmse,
    ROUND(AVG(
        ABS(error_ma7)
    )::NUMERIC)                         AS mae,
    ROUND(AVG(
        ABS(error_ma7::NUMERIC /
        NULLIF(actual_sales, 0)) * 100
    )::NUMERIC, 2)                      AS mape,
    ROUND(AVG(error_ma7)::NUMERIC)      AS mean_bias

FROM test_forecasts

UNION ALL

SELECT
    'MA_14',
    COUNT(*),
    ROUND(SQRT(AVG(POWER(error_ma14,2)))::NUMERIC),
    ROUND(AVG(ABS(error_ma14))::NUMERIC),
    ROUND(AVG(ABS(error_ma14::NUMERIC /
        NULLIF(actual_sales,0))*100)::NUMERIC, 2),
    ROUND(AVG(error_ma14)::NUMERIC)
FROM test_forecasts

UNION ALL

SELECT
    'MA_28',
    COUNT(*),
    ROUND(SQRT(AVG(POWER(error_ma28,2)))::NUMERIC),
    ROUND(AVG(ABS(error_ma28))::NUMERIC),
    ROUND(AVG(ABS(error_ma28::NUMERIC /
        NULLIF(actual_sales,0))*100)::NUMERIC, 2),
    ROUND(AVG(error_ma28)::NUMERIC)
FROM test_forecasts

UNION ALL

SELECT
    'WMA_28',
    COUNT(*),
    ROUND(SQRT(AVG(POWER(error_wma28,2)))::NUMERIC),
    ROUND(AVG(ABS(error_wma28))::NUMERIC),
    ROUND(AVG(ABS(error_wma28::NUMERIC /
        NULLIF(actual_sales,0))*100)::NUMERIC, 2),
    ROUND(AVG(error_wma28)::NUMERIC)
FROM test_forecasts

UNION ALL

SELECT
    'DOW_AVG',
    COUNT(*),
    ROUND(SQRT(AVG(POWER(error_dow,2)))::NUMERIC),
    ROUND(AVG(ABS(error_dow))::NUMERIC),
    ROUND(AVG(ABS(error_dow::NUMERIC /
        NULLIF(actual_sales,0))*100)::NUMERIC, 2),
    ROUND(AVG(error_dow)::NUMERIC)
FROM test_forecasts

ORDER BY rmse;