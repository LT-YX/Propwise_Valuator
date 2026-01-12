USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;

-- HDB_Price_Range - Lv
CREATE OR REPLACE TABLE FINAL_DATA.HDB_Price_Range AS
SELECT * FROM CLEANED_DATA.HDB_Price_Range;

-- HDB Property Info - Lv
CREATE OR REPLACE TABLE FINAL_DATA.HDB_Property_Info AS
SELECT * FROM CLEANED_DATA.HDB_Property_Info;

ALTER TABLE CLEANED_DATA.HDB_Property_Info
ADD COLUMN REMAINING_LEASE NUMBER(3,0) 
AS (99 - (EXTRACT(YEAR FROM CURRENT_DATE()) - YEAR_COMPLETED));

-- HDB Resale Index - Lv
CREATE OR REPLACE TABLE FINAL_DATA.HDB_Resale_Index AS
SELECT * FROM CLEANED_DATA.HDB_Resale_Index;

-- HDB Median Resale Price - Lv
CREATE OR REPLACE TABLE FINAL_DATA.HDB_Median_Resale_Price AS
SELECT * FROM CLEANED_DATA.HDB_Median_Resale_Price;

-- By Alluru Rishitha Reddy
-- Add features to MRT Table
create or replace table GROUP4_ASG2.FINAL_DATA.HDB_MRT_FEATURES as
with hdb as (
    select
        POSTAL_CODE,
        BLOCK_NO,
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as hdb_geo
    from GROUP4_ASG2.CLEANED_DATA.HDB_EXISTING_BUILDING
    where LATITUDE is not null
      and LONGITUDE is not null
),

mrt as (
    select
        STN_NAME,
        LINE_NS,
        LINE_EW,
        LINE_CC,
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as mrt_geo
    from GROUP4_ASG2.CLEANED_DATA.MRT_STATIONS_CLEANED
    where LATITUDE is not null
      and LONGITUDE is not null
),

hdb_mrt_dist as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        m.STN_NAME,
        m.LINE_NS,
        m.LINE_EW,
        m.LINE_CC,
        ST_DISTANCE(h.hdb_geo, m.mrt_geo) as distance_m
    from hdb h
    cross join mrt m
),

ranked_mrt as (
    select
        *,
        row_number() over (
            partition by POSTAL_CODE, BLOCK_NO
            order by distance_m
        ) as rn
    from hdb_mrt_dist
),

counts as (
    select
        POSTAL_CODE,
        BLOCK_NO,
        sum(case when distance_m <= 500 then 1 else 0 end) as MRT_WITHIN_500M,
        sum(case when distance_m <= 1000 then 1 else 0 end) as MRT_WITHIN_1KM
    from hdb_mrt_dist
    group by POSTAL_CODE, BLOCK_NO
)

select
    r.POSTAL_CODE,
    r.BLOCK_NO,
    r.distance_m as NEAREST_MRT_DISTANCE_M,
    r.STN_NAME as NEAREST_MRT_NAME,
    c.MRT_WITHIN_500M,
    c.MRT_WITHIN_1KM,
    r.LINE_NS as NEAREST_IS_NS_LINE,
    r.LINE_EW as NEAREST_IS_EW_LINE,
    r.LINE_CC as NEAREST_IS_CC_LINE
from ranked_mrt r
join counts c
  on r.POSTAL_CODE = c.POSTAL_CODE
 and r.BLOCK_NO = c.BLOCK_NO
where r.rn = 1;

-- Verify
select *
from hdb_mrt_features;

-- Add features to Healthcare Table
create or replace table GROUP4_ASG2.FINAL_DATA.HDB_HEALTHCARE_FEATURES as
with hdb as (
    select
        POSTAL_CODE,
        BLOCK_NO,
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as hdb_geo
    from GROUP4_ASG2.CLEANED_DATA.HDB_EXISTING_BUILDING
    where LATITUDE is not null
      and LONGITUDE is not null
),

clinics as (
    select
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as geo
    from GROUP4_ASG2.CLEANED_DATA.CHAS_CLINICS_CLEANED
    where LATITUDE is not null
      and LONGITUDE is not null
),

pharmacies as (
    select
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as geo
    from GROUP4_ASG2.CLEANED_DATA.RETAIL_PHARMACY_CLEANED
    where LATITUDE is not null
      and LONGITUDE is not null
),

hospitals as (
    select
        TO_GEOGRAPHY(
            'POINT(' || LON || ' ' || LAT || ')'
        ) as geo
    from GROUP4_ASG2.CLEANED_DATA.CLINICS_CLEANED
    where LAT is not null
      and LON is not null
),

clinic_features as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        min(ST_DISTANCE(h.hdb_geo, c.geo)) as NEAREST_CLINIC_M,
        sum(
            case
                when ST_DISTANCE(h.hdb_geo, c.geo) <= 500 then 1
                else 0
            end
        ) as CLINICS_WITHIN_500M
    from hdb h
    cross join clinics c
    group by h.POSTAL_CODE, h.BLOCK_NO
),

pharmacy_features as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        min(ST_DISTANCE(h.hdb_geo, p.geo)) as NEAREST_PHARMACY_M
    from hdb h
    cross join pharmacies p
    group by h.POSTAL_CODE, h.BLOCK_NO
),

hospital_features as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        min(ST_DISTANCE(h.hdb_geo, ho.geo)) as NEAREST_HOSPITAL_M
    from hdb h
    cross join hospitals ho
    group by h.POSTAL_CODE, h.BLOCK_NO
)

select
    h.POSTAL_CODE,
    h.BLOCK_NO,

    cf.NEAREST_CLINIC_M,
    cf.CLINICS_WITHIN_500M,
    pf.NEAREST_PHARMACY_M,
    hf.NEAREST_HOSPITAL_M,

    least(
        100,
        round(
              (500 / nullif(cf.NEAREST_CLINIC_M, 0)) * 30
            + (cf.CLINICS_WITHIN_500M * 5)
            + (500 / nullif(pf.NEAREST_PHARMACY_M, 0)) * 25
            + (1000 / nullif(hf.NEAREST_HOSPITAL_M, 0)) * 40
        )
    ) as HEALTHCARE_ACCESSIBILITY_SCORE

from hdb h
left join clinic_features cf
    on h.POSTAL_CODE = cf.POSTAL_CODE
   and h.BLOCK_NO = cf.BLOCK_NO
left join pharmacy_features pf
    on h.POSTAL_CODE = pf.POSTAL_CODE
   and h.BLOCK_NO = pf.BLOCK_NO
left join hospital_features hf
    on h.POSTAL_CODE = hf.POSTAL_CODE
   and h.BLOCK_NO = hf.BLOCK_NO;


-- Verify
select *
from hdb_healthcare_features;

-- Add Shopping Features Table
create or replace table GROUP4_ASG2.FINAL_DATA.HDB_SHOPPING_FEATURES as
with hdb as (
    select
        POSTAL_CODE,
        BLOCK_NO,
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as hdb_geo
    from GROUP4_ASG2.CLEANED_DATA.HDB_EXISTING_BUILDING
    where LATITUDE is not null
      and LONGITUDE is not null
),

malls as (
    select
        TO_GEOGRAPHY(
            'POINT(' || LON || ' ' || LAT || ')'
        ) as geo
    from GROUP4_ASG2.CLEANED_DATA.SHOPPING_MALLS_CLEANED
    where LAT is not null
      and LON is not null
),

supermarkets as (
    select
        TO_GEOGRAPHY(
            'POINT(' || LONGITUDE || ' ' || LATITUDE || ')'
        ) as geo
    from GROUP4_ASG2.CLEANED_DATA.SUPERMARKETS_CLEANED
    where LATITUDE is not null
      and LONGITUDE is not null
),

mall_features as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        min(ST_DISTANCE(h.hdb_geo, m.geo)) as NEAREST_MALL_M
    from hdb h
    cross join malls m
    group by h.POSTAL_CODE, h.BLOCK_NO
),

supermarket_features as (
    select
        h.POSTAL_CODE,
        h.BLOCK_NO,
        min(ST_DISTANCE(h.hdb_geo, s.geo)) as NEAREST_SUPERMARKET_DISTANCE_M,
        sum(
            case
                when ST_DISTANCE(h.hdb_geo, s.geo) <= 500 then 1
                else 0
            end
        ) as SUPERMARKETS_WITHIN_500M
    from hdb h
    cross join supermarkets s
    group by h.POSTAL_CODE, h.BLOCK_NO
)

select
    h.POSTAL_CODE,
    h.BLOCK_NO,

    mf.NEAREST_MALL_M,
    sf.NEAREST_SUPERMARKET_DISTANCE_M,
    sf.SUPERMARKETS_WITHIN_500M,
    
    least(
        100,
        round(
              (1000 / nullif(mf.NEAREST_MALL_M, 0)) * 50
            + (500 / nullif(sf.NEAREST_SUPERMARKET_DISTANCE_M, 0)) * 30
            + (sf.SUPERMARKETS_WITHIN_500M * 5)
        )
    ) as SHOPPING_CONVENIENCE_SCORE

from hdb h
left join mall_features mf
    on h.POSTAL_CODE = mf.POSTAL_CODE
   and h.BLOCK_NO = mf.BLOCK_NO
left join supermarket_features sf
    on h.POSTAL_CODE = sf.POSTAL_CODE
   and h.BLOCK_NO = sf.BLOCK_NO;

-- Verify
select *
from HDB_SHOPPING_FEATURES;

-- Merge Amenities to Master Table
create or replace table GROUP4_ASG2.FINAL_DATA.HDB_MASTER_AMENITY_FEATURES as

select
    hdb.POSTAL_CODE,
    hdb.BLOCK_NO,
    hdb.STREET_CODE,
    gym.NEAREST_GYM_DISTANCE_M,
    coalesce(gym.GYMS_WITHIN_1KM, 0) as GYMS_WITHIN_1KM,
    hawker.NEAREST_HAWKER_DISTANCE_M,
    coalesce(hawker.HAWKERS_WITHIN_500M, 0) as HAWKERS_WITHIN_500M,
    coalesce(hawker.HAWKERS_WITHIN_1KM, 0) as HAWKERS_WITHIN_1KM,
    coalesce(hawker.TOTAL_STALLS_WITHIN_1KM, 0) as TOTAL_FOOD_STALLS_WITHIN_1KM,
    mrt.NEAREST_MRT_DISTANCE_M,
    mrt.NEAREST_MRT_NAME,
    coalesce(mrt.MRT_WITHIN_500M, 0) as MRT_WITHIN_500M,
    coalesce(mrt.MRT_WITHIN_1KM, 0) as MRT_WITHIN_1KM,
    coalesce(mrt.NEAREST_IS_NS_LINE, 0) as NEAREST_IS_NS_LINE,
    coalesce(mrt.NEAREST_IS_EW_LINE, 0) as NEAREST_IS_EW_LINE,
    sup.NEAREST_SUPERMARKET_DISTANCE_M,
    coalesce(sup.SUPERMARKETS_WITHIN_500M, 0) as SUPERMARKETS_WITHIN_500M,
    coalesce(sup.SUPERMARKETS_WITHIN_1KM, 0) as SUPERMARKETS_WITHIN_1KM,
    coalesce(shop.SHOPPING_CONVENIENCE_SCORE, 0) as SHOPPING_CONVENIENCE_SCORE,
    park.NEAREST_PARK_DISTANCE_M,
    coalesce(park.PARKS_WITHIN_1KM, 0) as PARKS_WITHIN_1KM,
    pre.NEAREST_PRESCHOOL_DISTANCE_M as NEAREST_PRESCHOOL_M,
    coalesce(pre.PRESCHOOLS_WITHIN_1KM, 0) as PRESCHOOLS_WITHIN_1KM,
    hc.NEAREST_CLINIC_M,
    hc.NEAREST_PHARMACY_M,
    hc.NEAREST_HOSPITAL_M,
    coalesce(hc.CLINICS_WITHIN_500M, 0) as CLINICS_WITHIN_500M,
    coalesce(hc.HEALTHCARE_ACCESSIBILITY_SCORE, 0) as HEALTHCARE_ACCESSIBILITY_SCORE,
    shop.NEAREST_MALL_M,
    round(
          coalesce(shop.SHOPPING_CONVENIENCE_SCORE, 0) * 0.25
        + coalesce(hc.HEALTHCARE_ACCESSIBILITY_SCORE, 0) * 0.25
        + (case
              when mrt.NEAREST_MRT_DISTANCE_M <= 500 then 100
              when mrt.NEAREST_MRT_DISTANCE_M <= 1000 then 70
              else 40
          end) * 0.20
        + (case
              when hawker.HAWKERS_WITHIN_500M > 0 then 100
              when hawker.HAWKERS_WITHIN_1KM > 0 then 70
              else 40
          end) * 0.15
        + (case
              when park.PARKS_WITHIN_1KM > 0 then 100
              else 60
          end) * 0.15
    , 2) as OVERALL_AMENITY_SCORE

from GROUP4_ASG2.CLEANED_DATA.HDB_EXISTING_BUILDING hdb
left join GROUP4_ASG2.FINAL_DATA.HDB_GYM_FEATURES gym
    on hdb.POSTAL_CODE = gym.POSTAL_CODE
   and hdb.BLOCK_NO = gym.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_HAWKER_FEATURES hawker
    on hdb.POSTAL_CODE = hawker.POSTAL_CODE
   and hdb.BLOCK_NO = hawker.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_MRT_FEATURES mrt
    on hdb.POSTAL_CODE = mrt.POSTAL_CODE
   and hdb.BLOCK_NO = mrt.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_SUPERMARKET_FEATURES sup
    on hdb.POSTAL_CODE = sup.POSTAL_CODE
   and hdb.BLOCK_NO = sup.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_SHOPPING_FEATURES shop
    on hdb.POSTAL_CODE = shop.POSTAL_CODE
   and hdb.BLOCK_NO = shop.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_PARK_FEATURES park
    on hdb.POSTAL_CODE = park.POSTAL_CODE
   and hdb.BLOCK_NO = park.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_PRESCHOOL_FEATURES pre
    on hdb.POSTAL_CODE = pre.POSTAL_CODE
   and hdb.BLOCK_NO = pre.BLOCK_NO
left join GROUP4_ASG2.FINAL_DATA.HDB_HEALTHCARE_FEATURES hc
    on hdb.POSTAL_CODE = hc.POSTAL_CODE
   and hdb.BLOCK_NO = hc.BLOCK_NO;

-- Verify
select *
from GROUP4_ASG2.FINAL_DATA.HDB_MASTER_AMENITY_FEATURES;






-- =============================================
-- SCRIPT: HDB Amenities Feature Engineering - geojson
-- AUTHOR: Teo Hong Yi
-- DATE CREATED: 2026-01-11
-- LAST MODIFIED: 2026-01-11
-- =============================================

USE WAREHOUSE GROUP4_ASG2;
USE DATABASE Group4_Asg2;
USE SCHEMA FINAL_DATA;


-- =============================================
-- FEATURE SET 1: PRESCHOOL ACCESSIBILITY
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_PRESCHOOL_FEATURES AS
WITH hdb_preschool_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        preschool.centre_name,
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(preschool.longitude, preschool.latitude)
        ) AS distance_meters,
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(preschool.longitude, preschool.latitude)
            )
        ) AS rank
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.PRESCHOOLS_CLEANED preschool
    WHERE hdb.geometry IS NOT NULL
        AND preschool.longitude IS NOT NULL
        AND preschool.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    ROUND(MIN(CASE WHEN rank = 1 THEN distance_meters END), 2) AS nearest_preschool_distance_m,
    MIN(CASE WHEN rank = 1 THEN centre_name END) AS nearest_preschool_name,
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS preschools_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS preschools_within_1km,
    ROUND(AVG(CASE WHEN rank <= 3 THEN distance_meters END), 2) AS avg_distance_top3_preschools
FROM hdb_preschool_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

SELECT 'PRESCHOOL_FEATURES' AS feature_set, COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_PRESCHOOL_FEATURES;


-- =============================================
-- FEATURE SET 2: CLINIC ACCESSIBILITY
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_CLINIC_FEATURES AS
WITH hdb_clinic_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        clinic.clinic_name,
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(clinic.longitude, clinic.latitude)
        ) AS distance_meters,
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(clinic.longitude, clinic.latitude)
            )
        ) AS rank
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.CHAS_CLINICS_CLEANED clinic
    WHERE hdb.geometry IS NOT NULL
        AND clinic.longitude IS NOT NULL
        AND clinic.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    ROUND(MIN(CASE WHEN rank = 1 THEN distance_meters END), 2) AS nearest_clinic_distance_m,
    MIN(CASE WHEN rank = 1 THEN clinic_name END) AS nearest_clinic_name,
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS clinics_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS clinics_within_1km,
    ROUND(AVG(CASE WHEN rank <= 3 THEN distance_meters END), 2) AS avg_distance_top3_clinics
FROM hdb_clinic_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

SELECT 'CLINIC_FEATURES' AS feature_set, COUNT(*) AS hdb_blocks
FROM FINAL_DATA.HDB_CLINIC_FEATURES;


-- =============================================
-- FEATURE SET 3: SUPERMARKET ACCESSIBILITY
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_SUPERMARKET_FEATURES AS
WITH hdb_supermarket_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        supermarket.business_name,
        CASE 
            WHEN supermarket.business_name LIKE '%NTUC FAIRPRICE%' THEN 'NTUC FairPrice'
            WHEN supermarket.business_name LIKE '%SHENG SIONG%' THEN 'Sheng Siong'
            WHEN supermarket.business_name LIKE '%COLD STORAGE%' THEN 'Cold Storage'
            WHEN supermarket.business_name LIKE '%PRIME%' THEN 'Prime'
            ELSE 'Others'
        END AS supermarket_chain,
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(supermarket.longitude, supermarket.latitude)
        ) AS distance_meters,
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(supermarket.longitude, supermarket.latitude)
            )
        ) AS rank
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.SUPERMARKETS_CLEANED supermarket
    WHERE hdb.geometry IS NOT NULL
        AND supermarket.longitude IS NOT NULL
        AND supermarket.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    ROUND(MIN(CASE WHEN rank = 1 THEN distance_meters END), 2) AS nearest_supermarket_distance_m,
    MIN(CASE WHEN rank = 1 THEN business_name END) AS nearest_supermarket_name,
    MIN(CASE WHEN rank = 1 THEN supermarket_chain END) AS nearest_supermarket_chain,
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS supermarkets_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS supermarkets_within_1km,
    MAX(CASE WHEN distance_meters <= 500 AND supermarket_chain = 'NTUC FairPrice' THEN 1 ELSE 0 END) AS has_fairprice_nearby,
    MAX(CASE WHEN distance_meters <= 500 AND supermarket_chain = 'Sheng Siong' THEN 1 ELSE 0 END) AS has_shengsiong_nearby,
    MAX(CASE WHEN distance_meters <= 500 AND supermarket_chain = 'Cold Storage' THEN 1 ELSE 0 END) AS has_coldstorage_nearby,
    MAX(CASE WHEN distance_meters <= 500 AND supermarket_chain = 'Prime' THEN 1 ELSE 0 END) AS has_prime_nearby,
    ROUND(AVG(CASE WHEN rank <= 3 THEN distance_meters END), 2) AS avg_distance_top3_supermarkets
FROM hdb_supermarket_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

SELECT 'SUPERMARKET_FEATURES' AS feature_set, COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_SUPERMARKET_FEATURES;


-- =============================================
-- FEATURE SET 4: PHARMACY ACCESSIBILITY (CORRECTED)
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_PHARMACY_FEATURES AS
WITH hdb_pharmacy_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        pharmacy.pharmacy_name,
        
        -- Improved categorization with better pattern matching
        CASE 
            WHEN UPPER(pharmacy.pharmacy_name) LIKE '%WATSON%' THEN 'Watsons'
            WHEN UPPER(pharmacy.pharmacy_name) LIKE '%GUARDIAN%' THEN 'Guardian'
            WHEN UPPER(pharmacy.pharmacy_name) LIKE '%UNITY%' THEN 'Unity'
            WHEN UPPER(pharmacy.pharmacy_name) LIKE '%GUARDIAN HEALTH%' THEN 'Guardian'
            ELSE 'Others'
        END AS pharmacy_chain,
        
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(pharmacy.longitude, pharmacy.latitude)
        ) AS distance_meters,
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(pharmacy.longitude, pharmacy.latitude)
            )
        ) AS rank
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.RETAIL_PHARMACY_CLEANED pharmacy
    WHERE hdb.geometry IS NOT NULL
        AND pharmacy.longitude IS NOT NULL
        AND pharmacy.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    ROUND(MIN(CASE WHEN rank = 1 THEN distance_meters END), 2) AS nearest_pharmacy_distance_m,
    MIN(CASE WHEN rank = 1 THEN pharmacy_name END) AS nearest_pharmacy_name,
    MIN(CASE WHEN rank = 1 THEN pharmacy_chain END) AS nearest_pharmacy_chain,
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS pharmacies_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS pharmacies_within_1km,
    MAX(CASE WHEN distance_meters <= 500 AND pharmacy_chain = 'Watsons' THEN 1 ELSE 0 END) AS has_watsons_nearby,
    MAX(CASE WHEN distance_meters <= 500 AND pharmacy_chain = 'Guardian' THEN 1 ELSE 0 END) AS has_guardian_nearby,
    MAX(CASE WHEN distance_meters <= 500 AND pharmacy_chain = 'Unity' THEN 1 ELSE 0 END) AS has_unity_nearby,
    ROUND(AVG(CASE WHEN rank <= 3 THEN distance_meters END), 2) AS avg_distance_top3_pharmacies
FROM hdb_pharmacy_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

SELECT 'PHARMACY_FEATURES' AS feature_set, COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_PHARMACY_FEATURES;

-- =============================================
-- FEATURE SET 5: GYM ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics, density counts, and brand presence for gyms
-- OUTPUT: HDB_GYM_FEATURES table
-- BUSINESS CONTEXT: 
--   Gym accessibility promotes healthy lifestyle and is increasingly important for residents.
--   Major chains in Singapore include ClubFITT, Anytime Fitness, ActiveSG, and various boutique studios.
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_GYM_FEATURES AS
WITH hdb_gym_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        gym.name AS gym_name,
        
        -- Categorize gym chains/types for brand preference analysis
        CASE 
            WHEN gym.name LIKE '%CLUBFITT%' THEN 'ClubFITT'
            WHEN gym.name LIKE '%ANYTIME FITNESS%' THEN 'Anytime Fitness'
            WHEN gym.name LIKE '%ACTIVESG%' THEN 'ActiveSG'
            WHEN gym.name LIKE '%FITNESS FIRST%' THEN 'Fitness First'
            WHEN gym.name LIKE '%YOGA%' THEN 'Yoga Studio'
            WHEN gym.name LIKE '%CROSSFIT%' THEN 'CrossFit'
            ELSE 'Others'
        END AS gym_type,
        
        -- Calculate geospatial distance from HDB polygon centroid to gym point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(gym.longitude, gym.latitude)
        ) AS distance_meters,
        
        -- Rank gyms by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(gym.longitude, gym.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.GYMS_SG_CLEANED gym
    WHERE hdb.geometry IS NOT NULL
        AND gym.longitude IS NOT NULL
        AND gym.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest gym
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_gym_distance_m,
    MIN(CASE WHEN rank = 1 THEN gym_name END) AS nearest_gym_name,
    MIN(CASE WHEN rank = 1 THEN gym_type END) AS nearest_gym_type,
    
    -- Density metrics: count of gyms within buffer zones
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS gyms_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS gyms_within_1km,
    
    -- Type presence flags: binary indicators for major gym types within 500m
    MAX(
        CASE 
            WHEN distance_meters <= 500 
                AND gym_type = 'ClubFITT' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_clubfitt_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 500 
                AND gym_type = 'Anytime Fitness' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_anytimefitness_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 500 
                AND gym_type = 'ActiveSG' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_activesg_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 500 
                AND gym_type = 'Yoga Studio' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_yoga_nearby,
    
    -- Average distance to top 3 nearest gyms (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_gyms
    
FROM hdb_gym_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'GYM_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_GYM_FEATURES;

-- =============================================
-- FEATURE SET 6: ELDERCARE SERVICES ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics and density counts for eldercare services
-- OUTPUT: HDB_ELDERCARE_FEATURES table
-- BUSINESS CONTEXT: 
--   Eldercare services accessibility is crucial for Singapore's aging population.
--   Includes Senior Activity Centres (SAC) and various community eldercare facilities.
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_ELDERCARE_FEATURES AS
WITH hdb_eldercare_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        eldercare.name AS eldercare_name,
        
        -- Categorize eldercare service types for analysis
        CASE 
            WHEN UPPER(eldercare.name) LIKE '%SENIOR ACTIVITY CENTRE%' 
                OR UPPER(eldercare.name) LIKE '%SAC%' THEN 'Senior Activity Centre'
            WHEN UPPER(eldercare.name) LIKE '%DAY CARE%' 
                OR UPPER(eldercare.name) LIKE '%DAYCARE%' THEN 'Day Care Centre'
            WHEN UPPER(eldercare.name) LIKE '%BEFRIENDERS%' THEN 'Befrienders'
            WHEN UPPER(eldercare.name) LIKE '%SILVER ACE%' THEN 'Silver ACE'
            ELSE 'Others'
        END AS eldercare_type,
        
        -- Calculate geospatial distance from HDB polygon centroid to eldercare point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(eldercare.longitude, eldercare.latitude)
        ) AS distance_meters,
        
        -- Rank eldercare services by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(eldercare.longitude, eldercare.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.ELDERCARE_SERVICES_CLEANED eldercare
    WHERE hdb.geometry IS NOT NULL
        AND eldercare.longitude IS NOT NULL
        AND eldercare.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest eldercare service
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_eldercare_distance_m,
    MIN(CASE WHEN rank = 1 THEN eldercare_name END) AS nearest_eldercare_name,
    MIN(CASE WHEN rank = 1 THEN eldercare_type END) AS nearest_eldercare_type,
    
    -- Density metrics: count of eldercare services within buffer zones
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS eldercare_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS eldercare_within_1km,
    
    -- Type presence flags: binary indicators for service types within 1km (wider radius for eldercare)
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND eldercare_type = 'Senior Activity Centre' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_sac_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND eldercare_type = 'Day Care Centre' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_daycare_nearby,
    
    -- Average distance to top 3 nearest eldercare services (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_eldercare
    
FROM hdb_eldercare_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'ELDERCARE_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_ELDERCARE_FEATURES;


-- =============================================
-- FEATURE SET 7: HAWKER CENTRE ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics, density counts, and size indicators for hawker centres
-- OUTPUT: HDB_HAWKER_FEATURES table
-- BUSINESS CONTEXT: 
--   Hawker centres are iconic to Singapore's food culture and provide affordable dining options.
--   Only "Existing" centres are considered operational; under construction centres are excluded.
--   Number of food stalls indicates the size and variety available.
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_HAWKER_FEATURES AS
WITH hdb_hawker_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        hawker.name AS hawker_name,
        hawker.status,
        hawker.num_food_stalls,
        
        -- Categorize hawker centres by size (number of stalls)
        CASE 
            WHEN hawker.num_food_stalls >= 80 THEN 'Large (80+ stalls)'
            WHEN hawker.num_food_stalls >= 40 THEN 'Medium (40-79 stalls)'
            WHEN hawker.num_food_stalls > 0 THEN 'Small (<40 stalls)'
            ELSE 'Unknown'
        END AS hawker_size,
        
        -- Calculate geospatial distance from HDB polygon centroid to hawker point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(hawker.longitude, hawker.latitude)
        ) AS distance_meters,
        
        -- Rank hawker centres by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(hawker.longitude, hawker.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.HAWKER_CENTRES_CLEANED hawker
    WHERE hdb.geometry IS NOT NULL
        AND hawker.longitude IS NOT NULL
        AND hawker.latitude IS NOT NULL
        -- Only count existing operational hawker centres
        AND (hawker.status LIKE '%Existing%' OR hawker.status = 'Existing')
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest hawker centre
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_hawker_distance_m,
    MIN(CASE WHEN rank = 1 THEN hawker_name END) AS nearest_hawker_name,
    MIN(CASE WHEN rank = 1 THEN hawker_size END) AS nearest_hawker_size,
    MIN(CASE WHEN rank = 1 THEN num_food_stalls END) AS nearest_hawker_stalls,
    
    -- Density metrics: count of hawker centres within buffer zones
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS hawkers_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS hawkers_within_1km,
    
    -- Size-based flags: binary indicators for large hawker centres nearby
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND num_food_stalls >= 80 
            THEN 1 
            ELSE 0 
        END
    ) AS has_large_hawker_nearby,
    
    -- Total stalls within 1km (indicates food variety in vicinity)
    SUM(CASE WHEN distance_meters <= 1000 THEN num_food_stalls ELSE 0 END) AS total_stalls_within_1km,
    
    -- Average distance to top 3 nearest hawker centres (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_hawkers
    
FROM hdb_hawker_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'HAWKER_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_HAWKER_FEATURES;

-- =============================================
-- FEATURE SET 8: COMMUNITY CLUB ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics and density counts for community clubs
-- OUTPUT: HDB_CC_FEATURES table
-- BUSINESS CONTEXT: 
--   Community Clubs (CCs) are social and recreational hubs providing programs, 
--   facilities, and events for residents. They foster community bonding and 
--   offer various activities from sports to lifelong learning.
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_CC_FEATURES AS
WITH hdb_cc_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        cc.name AS cc_name,
        
        -- Categorize CC status (operational vs under construction)
        CASE 
            WHEN UPPER(cc.name) LIKE '%U/C%' 
                OR UPPER(cc.name) LIKE '%UNDER CONSTRUCTION%' 
                OR UPPER(cc.name) LIKE '%PENDING%' THEN 'Under Construction'
            ELSE 'Operational'
        END AS cc_status,
        
        -- Calculate geospatial distance from HDB polygon centroid to CC point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(cc.longitude, cc.latitude)
        ) AS distance_meters,
        
        -- Rank community clubs by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(cc.longitude, cc.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.COMMUNITY_CLUBS_CLEANED cc
    WHERE hdb.geometry IS NOT NULL
        AND cc.longitude IS NOT NULL
        AND cc.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest community club
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_cc_distance_m,
    MIN(CASE WHEN rank = 1 THEN cc_name END) AS nearest_cc_name,
    MIN(CASE WHEN rank = 1 THEN cc_status END) AS nearest_cc_status,
    
    -- Density metrics: count of CCs within buffer zones
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS ccs_within_1km,
    COUNT(CASE WHEN distance_meters <= 2000 THEN 1 END) AS ccs_within_2km,
    
    -- Operational CC nearby flag (exclude under construction)
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND cc_status = 'Operational' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_operational_cc_nearby,
    
    -- Average distance to top 3 nearest community clubs (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_ccs
    
FROM hdb_cc_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'CC_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_CC_FEATURES;


-- =============================================
-- FEATURE SET 9: PARK ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics and density counts for parks
-- OUTPUT: HDB_PARK_FEATURES table
-- BUSINESS CONTEXT: 
--   Parks provide green spaces for recreation, exercise, and mental well-being.
--   Proximity to parks enhances quality of life and property value.
--   Parks are categorized by type (reservoir, waterway, town, national parks).
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_PARK_FEATURES AS
WITH hdb_park_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        park.name AS park_name,
        
        -- Categorize parks by type based on name
        CASE 
            WHEN UPPER(park.name) LIKE '%RESERVOIR%' THEN 'Reservoir Park'
            WHEN UPPER(park.name) LIKE '%WATERWAY%' THEN 'Waterway Park'
            WHEN UPPER(park.name) LIKE '%TOWN PARK%' THEN 'Town Park'
            WHEN UPPER(park.name) LIKE '%BOTANIC%' 
                OR UPPER(park.name) LIKE '%GARDENS BY THE BAY%' THEN 'Botanical Garden'
            WHEN UPPER(park.name) LIKE '%BEACH%' THEN 'Beach Park'
            WHEN UPPER(park.name) LIKE '%CENTRAL PARK%' 
                OR UPPER(park.name) LIKE '%REGIONAL%' THEN 'Central/Regional Park'
            ELSE 'Neighborhood Park'
        END AS park_type,
        
        -- Calculate geospatial distance from HDB polygon centroid to park point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(park.longitude, park.latitude)
        ) AS distance_meters,
        
        -- Rank parks by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(park.longitude, park.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.PARKS_CLEANED park
    WHERE hdb.geometry IS NOT NULL
        AND park.longitude IS NOT NULL
        AND park.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest park
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_park_distance_m,
    MIN(CASE WHEN rank = 1 THEN park_name END) AS nearest_park_name,
    MIN(CASE WHEN rank = 1 THEN park_type END) AS nearest_park_type,
    
    -- Density metrics: count of parks within buffer zones
    COUNT(CASE WHEN distance_meters <= 500 THEN 1 END) AS parks_within_500m,
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS parks_within_1km,
    COUNT(CASE WHEN distance_meters <= 2000 THEN 1 END) AS parks_within_2km,
    
    -- Special park type flags within reasonable distance (1km)
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND park_type = 'Reservoir Park' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_reservoir_park_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 1000 
                AND park_type = 'Waterway Park' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_waterway_park_nearby,
    
    -- Average distance to top 3 nearest parks (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_parks
    
FROM hdb_park_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'PARK_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_PARK_FEATURES;


-- =============================================
-- FEATURE SET 10: WATER ACTIVITIES ACCESSIBILITY
-- =============================================
-- PURPOSE: Calculate distance metrics and density counts for water activity facilities
-- OUTPUT: HDB_WATER_ACTIVITIES_FEATURES table
-- BUSINESS CONTEXT: 
--   Water activity facilities include swimming complexes and sports/recreation centres with pools.
--   Swimming is a popular sport in tropical Singapore, important for fitness and recreation.
--   Facilities categorized by type (swimming complex, sports centre, water venture).
-- =============================================

CREATE OR REPLACE TABLE FINAL_DATA.HDB_WATER_ACTIVITIES_FEATURES AS
WITH hdb_water_distances AS (
    SELECT 
        hdb.postal_code,
        hdb.block_no,
        hdb.latitude AS hdb_latitude,
        hdb.longitude AS hdb_longitude,
        water.name AS facility_name,
        
        -- Categorize water facilities by type
        CASE 
            WHEN UPPER(water.name) LIKE '%SWIMMING COMPLEX%' THEN 'Swimming Complex'
            WHEN UPPER(water.name) LIKE '%WATER-VENTURE%' 
                OR UPPER(water.name) LIKE '%WATER VENTURE%' THEN 'Water Venture'
            WHEN UPPER(water.name) LIKE '%SPORTS AND RECREATION CENTRE%' 
                OR UPPER(water.name) LIKE '%SPORTS & RECREATION CENTRE%' THEN 'Sports & Recreation Centre'
            WHEN UPPER(water.name) LIKE '%AQUATIC CENTRE%' THEN 'Aquatic Centre'
            ELSE 'Other Water Facility'
        END AS facility_type,
        
        -- Calculate geospatial distance from HDB polygon centroid to facility point
        ST_DISTANCE(
            hdb.geometry, 
            ST_POINT(water.longitude, water.latitude)
        ) AS distance_meters,
        
        -- Rank water facilities by distance for each HDB block
        ROW_NUMBER() OVER (
            PARTITION BY hdb.postal_code 
            ORDER BY ST_DISTANCE(
                hdb.geometry, 
                ST_POINT(water.longitude, water.latitude)
            )
        ) AS rank
        
    FROM CLEANED_DATA.HDB_EXISTING_BUILDING_CLEANED hdb
    CROSS JOIN CLEANED_DATA.WATER_ACTIVITIES_CLEANED water
    WHERE hdb.geometry IS NOT NULL
        AND water.longitude IS NOT NULL
        AND water.latitude IS NOT NULL
)
SELECT 
    postal_code,
    block_no,
    MAX(hdb_latitude) AS hdb_latitude,
    MAX(hdb_longitude) AS hdb_longitude,
    
    -- Distance features to nearest water facility
    ROUND(
        MIN(CASE WHEN rank = 1 THEN distance_meters END), 
        2
    ) AS nearest_water_facility_distance_m,
    MIN(CASE WHEN rank = 1 THEN facility_name END) AS nearest_water_facility_name,
    MIN(CASE WHEN rank = 1 THEN facility_type END) AS nearest_water_facility_type,
    
    -- Density metrics: count of water facilities within buffer zones
    COUNT(CASE WHEN distance_meters <= 1000 THEN 1 END) AS water_facilities_within_1km,
    COUNT(CASE WHEN distance_meters <= 2000 THEN 1 END) AS water_facilities_within_2km,
    
    -- Facility type flags within reasonable distance (2km for swimming)
    MAX(
        CASE 
            WHEN distance_meters <= 2000 
                AND facility_type = 'Swimming Complex' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_swimming_complex_nearby,
    
    MAX(
        CASE 
            WHEN distance_meters <= 2000 
                AND facility_type = 'Sports & Recreation Centre' 
            THEN 1 
            ELSE 0 
        END
    ) AS has_sports_centre_nearby,
    
    -- Average distance to top 3 nearest water facilities (redundancy measure)
    ROUND(
        AVG(CASE WHEN rank <= 3 THEN distance_meters END), 
        2
    ) AS avg_distance_top3_water_facilities
    
FROM hdb_water_distances
WHERE rank <= 10
GROUP BY postal_code, block_no;

-- Verify row count
SELECT 
    'WATER_ACTIVITIES_FEATURES' AS feature_set, 
    COUNT(*) AS hdb_blocks 
FROM FINAL_DATA.HDB_WATER_ACTIVITIES_FEATURES;
