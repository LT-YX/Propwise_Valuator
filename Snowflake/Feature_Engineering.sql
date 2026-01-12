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
