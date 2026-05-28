-- Just list all views without row counts
SELECT
    viewname                        AS view_name,
    CASE
        WHEN viewname LIKE 'v_inventory%'  THEN 'Inventory'
        WHEN viewname LIKE 'v_forecast%'   THEN 'Forecasting'
        WHEN viewname LIKE 'v_final%'      THEN 'Forecasting'
        WHEN viewname LIKE 'v_ensemble%'   THEN 'Forecasting'
        WHEN viewname LIKE 'v_model%'      THEN 'Evaluation'
        WHEN viewname LIKE 'v_store%'      THEN 'Store Analytics'
        WHEN viewname LIKE 'v_monthly%'    THEN 'Time Series'
        WHEN viewname LIKE 'v_sales%'      THEN 'Sales Analytics'
        WHEN viewname LIKE 'v_promo%'      THEN 'Marketing'
        WHEN viewname LIKE 'v_ma%'         THEN 'Forecasting'
        WHEN viewname LIKE 'v_trend%'      THEN 'Forecasting'
        WHEN viewname LIKE 'v_ts%'         THEN 'Forecasting'
        WHEN viewname LIKE 'v_train%'      THEN 'Forecasting'
        WHEN viewname LIKE 'v_test%'       THEN 'Forecasting'
        WHEN viewname LIKE 'v_features%'   THEN 'Feature Engineering'
        WHEN viewname LIKE 'v_dashboard%'  THEN 'Dashboard'
        WHEN viewname LIKE 'v_reorder%'    THEN 'Inventory'
        WHEN viewname LIKE 'v_time%'       THEN 'Time Series'
        WHEN viewname LIKE 'v_seasonal%'   THEN 'Time Series'
        ELSE                                    'Other'
    END                             AS category
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'v_%'
ORDER BY category, viewname;