-- Moving Average Forecast
-- Strategy: use the last 7, 14, and 28 days average
-- as the forecast for the next day
-- We compute this on the TEST set using TRAIN data as history

CREATE OR REPLACE VIEW v_ma_forecast AS
WITH combined AS (
    SELECT
        "Date",
        actual_sales,
        'train'     AS split
    FROM v_train
    UNION ALL
    SELECT
        "Date",
        actual_sales,
        'test'
    FROM v_test
),
with_ma AS (
    SELECT
        "Date",
        actual_sales,
        split,

        -- 7-day moving average (excludes current)
        ROUND(AVG(actual_sales) OVER (
            ORDER BY "Date"
            ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
        ))                              AS ma_7,

        -- 14-day moving average
        ROUND(AVG(actual_sales) OVER (
            ORDER BY "Date"
            ROWS BETWEEN 14 PRECEDING AND 1 PRECEDING
        ))                              AS ma_14,

        -- 28-day moving average
        ROUND(AVG(actual_sales) OVER (
            ORDER BY "Date"
            ROWS BETWEEN 28 PRECEDING AND 1 PRECEDING
        ))                              AS ma_28,

        -- Weighted moving average (recent days weighted more)
        -- Weights: last 7 days = 3x, 8-14 days = 2x, 15-28 days = 1x
        ROUND((
            AVG(actual_sales) OVER (
                ORDER BY "Date"
                ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
            ) * 3
            + AVG(actual_sales) OVER (
                ORDER BY "Date"
                ROWS BETWEEN 14 PRECEDING AND 8 PRECEDING
            ) * 2
            + AVG(actual_sales) OVER (
                ORDER BY "Date"
                ROWS BETWEEN 28 PRECEDING AND 15 PRECEDING
            ) * 1
        ) / 6)                          AS wma_28,

        -- Day of week average from training period
        -- (seasonal naive component)
        AVG(actual_sales) OVER (
            PARTITION BY
                EXTRACT(DOW FROM "Date")::INTEGER
            ORDER BY "Date"
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND 1 PRECEDING
        )                               AS dow_avg

    FROM combined
)
SELECT
    "Date",
    actual_sales,
    split,
    ma_7,
    ma_14,
    ma_28,
    ROUND(wma_28)                       AS wma_28,
    ROUND(dow_avg)                      AS dow_avg,

    -- Errors for each model (only meaningful on test set)
    actual_sales - ma_7                 AS error_ma7,
    actual_sales - ma_14                AS error_ma14,
    actual_sales - ma_28                AS error_ma28,
    actual_sales - ROUND(wma_28)        AS error_wma28,
    actual_sales - ROUND(dow_avg)       AS error_dow

FROM with_ma
ORDER BY "Date";

-- Preview test set forecasts
SELECT
    "Date",
    actual_sales,
    ma_7,
    ma_14,
    ma_28,
    wma_28,
    dow_avg,
    error_ma7,
    error_ma14,
    error_ma28
FROM v_ma_forecast
WHERE split = 'test'
ORDER BY "Date"
LIMIT 20;