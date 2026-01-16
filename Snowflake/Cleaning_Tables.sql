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

-- HDB Property Info - No futher cleaning needs to be done
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_Property_Info AS
SELECT * FROM RAW_DATA.HDB_PROPERTY_INFO;

-- HDB Resale Index
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_Resale_Index AS
SELECT  
    SPLIT(year_quarter, '-')[0]::INTEGER AS year, 
    SPLIT(year_quarter, '-')[1]::STRING AS quarter,
    resale_index
FROM RAW_DATA.HDB_Resale_Index;

-- HDB Median Resale Price
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_Median_Resale_Price AS
SELECT 
    SPLIT(year_quarter, '-')[0]::INTEGER AS year, 
    SPLIT(year_quarter, '-')[1]::STRING AS quarter,
    town,
    flat_type,
    CASE
        WHEN LOWER(price) IN ('na', '-') THEN NULL
        ELSE price::FLOAT
    END AS price,
FROM RAW_DATA.HDB_MEDIAN_RESALE_PRICE;


-- ============================================
-- The following is done by Antozesslyn
-- Data Cleaning and Final Table Creation

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA RAW_DATA; 

-- Data Quality Checks
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
-- Drop duplicates at the end


-- Create the Cleaned Table and Perform Feature Engineering
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.Resale_Flat_Prices_Cleaned AS
SELECT
    -- Convert 'month' ('2015-01') to a DATE type
    -- TRY_TO_DATE(month, 'YYYY-MM') AS sale_date,
    -- Split to year and month seperately
    CAST(SPLIT_PART(month, '-', 1) AS INTEGER) AS sale_year,
    CAST(SPLIT_PART(month, '-', 2) AS INTEGER) AS sale_month,

    -- Feature engineering : create address
    block || ' ' || street_name AS address,
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

    -- Feature Engineering 1 : Extracting approximate remaining lease in years as a float
    -- This handles strings like '60 years 05 months' and '70' (for older data)
    -- The formula extracts years and months/12
    -- This ensures standardisation
CASE 
        WHEN remaining_lease LIKE '%years%' THEN -- Checks if data looks like '60 Years 5 Months'
            TRY_TO_NUMBER(SPLIT_PART(remaining_lease, ' years', 1)) + -- Takes the number of years
            (COALESCE(TRY_TO_NUMBER(SPLIT_PART(SPLIT_PART(remaining_lease, ' months', 1), ' ', -1)), 0) / 12)
            -- Finds the month number and divides it by 12 to get "decimal years" or 0 if there are no months
        ELSE -- '60'
            TRY_TO_NUMBER(remaining_lease) -- Turn text into a number
    END AS remaining_lease_years, -- Saves the final result into a new column

    -- Feature Engineering 2 : Price per SQM
    -- This allows comparison of the value regardless of the flat size
    (TRY_TO_NUMBER(resale_price) / NULLIF(TRY_TO_NUMBER(floor_area_sqm), 0)) AS price_per_sqm,
    
    -- Feature Engineering 3 : Flat age at time of sale 
    -- This calculated the how old the flat was at the time of sale
    (YEAR(TRY_TO_DATE(month, 'YYYY-MM')) - TRY_TO_NUMBER(lease_commence_date)) AS flat_age

    
FROM RAW_DATA.Resale_Flat_Prices

-- Only keep first original row of duplicate sets
-- Number them with a index and only keep 1
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY month, town, block, street_name, resale_price 
    ORDER BY month
) = 1;

-- Create the Final Joined/Consolidated Table
-- Since the files were combined in the RAW stage, this step is for final feature selection/view
USE SCHEMA FINAL_DATA;

CREATE OR REPLACE TABLE FINAL_DATA.HDB_RESALE_PRICES AS
SELECT
    -- sale_date,
    sale_year,
    sale_month,
    address,
    town,
    flat_type,
    storey_range,
    flat_model,
    floor_area_sqm,
    resale_price,
    remaining_lease_years,
    price_per_sqm,
    flat_age,
    block,
    street_name,
    lease_commence_year
FROM CLEANED_DATA.Resale_Flat_Prices_Cleaned;


-- Final duplicate check
SELECT 
    sale_year, 
    sale_month, 
    town, 
    block, 
    street_name, 
    resale_price, 
    COUNT(*) as duplicate_count
FROM FINAL_DATA.HDB_RESALE_PRICES
GROUP BY sale_year, sale_month, town, block, street_name, resale_price
HAVING COUNT(*) > 1;

-- Suspend warehouse 
ALTER WAREHOUSE GROUP4_ASG2 SUSPEND;

-- ============================================



-- The below is done by Joely
USE SCHEMA CLEANED_DATA;

-- Drop the existing cleaned table if it exists
DROP TABLE IF EXISTS CLEANED_DATA.HDB_EXISTING_BUILDING;

-- 4. Create Cleaned Table using LATERAL FLATTEN to parse the features array
CREATE OR REPLACE TABLE CLEANED_DATA.HDB_EXISTING_BUILDING AS
SELECT
    -- Extract property attributes from the flattened features
    F.VALUE:properties:OBJECTID::INTEGER AS OBJECT_ID,
    F.VALUE:properties:BLK_NO::STRING AS BLOCK_NO,
    F.VALUE:properties:ST_COD::STRING AS STREET_CODE,
    F.VALUE:properties:ENTITYID::INTEGER AS ENTITY_ID,
    F.VALUE:properties:POSTAL_COD::STRING AS POSTAL_CODE,
    F.VALUE:properties:INC_CRC::STRING AS INC_CRC,
    F.VALUE:properties:FMEL_UPD_D::STRING AS LAST_UPDATED,
    
    -- For numeric fields, cast to STRING first, then to NUMBER
    TRY_TO_NUMBER(F.VALUE:properties:"SHAPE.AREA"::STRING) AS SHAPE_AREA,
    TRY_TO_NUMBER(F.VALUE:properties:"SHAPE.LEN"::STRING) AS SHAPE_LENGTH,
    
    -- Store geometry as GEOGRAPHY type for spatial analysis
    TO_GEOGRAPHY(F.VALUE:geometry) AS GEOMETRY,
    
    -- Keep geometry type for reference
    F.VALUE:geometry:type::STRING AS GEOMETRY_TYPE,
    
    -- Extract latitude and longitude from geometry
    ST_Y(ST_CENTROID(TO_GEOGRAPHY(F.VALUE:geometry))) AS LATITUDE,
    ST_X(ST_CENTROID(TO_GEOGRAPHY(F.VALUE:geometry))) AS LONGITUDE
FROM RAW_DATA.HDB_EXISTING_BUILDING,
LATERAL FLATTEN(input => RAW_DATA:features) F;

-- 5. Verify cleaned data
SELECT COUNT(*) FROM CLEANED_DATA.HDB_EXISTING_BUILDING;

-- Check for any null postal codes or block numbers (data quality check)
SELECT 
    COUNT(*) AS TOTAL_RECORDS,
    COUNT(BLOCK_NO) AS BLOCKS_WITH_DATA,
    COUNT(POSTAL_CODE) AS POSTAL_CODES_WITH_DATA,
    COUNT(LATITUDE) AS RECORDS_WITH_LATITUDE,
    COUNT(LONGITUDE) AS RECORDS_WITH_LONGITUDE
FROM CLEANED_DATA.HDB_EXISTING_BUILDING;

-- Preview data with coordinates
SELECT 
    BLOCK_NO,
    POSTAL_CODE,
    LATITUDE,
    LONGITUDE,
    GEOMETRY_TYPE
FROM CLEANED_DATA.HDB_EXISTING_BUILDING
LIMIT 10;

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


-- ============================================
-- PRESCHOOLS CLEANING
-- ============================================
USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.PRESCHOOLS_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>CENTRE_NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS centre_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>CENTRE_CODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS centre_code,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    TO_GEOGRAPHY(location:geometry) AS geometry
FROM RAW_DATA.PRESCHOOLS
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total_records FROM CLEANED_DATA.PRESCHOOLS_CLEANED;

-- Check names extracted
SELECT COUNT(*) AS records_with_name
FROM CLEANED_DATA.PRESCHOOLS_CLEANED
WHERE centre_name IS NOT NULL;

-- Preview (without geom column)
SELECT 
    centre_name,
    centre_code,
    ROUND(longitude, 4) AS lon,
    ROUND(latitude, 4) AS lat
FROM CLEANED_DATA.PRESCHOOLS_CLEANED
WHERE centre_name IS NOT NULL
LIMIT 10;


-- ============================================
-- CHAS_CLINICS CLEANING
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.CHAS_CLINICS_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>HCI_NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS clinic_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>HCI_CODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS clinic_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>POSTAL_CD</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>STREET_NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS street_name,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    TO_GEOGRAPHY(location:geometry) AS geometry
FROM RAW_DATA.CHAS_CLINICS
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total_records FROM CLEANED_DATA.CHAS_CLINICS_CLEANED;

SELECT COUNT(*) AS records_with_name
FROM CLEANED_DATA.CHAS_CLINICS_CLEANED
WHERE clinic_name IS NOT NULL;

-- Preview (without geometry column)
SELECT 
    clinic_name,
    clinic_code,
    postal_code,
    street_name,
    ROUND(longitude, 4) AS lon,
    ROUND(latitude, 4) AS lat
FROM CLEANED_DATA.CHAS_CLINICS_CLEANED
WHERE clinic_name IS NOT NULL
LIMIT 10;

-- ============================================
-- SUPERMARKETS CLEANING
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.SUPERMARKETS_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>LIC_NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS business_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>POSTCODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>STR_NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS street_name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>BLK_HOUSE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS block_no,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude,
    TO_GEOGRAPHY(location:geometry) AS geometry
FROM RAW_DATA.SUPERMARKETS
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total_records FROM CLEANED_DATA.SUPERMARKETS_CLEANED;

SELECT COUNT(*) AS records_with_name
FROM CLEANED_DATA.SUPERMARKETS_CLEANED
WHERE business_name IS NOT NULL;

-- Preview (without geometry column)
SELECT 
    business_name,
    postal_code,
    street_name,
    block_no,
    ROUND(longitude, 4) AS lon,
    ROUND(latitude, 4) AS lat
FROM CLEANED_DATA.SUPERMARKETS_CLEANED
WHERE business_name IS NOT NULL
LIMIT 10;


-- ============================================
-- RETAIL_PHARMACY CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.RETAIL_PHARMACY_CLEANED AS
SELECT
    location:properties:PHARMACY_NAME::STRING AS pharmacy_name,
    location:properties:POSTAL_CODE::STRING AS postal_code,
    location:properties:ROAD_NAME::STRING AS road_name,
    location:properties:BUILDING_NAME::STRING AS building_name,
    location:properties:HOUSE_BLK_NO::STRING AS block_no,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.RETAIL_PHARMACY
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) FROM CLEANED_DATA.RETAIL_PHARMACY_CLEANED;

SELECT * FROM CLEANED_DATA.RETAIL_PHARMACY_CLEANED LIMIT 10;


-- ============================================
-- GYMS_SG CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.GYMS_SG_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSPOSTALCODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSSTREETNAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS street_name,
    
    COALESCE(
        REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSBUILDINGNAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1),
        'Not Specified'
    ) AS building_name,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.GYMS_SG
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.GYMS_SG_CLEANED;

SELECT COUNT(*) AS with_name
FROM CLEANED_DATA.GYMS_SG_CLEANED
WHERE name IS NOT NULL;

-- Preview
SELECT * FROM CLEANED_DATA.GYMS_SG_CLEANED LIMIT 10;

-- ============================================
-- ELDERCARE_SERVICES CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.ELDERCARE_SERVICES_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSPOSTALCODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSSTREETNAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS address,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.ELDERCARE_SERVICES
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.ELDERCARE_SERVICES_CLEANED;

SELECT COUNT(*) AS with_name
FROM CLEANED_DATA.ELDERCARE_SERVICES_CLEANED
WHERE name IS NOT NULL;

SELECT * FROM CLEANED_DATA.ELDERCARE_SERVICES_CLEANED LIMIT 10;

-- ============================================
-- HAWKER_CENTRES CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.HAWKER_CENTRES_CLEANED AS
SELECT
    location:properties:NAME::STRING AS name,
    location:properties:ADDRESSPOSTALCODE::STRING AS postal_code,
    location:properties:ADDRESSSTREETNAME::STRING AS street_name,
    
    -- Fix null building names
    COALESCE(location:properties:ADDRESSBUILDINGNAME::STRING, 'Not Specified') AS building_name,
    
    location:properties:ADDRESSBLOCKHOUSENUMBER::STRING AS block_no,
    location:properties:STATUS::STRING AS status,
    
    -- Fix null stall counts (default to 0)
    COALESCE(TRY_TO_NUMBER(location:properties:NUMBER_OF_COOKED_FOOD_STALLS::STRING), 0) AS num_food_stalls,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
    -- Removed geometry column
FROM RAW_DATA.HAWKER_CENTRES
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.HAWKER_CENTRES_CLEANED;

SELECT COUNT(*) AS with_name
FROM CLEANED_DATA.HAWKER_CENTRES_CLEANED
WHERE name IS NOT NULL;

-- Check null fixes
SELECT 
    COUNT(*) AS total,
    COUNT(CASE WHEN building_name = 'Not Specified' THEN 1 END) AS nulls_fixed,
    ROUND(AVG(num_food_stalls), 1) AS avg_stalls
FROM CLEANED_DATA.HAWKER_CENTRES_CLEANED;

-- Preview
SELECT * FROM CLEANED_DATA.HAWKER_CENTRES_CLEANED LIMIT 10;


-- ============================================
-- COMMUNITY_CLUBS CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.COMMUNITY_CLUBS_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSPOSTALCODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSSTREETNAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS street_name,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.COMMUNITY_CLUBS
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.COMMUNITY_CLUBS_CLEANED;

SELECT COUNT(*) AS with_name
FROM CLEANED_DATA.COMMUNITY_CLUBS_CLEANED
WHERE name IS NOT NULL;

-- Preview
SELECT * FROM CLEANED_DATA.COMMUNITY_CLUBS_CLEANED LIMIT 10;

-- ============================================
-- PARKS CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.PARKS_CLEANED AS
SELECT
    location:properties:NAME::STRING AS name,
    TRY_TO_NUMBER(location:properties:OBJECTID::STRING) AS object_id,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.PARKS;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.PARKS_CLEANED;

SELECT 
    COUNT(*) AS total,
    COUNT(CASE WHEN name IS NOT NULL AND name != '' THEN 1 END) AS has_name,
    COUNT(CASE WHEN object_id IS NOT NULL THEN 1 END) AS has_id
FROM CLEANED_DATA.PARKS_CLEANED;

-- Show everything including nulls
SELECT * FROM CLEANED_DATA.PARKS_CLEANED LIMIT 10;

-- Try to see raw data
SELECT 
    location:properties:NAME AS name_raw,
    location:properties:OBJECTID AS id_raw,
    location:geometry:coordinates[0] AS lon,
    location:geometry:coordinates[1] AS lat
FROM RAW_DATA.PARKS
LIMIT 10;

-- ============================================
-- PARKS FINAL 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.PARKS_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS name,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.PARKS
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.PARKS_CLEANED;

-- Preview
SELECT * FROM CLEANED_DATA.PARKS_CLEANED LIMIT 10;


-- ============================================
-- WATER_ACTIVITIES CLEANING 
-- ============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA CLEANED_DATA;

CREATE OR REPLACE TABLE CLEANED_DATA.WATER_ACTIVITIES_CLEANED AS
SELECT
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>NAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS name,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSPOSTALCODE</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS postal_code,
    REGEXP_SUBSTR(location:properties:Description::STRING, '<th>ADDRESSSTREETNAME</th> <td>([^<]+)</td>', 1, 1, 'e', 1) AS street_name,
    
    location:geometry:coordinates[0]::FLOAT AS longitude,
    location:geometry:coordinates[1]::FLOAT AS latitude
FROM RAW_DATA.WATER_ACTIVITIES
WHERE location:geometry:coordinates[0] IS NOT NULL;

-- Verify
SELECT COUNT(*) AS total FROM CLEANED_DATA.WATER_ACTIVITIES_CLEANED;

SELECT COUNT(*) AS with_name
FROM CLEANED_DATA.WATER_ACTIVITIES_CLEANED
WHERE name IS NOT NULL;

-- Preview
SELECT * FROM CLEANED_DATA.WATER_ACTIVITIES_CLEANED LIMIT 10;
