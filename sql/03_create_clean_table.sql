DROP TABLE IF EXISTS sales CASCADE;

CREATE TABLE sales AS
SELECT
    t."Store",
    t."Date",
    t."DayOfWeek",
    t."Sales",
    t."Customers",
    t."Promo",
    t."StateHoliday",
    t."SchoolHoliday",

    -- Store metadata
    s."StoreType",
    s."Assortment",
    s."Promo2",

    -- Impute missing CompetitionDistance with median
    COALESCE(
        s."CompetitionDistance",
        (SELECT PERCENTILE_CONT(0.5)
                WITHIN GROUP (ORDER BY "CompetitionDistance")
         FROM raw_store
         WHERE "CompetitionDistance" IS NOT NULL)
    ) AS competition_distance,

    COALESCE(s."CompetitionOpenSinceMonth", 0) AS competition_open_since_month,
    COALESCE(s."CompetitionOpenSinceYear",  0) AS competition_open_since_year,
    COALESCE(s."Promo2SinceWeek",           0) AS promo2_since_week,
    COALESCE(s."Promo2SinceYear",           0) AS promo2_since_year,
    COALESCE(s."PromoInterval",            '0') AS promo_interval,

    -- Extract date parts for EDA and modelling
    EXTRACT(YEAR  FROM t."Date")::INTEGER AS year,
    EXTRACT(MONTH FROM t."Date")::INTEGER AS month,
    EXTRACT(DAY   FROM t."Date")::INTEGER AS day,
    TO_CHAR(t."Date", 'Mon')              AS month_name,
    EXTRACT(WEEK  FROM t."Date")::INTEGER AS week_of_year,
    TO_CHAR(t."Date", 'Day')              AS day_name

FROM raw_train t
JOIN raw_store s ON t."Store" = s."Store"

-- Remove closed store days
WHERE t."Open" = 1
  AND t."Sales" > 0;

-- Primary key
ALTER TABLE sales ADD COLUMN id SERIAL PRIMARY KEY;

-- Indexes for fast querying
CREATE INDEX idx_sales_store ON sales("Store");
CREATE INDEX idx_sales_date  ON sales("Date");
CREATE INDEX idx_sales_year  ON sales(year);
CREATE INDEX idx_sales_month ON sales(month);

SELECT 'sales table created: ' || COUNT(*) || ' rows' AS status FROM sales;