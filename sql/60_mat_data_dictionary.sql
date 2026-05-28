-- Data dictionary: documents every table and view
-- Professional touch for GitHub README and portfolio
SELECT
    't_final_forecast'          AS object_name,
    'Table'                     AS object_type,
    'Daily forecast results for all 1115 stores.
     Contains actual sales, ensemble forecast,
     confidence intervals and error metrics.'  AS description,
    '828,728'                   AS approx_rows,
    'Store, Date'               AS key_columns,
    'Streamlit dashboard - Forecast tab'
                                AS used_by
UNION ALL
SELECT
    't_store_summary',
    'Table',
    'One row per store with forecast quality,
     inventory levels, alert status and
     historical performance metrics.',
    '1,115',
    'Store',
    'Streamlit dashboard - Store Analysis tab'
UNION ALL
SELECT
    't_monthly_forecast',
    'Table',
    'Monthly aggregated forecasts per store.
     Used for trend charts and monthly KPI cards.',
    '34,000',
    'Store, year, month',
    'Streamlit dashboard - Trends tab'
UNION ALL
SELECT
    't_kpi_summary',
    'Table',
    'Single-row KPI table for dashboard home page.
     Pre-computed metrics updated on each run.',
    '1',
    'N/A',
    'Streamlit dashboard - Home tab'
UNION ALL
SELECT
    'v_model_scorecard',
    'View',
    'Model comparison: DOW_AVG vs Trend+Seasonal
     vs Ensemble. RMSE, MAE, MAPE, bias, coverage.',
    '3',
    'model',
    'Streamlit dashboard - Model tab'
UNION ALL
SELECT
    'v_store_performance',
    'View',
    'Store rankings by total sales, avg sales,
     efficiency. Includes DENSE_RANK and percentile.',
    '1,115',
    'Store',
    'Streamlit dashboard - Store Analysis tab'
UNION ALL
SELECT
    'v_monthly_sales',
    'View',
    'Monthly sales aggregation across all stores.
     Used for year-over-year comparison charts.',
    '31',
    'year, month',
    'Streamlit dashboard - Trends tab'
UNION ALL
SELECT
    'v_inventory_intelligence',
    'View',
    'Safety stock, reorder points, EOQ and
     volatility scores per store.',
    '1,115',
    'Store',
    'Streamlit dashboard - Inventory tab'
UNION ALL
SELECT
    'v_promo_effectiveness',
    'View',
    'Promo lift % by store type and assortment.
     Shows which store segments respond best.',
    '9',
    'StoreType, Assortment',
    'Streamlit dashboard - EDA tab'
UNION ALL
SELECT
    'v_dashboard_summary',
    'View',
    'Single-row overall summary: revenue, stores,
     promo stats, store type breakdown by year.',
    '1',
    'N/A',
    'Streamlit dashboard - Home tab'
UNION ALL
SELECT
    'sales',
    'Table',
    'Core cleaned sales table. 844K rows of daily
     sales per store with store metadata merged in.',
    '844,338',
    'Store, Date',
    'Source for all views and models'
UNION ALL
SELECT
    'raw_train',
    'Table',
    'Raw Rossmann train.csv loaded directly.
     1M rows before cleaning.',
    '1,017,209',
    'Store, Date',
    'Ingestion layer'
UNION ALL
SELECT
    'raw_store',
    'Table',
    'Raw store metadata from store.csv.',
    '1,115',
    'Store',
    'Ingestion layer'
ORDER BY
    CASE object_type
        WHEN 'Table' THEN 1
        WHEN 'View'  THEN 2
    END,
    object_name;