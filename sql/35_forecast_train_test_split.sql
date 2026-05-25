-- Create train and test tables
-- Train: Jan 2013 - Dec 2014 (2 full years)
-- Test : Jan 2015 - Jul 2015 (7 months holdout)
CREATE OR REPLACE VIEW v_train AS
SELECT *
FROM v_forecast_ready
WHERE "Date" < '2015-01-01'
  AND "Store" = 1;

CREATE OR REPLACE VIEW v_test AS
SELECT *
FROM v_forecast_ready
WHERE "Date" >= '2015-01-01'
  AND "Store" = 1;

-- Verify split
SELECT 'TRAIN' AS split,
    COUNT(*)        AS rows,
    MIN("Date")     AS date_from,
    MAX("Date")     AS date_to,
    ROUND(AVG(actual_sales)) AS avg_sales
FROM v_train
UNION ALL
SELECT 'TEST',
    COUNT(*),
    MIN("Date"),
    MAX("Date"),
    ROUND(AVG(actual_sales))
FROM v_test;