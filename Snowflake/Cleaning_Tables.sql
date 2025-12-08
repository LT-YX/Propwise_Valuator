USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;

-- Cleaning HDB_Price_Range - Lv
--   Create Table for Cleaning in Cleaned Data Schema
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_Price_Range AS
SELECT * FROM RAW_DATA.HDB_Price_Range;

--   Drop Irrelevant Columns
ALTER TABLE CLEANED_DATA.HDB_PRICE_RANGE
DROP COLUMN MIN_SELLING_PRICE_LESS_AHG_SHG, MAX_SELLING_PRICE_LESS_AHG_SHG;

--   Change Data Types to more suitable ones
DELETE FROM CLEANED_DATA.HDB_PRICE_RANGE
WHERE REGEXP_LIKE(MIN_SELLING_PRICE, '^-+$')
   OR REGEXP_LIKE(MAX_SELLING_PRICE, '^-+$');
--   5 rows were deleted

CREATE OR REPLACE TABLE CLEANED_DATA.HDB_PRICE_RANGE AS
SELECT
    financial_year,
    town,
    room_type,
    TRY_TO_NUMBER(MIN_SELLING_PRICE) AS min_selling_price,
    TRY_TO_NUMBER(MAX_SELLING_PRICE) AS max_selling_price,
FROM CLEANED_DATA.HDB_PRICE_RANGE;


-- Antozesslyn
-- Data Cleaning and Final Table Creation
-- Create the Cleaned Table
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.Resale_Flat_Prices_Cleaned AS
SELECT
    -- Convert 'month' (e.g., '2015-01') to a DATE type
    TRY_TO_DATE(month, 'YYYY-MM') AS sale_date,

    -- Retain key location/property features
    town,
    flat_type,
    block,
    street_name,
    storey_range,
    flat_model,

    -- Convert numerical fields using TRY_TO_NUMBER for error handling
    TRY_TO_NUMBER(floor_area_sqm) AS floor_area_sqm,
    TRY_TO_NUMBER(lease_commence_date) AS lease_commence_year,
    TRY_TO_NUMBER(resale_price) AS resale_price,

    -- Feature Engineering: Extracting approximate remaining lease in years as a float
    -- This handles strings like '60 years 05 months' and '70' (for older data)
    -- The formula extracts years and months/12
    COALESCE(
        TRY_TO_NUMBER(SPLIT_PART(remaining_lease, ' years', 1)),
        TRY_TO_NUMBER(remaining_lease) -- Handle cases where it's just a number
    ) +
    COALESCE(
        (TRY_TO_NUMBER(SPLIT_PART(SPLIT_PART(remaining_lease, ' months', 1), ' ', -1)) / 12),
        0
    ) AS remaining_lease_years_float

FROM RAW_DATA.Resale_Flat_Prices


-- Create the Final Joined/Consolidated Table
-- Since the files were combined in the RAW stage, this step is for final feature selection/view
USE SCHEMA FINAL_DATA;

CREATE OR REPLACE VIEW FINAL_DATA.MASTER_RESALE_DATA AS
SELECT
    sale_date,
    town,
    flat_type,
    floor_area_sqm,
    resale_price,
    lease_commence_year,
    remaining_lease_years_float,
    storey_range,
    flat_model,
    block,
    street_name
FROM CLEANED_DATA.Resale_Flat_Prices_Cleaned;


--







