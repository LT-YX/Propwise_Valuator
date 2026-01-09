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
-- 1. Create Raw Table with VARIANT column for GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.hdb_existing_building (
    raw_data VARIANT
);

-- 2. Load GeoJSON file from stage
COPY INTO RAW_DATA.hdb_existing_building
FROM @stage_raw/HDBExistingBuilding.geojson
FILE_FORMAT = (
    TYPE = JSON
)
ON_ERROR = 'CONTINUE';

-- 3. Verify the load
SELECT COUNT(*) FROM RAW_DATA.hdb_existing_building;

-- Preview the raw data structure
SELECT raw_data FROM RAW_DATA.hdb_existing_building LIMIT 5;

-- ============================================
-- The below is done by Hong Yi
-- ============================================

-- 1. Upload files to stage using Snowflake UI
-- 2. Once file has been uploaded, create table
-- 3. Load data from stage to table


-- Bus Stops - Hong Yi
-- 1. Create Raw Table for Bus Stops (CSV)
CREATE OR REPLACE TABLE RAW_DATA.BUS_STOPS (
    BUSSTOPCODE NUMBER(38,0),
    ROADNAME VARCHAR(16777216),
    DESCRIPTION VARCHAR(16777216),
    LATITUDE NUMBER(38,14),
    LONGITUDE NUMBER(38,14)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.BUS_STOPS
FROM @stage_raw/BusStops.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- Clinics - Hong Yi
-- 1. Create Raw Table for Clinics (CSV)
CREATE OR REPLACE TABLE RAW_DATA.CLINICS (
    NAME VARCHAR(16777216),
    CATEGORY VARCHAR(16777216),
    LAT NUMBER(38,7),
    LON NUMBER(38,7),
    BRAND VARCHAR(16777216),
    ADDRESS VARCHAR(16777216),
    WEBSITE VARCHAR(16777216),
    PHONE VARCHAR(16777216)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.CLINICS
FROM @stage_raw/Clinics.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- Hospitals - Hong Yi
-- 1. Create Raw Table for Hospitals (CSV)
CREATE OR REPLACE TABLE RAW_DATA.HOSPITALS (
    HOSPITAL_NAME VARCHAR(16777216),
    ADDRESS VARCHAR(16777216),
    POSTAL_CODE NUMBER(38,0),
    HOSPITAL_TYPE VARCHAR(16777216),
    LATITUDE NUMBER(38,7),
    LONGITUDE NUMBER(38,7),
    TOWN VARCHAR(16777216)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.HOSPITALS
FROM @stage_raw/Hospitals.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- MRT Stations - Hong Yi
-- 1. Create Raw Table for MRT Stations (CSV)
CREATE OR REPLACE TABLE RAW_DATA.MRT_STATIONS (
    OBJECTID NUMBER(38,0),
    STN_NAME VARCHAR(16777216),
    STN_NO VARCHAR(16777216),
    GEOMETRY VARCHAR(16777216),
    LATITUDE NUMBER(38,16),
    LONGITUDE NUMBER(38,14)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.MRT_STATIONS
FROM @stage_raw/MRTStations.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- School Location - Hong Yi
-- 1. Create Raw Table for School Location (CSV)
CREATE OR REPLACE TABLE RAW_DATA.SCHOOL_LOCATION (
    SCHOOL_NAME VARCHAR(16777216),
    URL_ADDRESS VARCHAR(16777216),
    ADDRESS VARCHAR(16777216),
    POSTAL_CODE NUMBER(38,0),
    TELEPHONE_NO VARCHAR(16777216),
    TELEPHONE_NO_2 VARCHAR(16777216),
    FAX_NO VARCHAR(16777216),
    FAX_NO_2 VARCHAR(16777216),
    EMAIL_ADDRESS VARCHAR(16777216),
    MRT_DESC VARCHAR(16777216),
    BUS_DESC VARCHAR(16777216),
    PRINCIPAL_NAME VARCHAR(16777216),
    FIRST_VP_NAME VARCHAR(16777216),
    SECOND_VP_NAME VARCHAR(16777216),
    THIRD_VP_NAME VARCHAR(16777216),
    FOURTH_VP_NAME VARCHAR(16777216),
    FIFTH_VP_NAME VARCHAR(16777216),
    SIXTH_VP_NAME VARCHAR(16777216),
    DGP_CODE VARCHAR(16777216),
    ZONE_CODE VARCHAR(16777216),
    TYPE_CODE VARCHAR(16777216),
    NATURE_CODE VARCHAR(16777216),
    SESSION_CODE VARCHAR(16777216),
    MAINLEVEL_CODE VARCHAR(16777216),
    SAP_IND BOOLEAN,
    AUTONOMOUS_IND BOOLEAN,
    GIFTED_IND BOOLEAN,
    IP_IND BOOLEAN,
    MOTHERTONGUE1_CODE VARCHAR(16777216),
    MOTHERTONGUE2_CODE VARCHAR(16777216),
    MOTHERTONGUE3_CODE VARCHAR(16777216)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.SCHOOL_LOCATION
FROM @stage_raw/SchoolLocation.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- Shopping Malls - Hong Yi
-- 1. Create Raw Table for Shopping Malls (CSV)
CREATE OR REPLACE TABLE RAW_DATA.SHOPPING_MALLS (
    NAME VARCHAR(16777216),
    CATEGORY VARCHAR(16777216),
    LAT NUMBER(38,7),
    LON NUMBER(38,7),
    BRAND VARCHAR(16777216),
    ADDRESS VARCHAR(16777216),
    WEBSITE VARCHAR(16777216),
    PHONE VARCHAR(16777216)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.SHOPPING_MALLS
FROM @stage_raw/ShoppingMalls.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- Shopping Mall Coordinates - Hong Yi
-- 1. Create Raw Table for Shopping Mall Coordinates (CSV)
CREATE OR REPLACE TABLE RAW_DATA.SHOPPING_MALL_COORDINATES (
    MALLNAME VARCHAR(16777216),
    LATITUDE NUMBER(38,14),
    LONGITUDE NUMBER(38,12)
);

-- 2. Load CSV file from stage
COPY INTO RAW_DATA.SHOPPING_MALL_COORDINATES
FROM @stage_raw/ShoppingMallCoordinates.csv
FILE_FORMAT = csv_format
ON_ERROR = 'CONTINUE';


-- CHAS Clinics - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.CHAS_CLINICS (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.CHAS_CLINICS
FROM @stage_raw/CHASClinics.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Community Clubs - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.COMMUNITY_CLUBS (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.COMMUNITY_CLUBS
FROM @stage_raw/CommunityClubs.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Eldercare Services - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.ELDERCARE_SERVICES (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.ELDERCARE_SERVICES
FROM @stage_raw/EldercareServices.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Gyms SG - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.GYMS_SG (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.GYMS_SG
FROM @stage_raw/GymsSGGEOJSON.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Hawker Centres - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.HAWKER_CENTRES (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.HAWKER_CENTRES
FROM @stage_raw/HawkerCentresGEOJSON.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Parks - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.PARKS (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.PARKS
FROM @stage_raw/Parks.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Preschools - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.PRESCHOOLS (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.PRESCHOOLS
FROM @stage_raw/PreSchoolsLocation.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Retail Pharmacy - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.RETAIL_PHARMACY (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.RETAIL_PHARMACY
FROM @stage_raw/RetailPharmacyLocations.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Supermarkets - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.SUPERMARKETS (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.SUPERMARKETS
FROM @stage_raw/SupermarketsGEOJSON.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';


-- Water Activities - Hong Yi
-- 1. Create Raw Table with VARIANT column for GeoJSON
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.WATER_ACTIVITIES (
    location VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.WATER_ACTIVITIES
FROM @stage_raw/WaterActivities@SG.geojson
FILE_FORMAT = (TYPE = JSON STRIP_OUTER_ARRAY = TRUE)
ON_ERROR = 'CONTINUE';
