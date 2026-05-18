DROP TABLE IF EXISTS raw_train CASCADE;
DROP TABLE IF EXISTS raw_store CASCADE;
DROP TABLE IF EXISTS raw_test  CASCADE;

CREATE TABLE raw_train (
    "Store"         INTEGER,
    "DayOfWeek"     INTEGER,
    "Date"          DATE,
    "Sales"         INTEGER,
    "Customers"     INTEGER,
    "Open"          SMALLINT,
    "Promo"         SMALLINT,
    "StateHoliday"  VARCHAR(5),
    "SchoolHoliday" SMALLINT
);

CREATE TABLE raw_store (
    "Store"                      INTEGER,
    "StoreType"                  VARCHAR(5),
    "Assortment"                 VARCHAR(5),
    "CompetitionDistance"        NUMERIC,
    "CompetitionOpenSinceMonth"  NUMERIC,
    "CompetitionOpenSinceYear"   NUMERIC,
    "Promo2"                     SMALLINT,
    "Promo2SinceWeek"            NUMERIC,
    "Promo2SinceYear"            NUMERIC,
    "PromoInterval"              VARCHAR(30)
);

CREATE TABLE raw_test (
    "Id"            INTEGER,
    "Store"         INTEGER,
    "DayOfWeek"     INTEGER,
    "Date"          DATE,
    "Open"          SMALLINT,
    "Promo"         SMALLINT,
    "StateHoliday"  VARCHAR(5),
    "SchoolHoliday" SMALLINT
);

SELECT 'Tables created successfully' AS status;