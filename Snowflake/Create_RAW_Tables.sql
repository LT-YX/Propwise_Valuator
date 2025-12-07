-- DO NOT REMOVE
USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA RAW_DATA;
-- CREATE OR REPLACE STAGE RAW_DATA.stage_raw; Has been created DO NOT run again

-- 1. Upload files to stage using Snowflake UI
-- 2. Once file has been uploaded, create table
-- 3. Load data from stage to table

-- HDB Price Range
CREATE OR REPLACE TABLE HDB_Price_Range (
    financial_year STRING,
    town STRING,
    room_type STRING,
    min_selling_price STRING,
    max_selling_price STRING,
    min_selling_price_less_ahg_shg STRING, -- Will remove these unnessary columns later
    max_selling_price_less_ahg_shg STRING
); -- Temporary placeholder type


COPY INTO HDB_Price_Range
FROM @stage_raw/PriceRangeofHDBFlatsOffered.csv
FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1)
ON_ERROR = 'CONTINUE';

-- 

