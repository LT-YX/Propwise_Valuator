-- DO NOT REMOVE
USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA RAW_DATA;
-- CREATE OR REPLACE STAGE RAW_DATA.stage_raw; Has been created DO NOT run again

-- 1. Upload files to stage using Snowflake UI
-- 2. Once file has been uploaded, create table
-- 3. Load data from stage to table

CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1;

-- HDB Price Range - Lv
CREATE OR REPLACE TABLE HDB_Price_Range (
    financial_year STRING, -- Not a mathematical number
    town STRING,
    room_type STRING,
    min_selling_price STRING,
    max_selling_price STRING,
    min_selling_price_less_ahg_shg STRING, 
    max_selling_price_less_ahg_shg STRING
); -- Temporary placeholder type


COPY INTO HDB_Price_Range
FROM @stage_raw/PriceRangeofHDBFlatsOffered.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- HDB_Property_Info - Lv
CREATE OR REPLACE TABLE HDB_Property_Info (
    blk_no STRING, -- Not a mathematical number
    street STRING,
    max_floor_level NUMBER,
    year_completed STRING, -- Not a mathematical number
    residential STRING,
    commercial STRING, 
    market_hawker STRING,
    multistorey_carpark STRING,
    total_dwelling_units NUMBER
); -- Temporary placeholder type

COPY INTO HDB_Property_Info (blk_no, street, max_floor_level, year_completed, residential, commercial, market_hawker, multistorey_carpark, total_dwelling_units)
FROM (
    SELECT
        $1,
        $2,
        TRY_TO_NUMBER($3),
        TRY_TO_NUMBER($4),
        $5,
        $6,
        $7,
        $9,
        TRY_TO_NUMBER($12)
    FROM @stage_raw/HDBPropertyInformation.csv (FILE_FORMAT => csv_format)
)
ON_ERROR = 'CONTINUE';

-- HDB Resale Index - Lv
CREATE OR REPLACE TABLE HDB_Resale_Index(
    year_quarter STRING,
    resale_index DECIMAL
);

COPY INTO HDB_Resale_Index
FROM @stage_raw/HDBResalePriceIndex1Q2009100Quarterly.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- HDB Median Resale Price - Lv
CREATE OR REPLACE TABLE HDB_Median_Resale_Price(
    year_quarter STRING,
    town STRING,
    flat_type STRING,
    price STRING -- Leave as String due to values
);
COPY INTO HDB_Median_Resale_Price
FROM @stage_raw/MedianResalePricesforRegisteredApplicationsbyTownandFlatType.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';

-- 
-- The following part is done by Antozesslyn
-- Create Raw Table for ALL Resale Price Data
-- All columns are initially set to STRING to prevent load errors
CREATE OR REPLACE TABLE RAW_DATA.Resale_Flat_Prices (
    month STRING,
    town STRING,
    flat_type STRING,
    block STRING,
    street_name STRING,
    storey_range STRING,
    floor_area_sqm STRING,
    flat_model STRING,
    lease_commence_date STRING,
    remaining_lease STRING,
    resale_price STRING
);

-- Load data from 2015 to 2016 file
COPY INTO RAW_DATA.Resale_Flat_Prices
FROM @stage_raw/ResaleFlatPricesBasedonRegistrationDateFromJan2015toDec2016.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

-- Load data from 2017 onwards file
COPY INTO RAW_DATA.Resale_Flat_Prices
FROM @stage_raw/ResaleflatpricesbasedonregistrationdatefromJan2017onwards.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

-- Check the total number of records loaded to double check
SELECT COUNT(*) FROM RAW_DATA.Resale_Flat_Prices;

--

-- The below is done by Joely
CREATE OR REPLACE TABLE RAW_DATA.HDB_EXISTING_BUILDING (
    RAW_DATA VARIANT
);

-- 2. Load GeoJSON file from stage
COPY INTO RAW_DATA.HDB_EXISTING_BUILDING
FROM @STAGE_RAW/HDBExistingBuilding.geojson
FILE_FORMAT = (
    TYPE = JSON
)
ON_ERROR = 'CONTINUE';

-- 3. Verify the load
SELECT COUNT(*) FROM RAW_DATA.HDB_EXISTING_BUILDING;

-- Preview the raw data structure
SELECT RAW_DATA FROM RAW_DATA.HDB_EXISTING_BUILDING LIMIT 5;

-- ============================================
-- LOAD ALL 10 GEOJSON FILES INTO RAW_DATA
-- Created by: Hong Yi
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA RAW_DATA;

-- ============================================
-- 1. CHAS_CLINICS
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_chas_raw (raw_json VARIANT);

COPY INTO temp_chas_raw 
FROM @stage_raw/CHASClinics.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.CHAS_CLINICS AS
SELECT f.value AS location
FROM temp_chas_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'CHAS_CLINICS' AS table_name, COUNT(*) AS records FROM RAW_DATA.CHAS_CLINICS;


-- ============================================
-- 2. COMMUNITY_CLUBS
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_cc_raw (raw_json VARIANT);

COPY INTO temp_cc_raw 
FROM @stage_raw/CommunityClubs.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.COMMUNITY_CLUBS AS
SELECT f.value AS location
FROM temp_cc_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'COMMUNITY_CLUBS' AS table_name, COUNT(*) FROM RAW_DATA.COMMUNITY_CLUBS;


-- ============================================
-- 3. ELDERCARE_SERVICES
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_eldercare_raw (raw_json VARIANT);

COPY INTO temp_eldercare_raw 
FROM @stage_raw/EldercareServices.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.ELDERCARE_SERVICES AS
SELECT f.value AS location
FROM temp_eldercare_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'ELDERCARE_SERVICES' AS table_name, COUNT(*) FROM RAW_DATA.ELDERCARE_SERVICES;


-- ============================================
-- 4. GYMS_SG
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_gyms_raw (raw_json VARIANT);

COPY INTO temp_gyms_raw 
FROM @stage_raw/GymsSGGEOJSON.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.GYMS_SG AS
SELECT f.value AS location
FROM temp_gyms_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'GYMS_SG' AS table_name, COUNT(*) FROM RAW_DATA.GYMS_SG;


-- ============================================
-- 5. HAWKER_CENTRES
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_hawker_raw (raw_json VARIANT);

COPY INTO temp_hawker_raw 
FROM @stage_raw/HawkerCentresGEOJSON.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.HAWKER_CENTRES AS
SELECT f.value AS location
FROM temp_hawker_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'HAWKER_CENTRES' AS table_name, COUNT(*) FROM RAW_DATA.HAWKER_CENTRES;


-- ============================================
-- 6. PARKS
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_parks_raw (raw_json VARIANT);

COPY INTO temp_parks_raw 
FROM '@stage_raw/Parks@SG.geojson' 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.PARKS AS
SELECT f.value AS location
FROM temp_parks_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'PARKS' AS table_name, COUNT(*) FROM RAW_DATA.PARKS;


-- ============================================
-- 7. PRESCHOOLS
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_preschools_raw (raw_json VARIANT);

COPY INTO temp_preschools_raw 
FROM @stage_raw/PreSchoolsLocation.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.PRESCHOOLS AS
SELECT f.value AS location
FROM temp_preschools_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'PRESCHOOLS' AS table_name, COUNT(*) FROM RAW_DATA.PRESCHOOLS;


-- ============================================
-- 8. RETAIL_PHARMACY
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_pharmacy_raw (raw_json VARIANT);

COPY INTO temp_pharmacy_raw 
FROM '@stage_raw/Retail pharmacy locations (GEOJSON).geojson' 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.RETAIL_PHARMACY AS
SELECT f.value AS location
FROM temp_pharmacy_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'RETAIL_PHARMACY' AS table_name, COUNT(*) FROM RAW_DATA.RETAIL_PHARMACY;


-- ============================================
-- 9. SUPERMARKETS
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_supermarkets_raw (raw_json VARIANT);

COPY INTO temp_supermarkets_raw 
FROM @stage_raw/SupermarketsGEOJSON.geojson 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.SUPERMARKETS AS
SELECT f.value AS location
FROM temp_supermarkets_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'SUPERMARKETS' AS table_name, COUNT(*) FROM RAW_DATA.SUPERMARKETS;


-- ============================================
-- 10. WATER_ACTIVITIES
-- ============================================
CREATE OR REPLACE TEMPORARY TABLE temp_water_raw (raw_json VARIANT);

COPY INTO temp_water_raw 
FROM '@stage_raw/WaterActivities@SG.geojson' 
FILE_FORMAT = (TYPE = JSON)
ON_ERROR = 'ABORT_STATEMENT';

CREATE OR REPLACE TABLE RAW_DATA.WATER_ACTIVITIES AS
SELECT f.value AS location
FROM temp_water_raw,
LATERAL FLATTEN(input => raw_json:features) f;

SELECT 'WATER_ACTIVITIES' AS table_name, COUNT(*) FROM RAW_DATA.WATER_ACTIVITIES;


