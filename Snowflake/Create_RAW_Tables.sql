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
-- VARIANT data type handles semi-structured data like GeoJSON
CREATE OR REPLACE TABLE RAW_DATA.HDB_Existing_Building (
    raw_data VARIANT
);

-- 2. Load GeoJSON file from stage
-- Use STRIP_OUTER_ARRAY=TRUE to parse each feature as a separate row
COPY INTO RAW_DATA.HDB_Existing_Building
FROM @stage_raw/HDBExistingBuilding.geojson
FILE_FORMAT = (
    TYPE = JSON
    STRIP_OUTER_ARRAY = TRUE
)
ON_ERROR = 'CONTINUE';

-- 3. Verify the load
SELECT raw_data FROM RAW_DATA.HDB_Existing_Building LIMIT 5;

