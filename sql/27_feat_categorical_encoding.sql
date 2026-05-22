-- Encode categorical variables as numeric features
-- XGBoost needs numbers, not strings
SELECT
    "Store",
    "Date",
    "Sales",
    "StoreType",
    "Assortment",
    "StateHoliday",

    -- One-hot encode StoreType
    CASE WHEN "StoreType" = 'a' THEN 1 ELSE 0 END AS store_type_a,
    CASE WHEN "StoreType" = 'b' THEN 1 ELSE 0 END AS store_type_b,
    CASE WHEN "StoreType" = 'c' THEN 1 ELSE 0 END AS store_type_c,
    CASE WHEN "StoreType" = 'd' THEN 1 ELSE 0 END AS store_type_d,

    -- One-hot encode Assortment
    CASE WHEN "Assortment" = 'a' THEN 1 ELSE 0 END AS assortment_a,
    CASE WHEN "Assortment" = 'b' THEN 1 ELSE 0 END AS assortment_b,
    CASE WHEN "Assortment" = 'c' THEN 1 ELSE 0 END AS assortment_c,

    -- Encode StateHoliday
    CASE WHEN "StateHoliday" = '0' THEN 0
         WHEN "StateHoliday" = 'a' THEN 1
         WHEN "StateHoliday" = 'b' THEN 2
         WHEN "StateHoliday" = 'c' THEN 3
    END AS state_holiday_encoded,

    -- Binary flags
    "Promo"         AS is_promo,
    "SchoolHoliday" AS is_school_holiday,
    "Promo2"        AS is_promo2,

    -- Competition distance buckets (ordinal encoding)
    CASE
        WHEN competition_distance < 500   THEN 1
        WHEN competition_distance < 1000  THEN 2
        WHEN competition_distance < 5000  THEN 3
        WHEN competition_distance < 10000 THEN 4
        ELSE                                   5
    END AS competition_bucket,

    -- Cyclical encoding of month (preserves Jan-Dec continuity)
    ROUND(SIN(2 * PI() * month / 12.0)::NUMERIC, 4) AS month_sin,
    ROUND(COS(2 * PI() * month / 12.0)::NUMERIC, 4) AS month_cos,

    -- Cyclical encoding of day of week
    ROUND(SIN(2 * PI() * "DayOfWeek" / 7.0)::NUMERIC, 4) AS dow_sin,
    ROUND(COS(2 * PI() * "DayOfWeek" / 7.0)::NUMERIC, 4) AS dow_cos,

    -- Raw numeric features
    year,
    month,
    day,
    week_of_year,
    "DayOfWeek",
    competition_distance

FROM sales
WHERE "Store" = 1
ORDER BY "Date"
LIMIT 20;