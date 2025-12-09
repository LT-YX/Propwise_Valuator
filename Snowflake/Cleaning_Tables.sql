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


-- The below is done by Joely
USE SCHEMA CLEANED_DATA;

-- 4. Create Cleaned Table by parsing GeoJSON properties and geometry
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_Existing_Building_Cleaned AS
SELECT
    -- Extract property attributes using :: operator
    raw_data:properties:OBJECTID::INTEGER AS object_id,
    raw_data:properties:BLK_NO::STRING AS block_no,
    raw_data:properties:ST_COD::STRING AS street_code,
    raw_data:properties:ENTITYID::INTEGER AS entity_id,
    raw_data:properties:POSTAL_COD::STRING AS postal_code,
    raw_data:properties:INC_CRC::STRING AS inc_crc,
    raw_data:properties:FMEL_UPD_D::STRING AS last_updated,
    
    -- For numeric fields, cast to STRING first, then to NUMBER
    TRY_TO_NUMBER(raw_data:properties:"SHAPE.AREA"::STRING) AS shape_area,
    TRY_TO_NUMBER(raw_data:properties:"SHAPE.LEN"::STRING) AS shape_length,
    
    -- Store geometry as GEOGRAPHY type for spatial analysis
    TO_GEOGRAPHY(raw_data:geometry) AS geometry,
    
    -- Keep geometry type for reference
    raw_data:geometry:type::STRING AS geometry_type
FROM RAW_DATA.HDB_Existing_Building;

-- 5. Verify cleaned data
SELECT COUNT(*) FROM CLEANED_DATA.HDB_Existing_Building_Cleaned;

-- Check for any null postal codes or block numbers (data quality check)
SELECT 
    COUNT(*) AS total_records,
    COUNT(block_no) AS blocks_with_data,
    COUNT(postal_code) AS postal_codes_with_data
FROM CLEANED_DATA.HDB_Existing_Building_Cleaned;






