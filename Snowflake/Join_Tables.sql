-- Create Price Master Table Lv
CREATE OR REPLACE TABLE FINAL_DATA.HDB_PRICE_MASTER 
AS
SELECT 
    p.sale_year,
    p.sale_quarter,
    p.sale_month,
    p.address,
    e.postal_code,
    i.resale_index,
    p.resale_price,
    r.min_selling_price,
    m.price AS median_resale_price,
    r.max_selling_price,
    p.town,
    p.flat_type,
    p.storey_range,
    p.flat_model,
    e.year_completed,
    e.max_floor_level,
    p.remaining_lease_years,
    e.latitude,
    e.longitude

FROM FINAL_DATA.HDB_PROPERTY_INFO_ENRICHED e
INNER JOIN FINAL_DATA.HDB_RESALE_PRICES p
ON e.address = p.address
LEFT JOIN FINAL_DATA.HDB_PRICE_RANGE r
ON r.year = p.sale_year
AND UPPER(r.town) = p.town
AND UPPER(r.room_type) = p.flat_type
LEFT JOIN FINAL_DATA.HDB_RESALE_INDEX i
ON i.year = p.sale_year
AND i.quarter = p.sale_quarter
LEFT JOIN FINAL_DATA.HDB_MEDIAN_RESALE_PRICE m
ON m.year = p.sale_year
AND m.quarter = p.sale_quarter
AND m.flat_type = p.flat_type;

-- Create final complete dataset Lv
CREATE OR REPLACE TABLE FINAL_DATA.PROPWISE_MASTER AS
SELECT 
    p.sale_year,
    p.sale_quarter,
    p.sale_month,
    p.postal_code,
    p.address,
    p.resale_index,
    p.resale_price,
    p.min_selling_price,
    p.median_resale_price,
    p.max_selling_price,
    p.town,
    p.flat_type,
    p.storey_range,
    p.flat_model,
    p.year_completed,
    p.max_floor_level,
    p.remaining_lease_years,
    p.latitude,
    p.longitude,
    a.overall_amenity_score,
    a.nearest_mrt_name,
    a.nearest_mrt_distance_m,
    a.mrt_within_500m,
    a.mrt_within_1km,
    a.nearest_is_ns_line,
    a.nearest_is_ew_line,
    a.NEAREST_GYM_DISTANCE_M,
    a.gyms_within_1km,
    a.nearest_hawker_distance_m,
    a.hawkers_within_500m,
    a.hawkers_within_1km,
    a.total_food_stalls_within_1km,
    a.nearest_supermarket_distance_m,
    a.supermarkets_within_500m,
    a.supermarkets_within_1km,
    a.shopping_convenience_score,
    a.nearest_park_distance_m,
    a.parks_within_1km,
    a.nearest_preschool_m,
    a.preschools_within_1km,
    a.nearest_clinic_m,
    a.clinics_within_500m,
    a.nearest_pharmacy_m,
    a.nearest_hospital_m,
    a.healthcare_accessibility_score,
    a.nearest_mall_m
    
FROM FINAL_DATA.HDB_PRICE_MASTER p
LEFT JOIN FINAL_DATA.HDB_MASTER_AMENITY_FEATURES a
ON p.postal_code = a.postal_code;
