SELECT 'raw_train' AS table_name, COUNT(*) AS row_count FROM raw_train
UNION ALL
SELECT 'raw_store',               COUNT(*)               FROM raw_store
UNION ALL
SELECT 'raw_test',                COUNT(*)               FROM raw_test;