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

-- Check for null values  
SELECT 
    'Null Check' AS check_type,
    COUNT(*) AS issue_count 
FROM RAW_DATA.Resale_Flat_Prices
WHERE resale_price IS NULL 
   OR floor_area_sqm IS NULL 
   OR town IS NULL 
   OR month IS NULL;

-- Check for duplicates
SELECT 
    month, town, block, street_name, resale_price, 
    COUNT(*) as duplicate_count
FROM RAW_DATA.Resale_Flat_Prices
GROUP BY month, town, block, street_name, resale_price
HAVING COUNT(*) > 1;



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

-- By Alluru Rishitha
-- Cleaning Bus_Stops Table
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS
WHERE BUSSTOPCODE IS NULL
   OR ROADNAME IS NULL
   OR DESCRIPTION IS NULL
   OR LATITUDE IS NULL
   OR LONGITUDE IS NULL;
-- no null values

SELECT BUSSTOPCODE, COUNT(*) AS dup_count
FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS
GROUP BY BUSSTOPCODE
HAVING COUNT(*) > 1
ORDER BY dup_count DESC, BUSSTOPCODE;
-- no duplicates

DELETE FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS
WHERE LATITUDE <1.16 OR LATITUDE > 1.50 OR
      LONGITUDE < 103.60 OR LONGITUDE > 104.10;
-- 0 rows were deleted

-- Create Bus_Stops_Cleaned Table
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.BUS_STOPS_CLEANED AS
SELECT BUSSTOPCODE, ROADNAME, DESCRIPTION, LATITUDE, LONGITUDE
FROM GROUP4_ASG2.RAW_DATA.BUS_STOPS;

-- Cleaning Clinics Table
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.CLINICS;
-- All of the values in Brand Column seem to be null and Category Column seem to be 'clinic'

SELECT DISTINCT(BRAND, CATEGORY)
FROM GROUP4_ASG2.RAW_DATA.CLINICS;
-- All of the values in Brand Column are null and Category Column are 'clinic'

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.CLINICS;

-- Delete Brand Column and Category Column
ALTER TABLE GROUP4_ASG2.RAW_DATA.CLINICS
DROP COLUMN BRAND
DROP COLUMN CATEGORY;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.CLINICS
WHERE NAME IS NULL;
-- There are 12 rows with null NAME values

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.CLINICS
WHERE LAT IS NULL
    OR LON IS NULL;
-- There are 0 rows with null LAT and LON values

-- Delete rows with null NAME values
DELETE FROM GROUP4_ASG2.RAW_DATA.CLINICS
WHERE NAME IS NULL;
-- 12 rows were deleted

UPDATE GROUP4_ASG2.RAW_DATA.CLINICS
SET 
    PHONE = CASE 
        WHEN PHONE IS NULL THEN '+65 1234 5678'
        ELSE 
            CASE 
                WHEN LENGTH(REGEXP_REPLACE(PHONE, '[^0-9]', '')) = 10 
                    THEN '+65 ' || SUBSTR(REGEXP_REPLACE(PHONE, '[^0-9]', ''), 3, 4) || ' ' || SUBSTR(REGEXP_REPLACE(PHONE, '[^0-9]', ''), 7, 4)
                WHEN LENGTH(REGEXP_REPLACE(PHONE, '[^0-9]', '')) = 8 
                    THEN '+65 ' || SUBSTR(REGEXP_REPLACE(PHONE, '[^0-9]', ''), 1, 4) || ' ' || SUBSTR(REGEXP_REPLACE(PHONE, '[^0-9]', ''), 5, 4)
                ELSE REGEXP_REPLACE(PHONE, '[^0-9]', '')
            END
    END,
    ADDRESS = COALESCE(ADDRESS, 'No Address Provided'),
    WEBSITE = COALESCE(WEBSITE, 'unknownwebsite.com')
WHERE
    PHONE NOT REGEXP '\\+65 [0-9]{4} [0-9]{4}' 
    OR PHONE IS NULL
    OR ADDRESS IS NULL 
    OR WEBSITE IS NULL;;
-- 390 rows updated

-- Manually update erroneous phone number
UPDATE GROUP4_ASG2.RAW_DATA.CLINICS
SET PHONE = REPLACE(PHONE, '7478200', '+65 6747 8200')
WHERE PHONE = '7478200';

-- Verify
SELECT *
FROM GROUP4_ASG2.RAW_DATA.CLINICS;

CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.CLINICS_CLEANED AS
SELECT NAME, LAT, LON, ADDRESS, WEBSITE, PHONE
FROM GROUP4_ASG2.RAW_DATA.CLINICS;

-- Cleaning Hospitals Table
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.HOSPITALS;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.HOSPITALS;

-- Check for null values
SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.HOSPITALS
WHERE HOSPITAL_NAME IS NULL
    OR ADDRESS IS NULL
    OR POSTAL_CODE IS NULL
    OR HOSPITAL_TYPE IS NULL
    OR LATITUDE IS NULL
    OR LONGITUDE IS NULL
    OR TOWN IS NULL;
-- 0 null count

-- Delete invalid values
DELETE FROM GROUP4_ASG2.RAW_DATA.HOSPITALS
WHERE LATITUDE <1.16 OR LATITUDE > 1.50 OR
      LONGITUDE < 103.60 OR LONGITUDE > 104.10;

DELETE FROM GROUP4_ASG2.RAW_DATA.HOSPITALS
WHERE NOT REGEXP_LIKE(POSTAL_CODE, '^[0-9]{6}$');

DELETE FROM GROUP4_ASG2.RAW_DATA.HOSPITALS
WHERE HOSPITAL_TYPE NOT IN ('Private', 'Public');
-- 0 rows deleted for the 3 queries

-- Create HOSPITALS_CLEANED
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.HOSPITALS_CLEANED AS
SELECT HOSPITAL_NAME, ADDRESS, POSTAL_CODE, HOSPITAL_TYPE, LATITUDE, LONGITUDE, TOWN
FROM  GROUP4_ASG2.RAW_DATA.HOSPITALS;

-- Cleaning MRT Stations Table
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.MRT_STATIONS;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.MRT_STATIONS;

-- Check for null values
SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.MRT_STATIONS
WHERE STN_NAME IS NULL
	OR STN_NO IS NULL
	OR GEOMETRY IS NULL
	OR LATITUDE IS NULL
	OR LONGITUDE IS NULL;

CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.MRT_STATIONS_CLEANED AS
SELECT 
    STN_NAME,
    STN_NO,
    GEOMETRY,
    LATITUDE,
    LONGITUDE,
    -- Core MRT Lines
    MAX(IFF(LINE_PREFIX = 'NS', 1, 0)) AS LINE_NS, -- North-South
    MAX(IFF(LINE_PREFIX = 'EW', 1, 0)) AS LINE_EW, -- East-West
    MAX(IFF(LINE_PREFIX = 'CG', 1, 0)) AS LINE_CG, -- Changi Extension
    MAX(IFF(LINE_PREFIX = 'NE', 1, 0)) AS LINE_NE, -- North-East
    MAX(IFF(LINE_PREFIX = 'CC', 1, 0)) AS LINE_CC, -- Circle
    MAX(IFF(LINE_PREFIX = 'CE', 1, 0)) AS LINE_CE, -- Circle Extension
    MAX(IFF(LINE_PREFIX = 'DT', 1, 0)) AS LINE_DT, -- Downtown
    MAX(IFF(LINE_PREFIX = 'TE', 1, 0)) AS LINE_TE, -- Thomson-East Coast
    -- LRT Lines
    MAX(IFF(LINE_PREFIX = 'BP', 1, 0)) AS LINE_BP, -- Bukit Panjang
    MAX(IFF(LINE_PREFIX IN ('SE', 'SW', 'STC'), 1, 0)) AS LINE_SK, -- Sengkang LRT
    MAX(IFF(LINE_PREFIX IN ('PE', 'PW', 'PTC'), 1, 0)) AS LINE_PG  -- Punggol LRT
FROM (SELECT 
        STN_NAME,
        STN_NO,
        GEOMETRY,
        LATITUDE,
        LONGITUDE,
        REGEXP_SUBSTR(SINGLE_CODE, '^[A-Z]+') as LINE_PREFIX
    FROM(SELECT 
        STN_NAME,
        STN_NO,
        GEOMETRY,
        LATITUDE,
        LONGITUDE,
        TRIM(f.value::string) as SINGLE_CODE
    FROM GROUP4_ASG2.RAW_DATA.MRT_STATIONS,
    LATERAL FLATTEN(input => SPLIT(STN_NO, '/')) f))
GROUP BY STN_NAME, STN_NO,GEOMETRY, LATITUDE, LONGITUDE;

-- Verify
SELECT *
FROM GROUP4_ASG2.CLEANED_DATA.MRT_STATIONS_CLEANED;

-- Cleaning School Locations Table
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION;

-- Remove unnecessary columns
ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN PRINCIPAL_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN FIRST_VP_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN SECOND_VP_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN THIRD_VP_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN FOURTH_VP_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN FIFTH_VP_NAME;

ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
DROP COLUMN SIXTH_VP_NAME;

-- Check for null values
SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
WHERE SCHOOL_NAME IS NULL
    OR ADDRESS IS NULL
    OR POSTAL_CODE IS NULL;
-- 0 null values for the key columns

SELECT DISTINCT MOTHERTONGUE1_CODE, MOTHERTONGUE2_CODE, MOTHERTONGUE3_CODE
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION;
-- It can be observed that there are only 3 combinations

-- Encode the Mothertongue columns
ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION RENAME COLUMN MOTHERTONGUE1_CODE TO CHINESE;
ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION RENAME COLUMN MOTHERTONGUE2_CODE TO MALAY;
ALTER TABLE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION RENAME COLUMN MOTHERTONGUE3_CODE TO TAMIL;

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET 
    CHINESE = CASE WHEN CHINESE = 'CHINESE' THEN 1 ELSE 0 END,
    MALAY   = CASE WHEN MALAY = 'MALAY'     THEN 1 ELSE 0 END,
    TAMIL   = CASE WHEN TAMIL = 'TAMIL'     THEN 1 ELSE 0 END;

-- Convert 'na' to null
UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET 
    URL_ADDRESS = NULLIF(URL_ADDRESS, 'na'),
    TELEPHONE_NO = NULLIF(TELEPHONE_NO, 'na'),
    TELEPHONE_NO_2 = NULLIF(TELEPHONE_NO_2, 'na'),
    FAX_NO = NULLIF(FAX_NO, 'na'),
    FAX_NO_2 = NULLIF(FAX_NO_2, 'na'),
    EMAIL_ADDRESS = NULLIF(EMAIL_ADDRESS, 'na'),
    MRT_DESC = NULLIF(MRT_DESC, 'na'),
    BUS_DESC = NULLIF(BUS_DESC, 'na'),
    DGP_CODE = NULLIF(DGP_CODE, 'na'),
    ZONE_CODE = NULLIF(ZONE_CODE, 'na'),
    TYPE_CODE = NULLIF(TYPE_CODE, 'na'),
    NATURE_CODE = NULLIF(NATURE_CODE, 'na'),
    SESSION_CODE = NULLIF(SESSION_CODE, 'na'),
    MAINLEVEL_CODE = NULLIF(MAINLEVEL_CODE, 'na');
    
-- Clean MRT_Desc column to match the format of STN_NAME in MRT Stations Table
CREATE TEMPORARY TABLE MRT_REFERENCE AS (
    SELECT 
        STN_NAME, 
        REPLACE(REPLACE(UPPER(STN_NAME), ' MRT STATION', ''), ' LRT STATION', '') AS CLEAN_NAME
    FROM GROUP4_ASG2.RAW_DATA.MRT_STATIONS
);

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET mrt_desc = (
    SELECT LISTAGG(STN_NAME, ', ') 
        FROM MRT_REFERENCE
    WHERE 
        UPPER(mrt_desc) LIKE '%' || CLEAN_NAME || '%'
        OR UPPER(mrt_desc) LIKE '%' || REPLACE(CLEAN_NAME, ' LRT', '') || '%'
);

-- Verifying 
SELECT *
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
WHERE MRT_DESC IS NULL OR MRT_DESC = '';
-- 9 missing MRT_Desc values

-- Manually fill in
UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'PUNGGOL EAST LRT STATION'
WHERE SCHOOL_NAME = 'VALOUR PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'FARRER ROAD MRT STATION'
WHERE SCHOOL_NAME = 'NANYANG PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'MARINE TERRACE MRT STATION'
WHERE SCHOOL_NAME = 'NGEE ANN PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'PUNGGOL POINT LRT STATION'
WHERE SCHOOL_NAME = 'NORTHSHORE PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'LORONG CHUAN MRT STATION'
WHERE SCHOOL_NAME = 'ST. GABRIEL\'S PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'MARINE TERRACE MRT STATION'
WHERE SCHOOL_NAME = 'ST. PATRICK\'S SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'KALLANG MRT STATION, PAYA LEBAR MRT STATION'
WHERE SCHOOL_NAME = 'TANJONG KATONG PRIMARY SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'MARINE PARADE MRT STATION, MARINE TERRACE MRT STATION'
WHERE SCHOOL_NAME = 'TAO NAN SCHOOL';

UPDATE GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION
SET MRT_DESC = 'HOUGANG MRT STATION'
WHERE SCHOOL_NAME = 'XINMIN PRIMARY SCHOOL';
-- After comparing with the original dataset and searching on Google, I managed to find the nearest MRT/LRT Stations for these schools

DROP TABLE MRT_REFERENCE;

CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.SCHOOL_LOCATION_CLEANED AS
SELECT *
FROM GROUP4_ASG2.RAW_DATA.SCHOOL_LOCATION;

-- Verify table creation
SELECT *
FROM GROUP4_ASG2.CLEANED_DATA.SCHOOL_LOCATION_CLEANED;

-- Cleaning Shopping Malls and Shopping Mall Coordinates Tables
USE SCHEMA CLEANED_DATA;

-- Inspect Raw Data
SELECT *
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS;

SELECT *
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALL_COORDINATES;

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS;
-- 249 rows

SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALL_COORDINATES;
-- 155 rows

-- Check for unique values in Category and Brand columns in Shopping Mall Table
SELECT DISTINCT CATEGORY, BRAND
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS;
-- Since all the values of Category = 'mall' and Brand = null, these columns can be dropped

ALTER TABLE GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS DROP COLUMN CATEGORY;
ALTER TABLE GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS DROP COLUMN BRAND;

-- Check for null values
SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS
WHERE NAME IS NULL 
    OR LAT IS NULL
    OR LON IS NULL;
-- 14 null values
    
SELECT COUNT(*)
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALL_COORDINATES
WHERE MALLNAME IS NULL
    OR LATITUDE IS NULL
    OR LONGITUDE IS NULL;
-- 0 null values

-- Investigate null values in Shopping Malls Table
SELECT DISTINCT *
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS
WHERE NAME IS NULL 
    OR LAT IS NULL
    OR LON IS NULL;
-- Only the Name values are null while Lat and Lon values are provided. No duplicates found

-- Try updating the missing values based on the Latitude and Longitude from Shopping Mall Coordinates Table
UPDATE GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS AS m
SET m.NAME = c.MALLNAME
FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALL_COORDINATES AS c
WHERE ROUND(m.LAT, 5) = ROUND(c.LATITUDE, 5)
  AND ROUND(m.LON, 5) = ROUND(c.LONGITUDE, 5)
  AND m.NAME IS NULL;
-- 0 rows updated

-- Delete these rows
DELETE FROM GROUP4_ASG2.RAW_DATA.SHOPPING_MALLS
WHERE NAME IS NULL 
    OR LAT IS NULL
    OR LON IS NULL;
-- 14 rows deleted

CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.SHOPPING_MALLS_CLEANED AS
SELECT *
FROM SHOPPING_MALLS;

-- Verify Table Creation
SELECT *
FROM GROUP4_ASG2.CLEANED_DATA.SHOPPING_MALLS_CLEANED;



-- ============================================
-- GEOJSON DATA CLEANING SCRIPT
-- Created by: Hong Yi
-- Purpose: Clean and standardize 10 GeoJSON datasets for HDB resale analysis
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

-- ============================================
-- TABLE 1: CHAS CLINICS
-- Description: Community Health Assist Scheme clinics providing subsidized healthcare
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Clinic name, code, contact info, location
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.CHAS_CLINICS LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.CHAS_CLINICS;

-- 3. Create Cleaned Table by parsing GeoJSON
-- Strategy: Extract data from HTML-formatted Description field using REGEXP_SUBSTR
-- HTML pattern example: <th>HCINAME</th> <td>OnecarClinic</td>
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED AS
SELECT
    -- Extract clinic identification fields
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thHCINAMEth td([^<]+)td', 1, 1, 'e', 1) AS clinic_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thHCICODEth td([^<]+)td', 1, 1, 'e', 1) AS clinic_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thLICENCETYPEth td([^<]+)td', 1, 1, 'e', 1) AS licence_type,
    
    -- Extract contact information
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thHCITELth td([^<]+)td', 1, 1, 'e', 1) AS phone,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thPOSTALCDth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thBLKHSENOth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thSTREETNAMEth td([^<]+)td', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thBUILDINGNAMEth td([^<]+)td', 1, 1, 'e', 1) AS building_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thFLOORNOth td([^<]+)td', 1, 1, 'e', 1) AS floor_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thUNITNOth td([^<]+)td', 1, 1, 'e', 1) AS unit_no,
    
    -- Extract programme information for feature engineering
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thCLINICPROGRAMMECODEth td([^<]+)td', 1, 1, 'e', 1) AS programme_codes,
    
    -- Extract coordinates from GeoJSON geometry array
    -- GeoJSON format: coordinates: [longitude, latitude, elevation]
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry as GEOGRAPHY type for spatial analysis
    -- This enables distance calculations, proximity queries, etc.
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type for reference (should be 'Point')
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.CHAS_CLINICS
WHERE 
    -- Filter to Singapore geographic bounds only
    -- Latitude range: 1.16°N (Sentosa) to 1.50°N (Woodlands)
    -- Longitude range: 103.60°E (Tuas) to 104.10°E (Changi)
    location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
    AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_clinic_names
FROM GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED
WHERE clinic_name IS NULL;

SELECT COUNT(*) AS null_coordinates
FROM GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED
WHERE longitude IS NULL OR latitude IS NULL;


-- ============================================
-- TABLE 2: COMMUNITY CLUBS
-- Description: Community centers providing social and recreational activities
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Club name, address, website
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.COMMUNITY_CLUBS LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.COMMUNITY_CLUBS;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.COMMUNITY_CLUBS_CLEANED AS
SELECT
    -- Extract community club identification
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thNAMEth td([^<]+)td', 1, 1, 'e', 1) AS name,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSPOSTALCODEth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSSTREETNAMEth td([^<]+)td', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBLOCKHOUSENUMBERth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBUILDINGNAMEth td([^<]+)td', 1, 1, 'e', 1) AS building_name,
    
    -- Extract additional information
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thHYPERLINKth td([^<]+)td', 1, 1, 'e', 1) AS website,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thDESCRIPTIONth td([^<]+)td', 1, 1, 'e', 1) AS description,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.COMMUNITY_CLUBS
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.COMMUNITY_CLUBS_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.COMMUNITY_CLUBS_CLEANED
WHERE name IS NULL;


-- ============================================
-- TABLE 3: ELDERCARE SERVICES
-- Description: Elderly care facilities and support services
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Service name, address, location
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.ELDERCARE_SERVICES LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.ELDERCARE_SERVICES;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.ELDERCARE_SERVICES_CLEANED AS
SELECT
    -- Extract service identification
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thNAMEth td([^<]+)td', 1, 1, 'e', 1) AS name,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSPOSTALCODEth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSSTREETNAMEth td([^<]+)td', 1, 1, 'e', 1) AS address,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBLOCKHOUSENUMBERth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBUILDINGNAMEth td([^<]+)td', 1, 1, 'e', 1) AS building_name,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.ELDERCARE_SERVICES
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.ELDERCARE_SERVICES_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.ELDERCARE_SERVICES_CLEANED
WHERE name IS NULL;


-- ============================================
-- TABLE 4: GYMS SG
-- Description: Fitness centers and gyms across Singapore
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Gym name, address, operating hours, facilities
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.GYMS_SG LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.GYMS_SG;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.GYMS_SG_CLEANED AS
SELECT
    -- Extract gym identification
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thNAMEth td([^<]+)td', 1, 1, 'e', 1) AS name,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSPOSTALCODEth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSSTREETNAMEth td([^<]+)td', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBLOCKHOUSENUMBERth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBUILDINGNAMEth td([^<]+)td', 1, 1, 'e', 1) AS building_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSFLOORNUMBERth td([^<]+)td', 1, 1, 'e', 1) AS floor_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSUNITNUMBERth td([^<]+)td', 1, 1, 'e', 1) AS unit_no,
    
    -- Extract additional information for feature engineering
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thDESCRIPTIONth td([^<]+)td', 1, 1, 'e', 1) AS description,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Enables: distance to HDB, proximity queries, buffer analysis
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.GYMS_SG
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.GYMS_SG_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.GYMS_SG_CLEANED
WHERE name IS NULL;

-- 6. Sample cleaned data for verification
SELECT * FROM GROUP4_ASG2.CLEANED_DATA.GYMS_SG_CLEANED LIMIT 10;



-- ============================================
-- TABLE 5: HAWKER CENTRES
-- Description: Government-managed food centers with multiple stalls
-- Raw Data Type: GeoJSON with properties directly accessible (not in HTML)
-- Key Fields: Hawker name, address, status, number of stalls, completion dates
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.HAWKER_CENTRES LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.HAWKER_CENTRES;

-- 3. Create Cleaned Table by parsing GeoJSON
-- Strategy: Direct property extraction using :: operator (cleaner than HTML parsing)
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.HAWKER_CENTRES_CLEANED AS
SELECT
    -- Extract hawker centre identification
    location:properties:NAME::STRING AS name,
    TRY_TO_NUMBER(location:properties:OBJECTID::STRING) AS object_id,
    
    -- Extract address components
    location:properties:ADDRESSPOSTALCODE::STRING AS postal_code,
    location:properties:ADDRESSSTREETNAME::STRING AS street_name,
    location:properties:ADDRESSBLOCKHOUSENUMBER::STRING AS block_no,
    location:properties:ADDRESSBUILDINGNAME::STRING AS building_name,
    
    -- Extract operational information for feature engineering
    location:properties:STATUS::STRING AS status,
    location:properties:DESCRIPTION::STRING AS description,
    TRY_TO_NUMBER(location:properties:NUMBEROFCOOKEDFOODSTALLS::STRING) AS num_cooked_food_stalls,
    
    -- Extract dates for temporal analysis
    -- Note: Date format varies, using flexible parsing
    location:properties:ESTORIGINALCOMPLETIONDATE::STRING AS original_completion_date,
    location:properties:HUPCOMPLETIONDATE::STRING AS hup_completion_date,
    location:properties:AWARDEDDATE::STRING AS awarded_date,
    
    -- Extract co-location information (useful for amenity density features)
    location:properties:INFOONCOLOCATORS::STRING AS colocators,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.HAWKER_CENTRES
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.HAWKER_CENTRES_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.HAWKER_CENTRES_CLEANED
WHERE name IS NULL;

-- 6. Check status distribution
SELECT status, COUNT(*) AS count
FROM GROUP4_ASG2.CLEANED_DATA.HAWKER_CENTRES_CLEANED
GROUP BY status
ORDER BY count DESC;


-- ============================================
-- TABLE 6: PARKS
-- Description: National parks, gardens, and recreational green spaces
-- Raw Data Type: GeoJSON with properties directly accessible
-- Key Fields: Park name, coordinates, object ID
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.PARKS LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.PARKS;

-- 3. Create Cleaned Table by parsing GeoJSON
-- Strategy: Direct property extraction (simplest approach)
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.PARKS_CLEANED AS
SELECT
    -- Extract park identification
    location:properties:NAME::STRING AS name,
    TRY_TO_NUMBER(location:properties:OBJECTID::STRING) AS object_id,
    
    -- Extract coordinate reference system values (for advanced GIS)
    TRY_TO_NUMBER(location:properties:X::STRING) AS x_coordinate,
    TRY_TO_NUMBER(location:properties:Y::STRING) AS y_coordinate,
    
    -- Extract metadata
    location:properties:INCCRC::STRING AS inc_crc,
    location:properties:FMELUPDD::STRING AS last_updated,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Use case: Calculate distance from HDB to nearest park
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.PARKS
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.PARKS_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.PARKS_CLEANED
WHERE name IS NULL;


-- ============================================
-- TABLE 7: PRESCHOOLS
-- Description: Preschool and childcare center locations
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Center name, center code, location
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.PRESCHOOLS LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.PRESCHOOLS;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.PRESCHOOLS_CLEANED AS
SELECT
    -- Extract preschool identification
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thCENTRENAMEth td([^<]+)td', 1, 1, 'e', 1) AS centre_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thCENTRECODEth td([^<]+)td', 1, 1, 'e', 1) AS centre_code,
    
    -- Extract metadata
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thINCCRCth td([^<]+)td', 1, 1, 'e', 1) AS inc_crc,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thFMELUPDDth td([^<]+)td', 1, 1, 'e', 1) AS last_updated,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Use case: Proximity to preschools affects family housing decisions
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.PRESCHOOLS
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.PRESCHOOLS_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.PRESCHOOLS_CLEANED
WHERE centre_name IS NULL;


-- ============================================
-- TABLE 8: RETAIL PHARMACY
-- Description: Licensed retail pharmacy locations
-- Raw Data Type: GeoJSON with properties directly accessible
-- Key Fields: Pharmacy name, address, postal code, building info
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.RETAIL_PHARMACY LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.RETAIL_PHARMACY;

-- 3. Create Cleaned Table by parsing GeoJSON
-- Strategy: Direct property extraction (properties are clean, not in HTML)
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.RETAIL_PHARMACY_CLEANED AS
SELECT
    -- Extract pharmacy identification
    location:properties:PHARMACYNAME::STRING AS pharmacy_name,
    TRY_TO_NUMBER(location:properties:OBJECTID1::STRING) AS object_id,
    
    -- Extract address components
    location:properties:POSTALCODE::STRING AS postal_code,
    location:properties:ROADNAME::STRING AS road_name,
    location:properties:HOUSEBLKNO::STRING AS block_no,
    location:properties:BUILDINGNAME::STRING AS building_name,
    location:properties:LEVELNO::STRING AS floor_no,
    location:properties:UNITNO::STRING AS unit_no,
    
    -- Extract metadata
    location:properties:INCCRC::STRING AS inc_crc,
    location:properties:FMELUPDD::STRING AS last_updated,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Use case: Healthcare accessibility metric
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.RETAIL_PHARMACY
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.RETAIL_PHARMACY_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.RETAIL_PHARMACY_CLEANED
WHERE pharmacy_name IS NULL;


-- ============================================
-- TABLE 9: SUPERMARKETS
-- Description: Licensed supermarket and grocery store locations
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: License name, address, postal code
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.SUPERMARKETS LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.SUPERMARKETS;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED AS
SELECT
    -- Extract supermarket identification
    -- LICNAME contains the business name
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thLICNAMEth td([^<]+)td', 1, 1, 'e', 1) AS business_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thLICNOth td([^<]+)td', 1, 1, 'e', 1) AS licence_no,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thPOSTCODEth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thSTRNAMEth td([^<]+)td', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thBLKHOUSEth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thUNITNOth td([^<]+)td', 1, 1, 'e', 1) AS unit_no,
    
    -- Extract metadata
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thINCCRCth td([^<]+)td', 1, 1, 'e', 1) AS inc_crc,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thFMELUPDDth td([^<]+)td', 1, 1, 'e', 1) AS last_updated,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Use case: Calculate supermarket density, accessibility index
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.SUPERMARKETS
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED
WHERE business_name IS NULL;

-- 6. Check for common supermarket chains (useful for brand analysis)
SELECT 
    CASE 
        WHEN business_name LIKE '%NTUC FAIRPRICE%' THEN 'NTUC FairPrice'
        WHEN business_name LIKE '%SHENG SIONG%' THEN 'Sheng Siong'
        WHEN business_name LIKE '%COLD STORAGE%' THEN 'Cold Storage'
        WHEN business_name LIKE '%PRIME SUPERMARKET%' THEN 'Prime'
        ELSE 'Others'
    END AS supermarket_chain,
    COUNT(*) AS count
FROM GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED
GROUP BY supermarket_chain
ORDER BY count DESC;


-- ============================================
-- TABLE 10: WATER ACTIVITIES
-- Description: Water sports facilities, swimming complexes, and aquatic centers
-- Raw Data Type: GeoJSON with properties embedded in HTML Description field
-- Key Fields: Facility name, address, facilities description, operating hours
-- ============================================

-- 1. Inspect Raw Data structure
SELECT location FROM GROUP4_ASG2.RAW_DATA.WATER_ACTIVITIES LIMIT 5;

-- 2. Check total record count
SELECT COUNT(*) AS total_records
FROM GROUP4_ASG2.RAW_DATA.WATER_ACTIVITIES;

-- 3. Create Cleaned Table by parsing GeoJSON
CREATE OR REPLACE TABLE GROUP4_ASG2.CLEANED_DATA.WATER_ACTIVITIES_CLEANED AS
SELECT  
    -- Extract facility identification
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thNAMEth td([^<]+)td', 1, 1, 'e', 1) AS name,
    
    -- Extract address components
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSPOSTALCODEth td([^<]+)td', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSSTREETNAMEth td([^<]+)td', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBLOCKHOUSENUMBERth td([^<]+)td', 1, 1, 'e', 1) AS block_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSBUILDINGNAMEth td([^<]+)td', 1, 1, 'e', 1) AS building_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSFLOORNUMBERth td([^<]+)td', 1, 1, 'e', 1) AS floor_no,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thADDRESSUNITNUMBERth td([^<]+)td', 1, 1, 'e', 1) AS unit_no,
    
    -- Extract facilities and operating information (useful for amenity quality features)
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thDESCRIPTIONth td([^<]+)td', 1, 1, 'e', 1) AS description,
    REGEXP_SUBSTR(location:properties:Description::STRING, 'thHYPERLINKth td([^<]+)td', 1, 1, 'e', 1) AS website,
    
    -- Extract land coordinates (alternative coordinate system)
    TRY_TO_NUMBER(REGEXP_SUBSTR(location:properties:Description::STRING, 'thLANDXADDRESSPOINTth td([^<]+)td', 1, 1, 'e', 1)) AS land_x,
    TRY_TO_NUMBER(REGEXP_SUBSTR(location:properties:Description::STRING, 'thLANDYADDRESSPOINTth td([^<]+)td', 1, 1, 'e', 1)) AS land_y,
    
    -- Extract coordinates from GeoJSON geometry
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    
    -- Store full geometry for spatial analysis
    -- Use case: Recreational facility accessibility
    TO_GEOGRAPHY(location:geometry) AS geometry,
    
    -- Keep geometry type
    location:geometry:type::STRING AS geometry_type
FROM GROUP4_ASG2.RAW_DATA.WATER_ACTIVITIES
WHERE location:geometry:coordinates[1]::FLOAT BETWEEN 1.16 AND 1.50
  AND location:geometry:coordinates[0]::FLOAT BETWEEN 103.60 AND 104.10;

-- 4. Verify cleaned data
SELECT COUNT(*) AS cleaned_records 
FROM GROUP4_ASG2.CLEANED_DATA.WATER_ACTIVITIES_CLEANED;

-- 5. Data quality checks
SELECT COUNT(*) AS null_names
FROM GROUP4_ASG2.CLEANED_DATA.WATER_ACTIVITIES_CLEANED
WHERE name IS NULL;

-- 6. Sample cleaned data for verification
SELECT * FROM GROUP4_ASG2.CLEANED_DATA.WATER_ACTIVITIES_CLEANED LIMIT 10;


-- ============================================
-- SUMMARY AND FINAL VERIFICATION
-- ============================================

-- Count all cleaned GeoJSON tables
SELECT 'CHAS_CLINICS' AS table_name, COUNT(*) AS record_count 
FROM GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED
UNION ALL
SELECT 'COMMUNITY_CLUBS', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.COMMUNITY_CLUBS_CLEANED
UNION ALL
SELECT 'ELDERCARE_SERVICES', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.ELDERCARE_SERVICES_CLEANED
UNION ALL
SELECT 'GYMS_SG', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.GYMS_SG_CLEANED
UNION ALL
SELECT 'HAWKER_CENTRES', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.HAWKER_CENTRES_CLEANED
UNION ALL
SELECT 'PARKS', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.PARKS_CLEANED
UNION ALL
SELECT 'PRESCHOOLS', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.PRESCHOOLS_CLEANED
UNION ALL
SELECT 'RETAIL_PHARMACY', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.RETAIL_PHARMACY_CLEANED
UNION ALL
SELECT 'SUPERMARKETS', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED
UNION ALL
SELECT 'WATER_ACTIVITIES', COUNT(*) 
FROM GROUP4_ASG2.CLEANED_DATA.WATER_ACTIVITIES_CLEANED
ORDER BY record_count DESC;