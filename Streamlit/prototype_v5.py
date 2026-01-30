# Import python packages
import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
# import requests
import numpy as np
import pydeck as pdk
import joblib
import gzip
import xgboost as xgb
from snowflake.snowpark.files import SnowflakeFile
import os
MAPBOX_API_KEY = "pk.eyJ1IjoibHZ0eXgiLCJhIjoiY21rcGpnNDFiMGRydDNlc2FhdXh2aW83NCJ9._zkoXyM6FbILkvw6RfM3UQ"
os.environ['MAPBOX_API_KEY'] = MAPBOX_API_KEY

# Streamlit Page Setup
st.set_page_config(
    page_title="PropWise Smart Valuator",
    page_icon="🏠",
    layout="wide",
)

# Custom styling for red and white theme 
st.markdown("""
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
        
        /* 1. GLOBAL BACKGROUNDS */
        .stApp, [data-testid="stAppViewContainer"], [data-testid="stHeader"] {
            background-color: #FDFBF0 !important; 
            font-family: 'Inter', sans-serif;
        }

        /* 2. SIDEBAR CONTROL PANEL */
        [data-testid="stSidebar"] {
            background-color: #FDFBF0 !important; 
            border-right: 1px solid #800000 !important;
        }
        
        [data-testid="stSidebar"] p, [data-testid="stSidebar"] span, [data-testid="stSidebar"] label, [data-testid="stSidebar"] h1, [data-testid="stSidebar"] h2 {
            color: #800000 !important;
        }

        div[data-testid="stRadio"] label[data-selected="true"] p {
            color: #FFFFFF !important;
            background-color: #800000;
            border-radius: 6px;
            padding: 4px 12px;
            width: 100%;
        }

        [data-testid="stSidebar"] div.stAlert {
            background-color: #800000 !important;
            color: #FFFFFF !important;
            border: 1px solid #5C0000 !important;
            border-radius: 12px !important;
        }
        [data-testid="stSidebar"] div.stAlert p {
            color: #FFFFFF !important;
        }

        /* 3. MAIN PAGE LABELS & HEADERS */
        h1, h2, h3, h4, .stMarkdown {
            color: #800000 !important;
        }
        
        label[data-testid="stWidgetLabel"] p {
            color: #800000 !important;
            font-weight: 600 !important;
        }

        /* 4. DROPDOWNS & INPUT BOXES */
        div[data-baseweb="select"] > div, 
        div[data-baseweb="input"] > div,
        div[data-testid="stNumberInput"] > div,
        div[data-testid="stTextInput"] > div {
            background-color: #800000 !important;
            border: 1px solid #5C0000 !important;
            border-radius: 8px !important;
        }

        input, div[data-baseweb="select"] * {
            color: #FFFFFF !important;
            -webkit-text-fill-color: #FFFFFF !important;
        }

        div[data-baseweb="popover"] ul {
            background-color: #800000 !important;
            border: 1px solid #5C0000 !important;
        }
        div[data-baseweb="popover"] li {
            background-color: #800000 !important;
            color: #FFFFFF !important;
        }
        div[data-baseweb="popover"] li:hover {
            background-color: #5C0000 !important;
        }

        /* 5. BUTTONS & ICONS */
        .stButton>button {
            background-color: #800000 !important;
            color: #FFFFFF !important;
            border: 2px solid #FDFBF0 !important;
            border-radius: 10px;
            width: 100%;
            font-weight: 600 !important;
            padding: 0.6rem 0 !important;
        }
        .stButton>button:hover {
            background-color: #5C0000 !important;
            border-color: #FFFFFF !important;
        }

        div[data-testid="stNumberInput"] button {
            background-color: #800000 !important;
            border: none !important;
        }
        div[data-testid="stNumberInput"] button svg {
            fill: #FFFFFF !important;
        }

        /* 6. EXPANDERS */
        .streamlit-expanderHeader {
            background-color: #800000 !important;
            color: #FFFFFF !important;
            border-radius: 8px !important;
        }
        .streamlit-expanderHeader svg {
            fill: #FFFFFF !important;
        }

        /* 7. TOAST NOTIFICATIONS */
        [data-testid="stToast"] {
            background-color: #FDFBF0 !important;
            border: 1px solid #800000 !important;
            border-radius: 10px !important;
        }
        [data-testid="stToast"] p {
            color: #800000 !important;
            font-weight: 600 !important;
        }
        [data-testid="stToast"] svg {
            fill: #800000 !important;
        }

        /* 8. GLOBAL INFO/SUCCESS/WARNING BOXES */
        div.stAlert {
            background-color: #800000 !important;
            color: #FFFFFF !important;
            border: 1px solid #5C0000 !important;
            border-radius: 12px !important;
        }
        div.stAlert p, div.stAlert h1, div.stAlert h2, div.stAlert h3 {
            color: #FFFFFF !important;
        }
        div.stAlert svg {
            fill: #FFFFFF !important;
        }
        /* 9. SELECTBOX PERFECTION */
        /* Targets the label text specifically for selectboxes */
        div[data-testid="stSelectbox"] label p {
            color: #800000 !important;
            font-weight: 600 !important;
        }

        /* Targets the placeholder and selected text visibility */
        div[data-testid="stSelectbox"] div[data-baseweb="select"] > div {
            color: #FFFFFF !important;
        }
        /* 10. SLIDER PERFECTION (Maroon Track & Handle) */
        div[data-testid="stSlider"] [data-baseweb="slider"] > div > div {
            background-color: #800000 !important;
        }
        div[data-testid="stSlider"] [data-baseweb="slider"] [role="slider"] {
            background-color: #800000 !important;
            border: 2px solid #FFFFFF !important;
        }
        /* Style the range values and labels below the slider */
        div[data-testid="stSlider"] [data-testid="stWidgetLabel"] p {
            color: #800000 !important;
        }
        /* 11. ADVANCED SEARCH EXPANDER (Full Maroon/White) */
        /* Outer border and main container */
        [data-testid="stExpander"] {
            border: 2px solid #800000 !important;
            border-radius: 12px !important;
            background-color: #FDFBF0 !important;
            overflow: hidden !important;
        }

        /* Expander Header to Solid Maroon */
        [data-testid="stExpander"] summary {
            background-color: #800000 !important;
            border-bottom: 2px solid #800000 !important;
            padding: 5px 15px !important;
        }

        /* Forces Header Text and Icon to White */
        [data-testid="stExpander"] summary p, 
        [data-testid="stExpander"] summary svg {
            color: #FFFFFF !important;
            fill: #FFFFFF !important;
        }
        
        /* Ensures the hover state doesn't turn it back to dark grey */
        [data-testid="stExpander"] summary:hover {
            background-color: #5C0000 !important;
        }
        /* 12. METRIC PERFECTION (Maroon Font) */
        /* Targets the main large number ($450K, 12, etc.) */
        [data-testid="stMetricValue"] {
            color: #800000 !important;
            font-weight: 700 !important;
        }

        /* Targets the label text above the number (Saved Properties, etc.) */
        [data-testid="stMetricLabel"] p {
            color: #800000 !important;
            opacity: 0.8; /* Keeps labels slightly softer than the main numbers */
            font-weight: 600 !important;
        }
        /* 13. SUCCESS BOX */
        /* Targets the main container of st.success */
        div[data-testid="stNotification"] {
            background-color: #800000 !important;
            color: #FFFFFF !important;
            border: 1px solid #5C0000 !important;
            border-radius: 12px !important;
            box-shadow: 0 4px 12px rgba(128,0,0,0.1) !important;
        }

        /* Targets the text inside the success box to force it to White */
        div[data-testid="stNotification"] .stMarkdown p {
            color: #FFFFFF !important;
            font-weight: 600 !important;
            font-size: 1.05rem !important;
        }

        /* Targets the success icon (the checkmark) to turn it White */
        div[data-testid="stNotification"] svg {
            fill: #FFFFFF !important;
        }

        /* Ensures the close button (x) is also visible/white */
        div[data-testid="stNotification"] button svg {
            fill: #FFFFFF !important;
            opacity: 0.8;
        }
        /* 15. CHECKBOX PERFECTION (Maroon Theme) */
        /* Targets the text label of the checkbox */
        div[data-testid="stCheckbox"] label p {
            color: #800000 !important;
            font-weight: 500 !important;
        }

        /* Targets the checkbox square when it is NOT checked */
        div[data-testid="stCheckbox"] div[role="checkbox"] {
            border-color: #800000 !important;
        }

        /* Targets the checkbox square when it IS checked */
        div[data-testid="stCheckbox"] div[role="checkbox"][aria-checked="true"] {
            background-color: #800000 !important;
            border-color: #800000 !important;
        }

        /* Targets the checkmark icon inside the box */
        div[data-testid="stCheckbox"] div[role="checkbox"] svg {
            fill: #FFFFFF !important;
        }

        /* Removes the blue focus glow when clicking */
        div[data-testid="stCheckbox"] div[role="checkbox"]:focus {
            box-shadow: none !important;
            outline: none !important;
        }
    </style>
    """, unsafe_allow_html=True)

# MODEL LOADING 
BUNDLE_PATH = "@GROUP4_ASG2.FINAL_DATA.MODELS/resale_price_bundle.pkl.gz"

@st.cache_resource
def load_artifacts_from_stage(stage_path: str):
    """Load complete ML bundle (model + encoders + feature order)."""
    try:
        raw_stream = SnowflakeFile.open(stage_path, "rb")
        with gzip.open(raw_stream, "rb") as gz:
            artifacts = joblib.load(gz)  # {"model", "label_encoders", "feature_columns"}
        return artifacts
    except Exception as e:
        st.error(f"Bundle load failed: {e}")
        return None

artifacts = load_artifacts_from_stage(BUNDLE_PATH)
if artifacts is None:
    st.error("⚠️ ML bundle missing. Check @GROUP4_ASG2.FINAL_DATA.MODELS/resale_price_bundle.pkl.gz")
    st.stop()

model = artifacts["model"]
label_encoders = artifacts["label_encoders"]
feature_columns = artifacts["feature_columns"]


# Set up and functions
# Get the active Snowflake session provided by Snowflake / Streamlit integration 
@st.cache_resource(show_spinner=False)
def get_session():
    return get_active_session()

# load dropdown options for town, flat type, and storey range and cache them
@st.cache_data(show_spinner=False)
def get_dropdown_data():
    session = get_session()
    towns_df = session.sql("""
        SELECT DISTINCT TOWN 
        FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
        WHERE TOWN IS NOT NULL
        ORDER BY TOWN
    """).to_pandas()
    
    flat_types_df = session.sql("""
        SELECT DISTINCT FLAT_TYPE 
        FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
        WHERE FLAT_TYPE IS NOT NULL
        ORDER BY FLAT_TYPE
    """).to_pandas()
    
    storey_ranges_df = session.sql("""
        SELECT DISTINCT STOREY_RANGE 
        FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
        WHERE STOREY_RANGE IS NOT NULL
        ORDER BY STOREY_RANGE
    """).to_pandas()
    
    return towns_df['TOWN'].tolist(), flat_types_df['FLAT_TYPE'].tolist(), storey_ranges_df['STOREY_RANGE'].tolist()

session = get_session() 
towns, flat_types, storey_ranges = get_dropdown_data() 

# Help to run a SQL Query and return a pandas Dataframe
@st.cache_data
def query_snowflake(sql: str) -> pd.DataFrame:
    return session.sql(sql).to_pandas()

@st.cache_data(ttl=1800)
def get_property_and_amenities(postal_code: str) -> pd.DataFrame:
    """
    Fetch property details and ALL nearby amenities for map visualization.
    
    Purpose:
        - Main data source for the MapBox map
        - Returns property location + amenity coordinates
    
    Args:
        postal_code (str): 6-digit Singapore postal code
    
    Returns:
        DataFrame with columns:
            - Property info: LATITUDE, LONGITUDE, ADDRESS, RESALE_PRICE
            - Amenity distances and counts (MRT, hawkers, supermarkets, etc.)
    
    Data Quality:
        - Only returns records with valid coordinates (LATITUDE/LONGITUDE not null)
        - Limits to 1 property (should be unique per postal code)
    """
    sql = f"""
    SELECT 
        -- Property Core Details
        LATITUDE, LONGITUDE, ADDRESS, RESALE_PRICE, TOWN, FLAT_TYPE,
        
        -- MRT Information
        NEAREST_MRT_NAME, NEAREST_MRT_DISTANCE_M,
        
        -- Food & Shopping Amenities
        NEAREST_HAWKER_DISTANCE_M, HAWKERS_WITHIN_500M,
        NEAREST_SUPERMARKET_DISTANCE_M, SUPERMARKETS_WITHIN_500M,
        
        -- Recreation & Health
        NEAREST_PARK_DISTANCE_M, NEAREST_GYM_DISTANCE_M,
        NEAREST_CLINIC_M, NEAREST_HOSPITAL_M,
        
        -- Family Services
        NEAREST_PRESCHOOL_M, PRESCHOOLS_WITHIN_1KM,
        
        -- Shopping & Overall Scores
        NEAREST_MALL_M, OVERALL_AMENITY_SCORE, 
        SHOPPING_CONVENIENCE_SCORE, HEALTHCARE_ACCESSIBILITY_SCORE
        
    FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
    WHERE POSTAL_CODE = '{postal_code}'
      AND LATITUDE IS NOT NULL
      AND LONGITUDE IS NOT NULL
    LIMIT 1
    """
    return query_snowflake(sql)


# Uses average lat/lon for the town matches in the input, to avoid API
@st.cache_data(ttl=3600)
def geocode_address(address: str) -> tuple[float | None, float | None]:
    """Fixed: UPPERCASE TOWN matching."""
    if not address:
        return None, None
    
    # Clean & uppercase search
    search_term = address.upper().strip()[:25]
    
    sql = f"""
        SELECT 
            AVG(LATITUDE) AS lat, 
            AVG(LONGITUDE) AS lon,
            COUNT(*) AS n_properties
        FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER 
        WHERE UPPER(TOWN) LIKE '%{search_term}%'
        GROUP BY TOWN
        HAVING COUNT(*) >= 10  -- Reliable centroid
        LIMIT 1
    """
    
    try:
        df = query_snowflake(sql)
        if len(df) > 0 and pd.notna(df['lat'].iloc[0]):
            return float(df['lat'].iloc[0]), float(df['lon'].iloc[0])
        return None, None
    except:
        return None, None



# NEW FEATURES IM SO CONFUSEDDDD
@st.cache_data(ttl=3600)
def get_addresses_in_town(town: str) -> list:
    """
    Fetch all unique addresses for a selected town.
    
    Purpose:
        - Powers the address dropdown after town is selected
        - Returns list of street addresses in that town
    
    Returns:
        list: Sorted list of unique addresses in that town
    """
    sql = f"""
    SELECT DISTINCT ADDRESS
    FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
    WHERE TOWN = '{town}'
      AND ADDRESS IS NOT NULL
      AND LATITUDE IS NOT NULL
      AND LONGITUDE IS NOT NULL
    ORDER BY ADDRESS
    LIMIT 300
    """
    df = query_snowflake(sql)
    return df['ADDRESS'].dropna().unique().tolist()


@st.cache_data(ttl=1800)
def get_property_by_address(town: str, address: str) -> pd.DataFrame:
    """
    Fetch property details and amenity data for a specific address.
    
    Purpose:
        - Main data source for MapBox visualization
        - Returns property coordinates + all amenity distances
    
    Returns:
        DataFrame with property location and amenity information
        Returns most recent sale if multiple records exist for same address
    """
    sql = f"""
    SELECT 
        -- Property Core Details
        LATITUDE, LONGITUDE, ADDRESS, RESALE_PRICE, TOWN, FLAT_TYPE,
        STOREY_RANGE, REMAINING_LEASE_YEARS, YEAR_COMPLETED,
        
        -- MRT Information
        NEAREST_MRT_NAME, NEAREST_MRT_DISTANCE_M,
        MRT_WITHIN_500M, MRT_WITHIN_1KM,
        
        -- Food & Shopping Amenities
        NEAREST_HAWKER_DISTANCE_M, HAWKERS_WITHIN_500M, HAWKERS_WITHIN_1KM,
        NEAREST_SUPERMARKET_DISTANCE_M, SUPERMARKETS_WITHIN_500M, SUPERMARKETS_WITHIN_1KM,
        
        -- Recreation & Health
        NEAREST_PARK_DISTANCE_M, PARKS_WITHIN_1KM,
        NEAREST_GYM_DISTANCE_M, GYMS_WITHIN_1KM,
        NEAREST_CLINIC_M, CLINICS_WITHIN_500M,
        NEAREST_HOSPITAL_M, NEAREST_PHARMACY_M,
        
        -- Family & Shopping
        NEAREST_PRESCHOOL_M, PRESCHOOLS_WITHIN_1KM,
        NEAREST_MALL_M,
        
        -- Overall Scores
        OVERALL_AMENITY_SCORE, SHOPPING_CONVENIENCE_SCORE, 
        HEALTHCARE_ACCESSIBILITY_SCORE
        
    FROM GROUP4_ASG2.FINAL_DATA.PROPWISE_MASTER
    WHERE TOWN = '{town}' 
      AND ADDRESS = '{address}'
      AND LATITUDE IS NOT NULL
      AND LONGITUDE IS NOT NULL
    ORDER BY SALE_YEAR DESC, SALE_MONTH DESC
    LIMIT 1
    """
    return query_snowflake(sql)

@st.cache_data(ttl=3600)
def generate_amenity_pins(prop_lat: float, prop_lon: float, amenity_data: dict) -> pd.DataFrame:
    """
    Generate estimated amenity pin locations based on distances from property.
    
    Purpose:
        - Creates approximate lat/lon coordinates for amenities
        - Since database only has distances (not actual amenity coordinates),
          we estimate positions using trigonometry
    
    How it works:
        1. Takes amenity distance (e.g., "MRT is 350m away")
        2. Converts meters to degrees (rough approximation for Singapore)
        3. Places pin at that distance in a random direction from property
    
    Args:
        prop_lat (float): Property latitude
        prop_lon (float): Property longitude
        amenity_data (dict): Dictionary with amenity distances from database
    
    Returns:
        DataFrame with columns: lat, lon, name, type, color (RGBA array), distance
    
    Note:
        - Colors are standardized for each amenity type
        - In production, replace with actual amenity coordinates if available
    """
    import math
    import random
    
    amenities = []
    
    # Helper: Convert meters to approximate degrees (Singapore ~1° = 111km)
    def meters_to_degrees(meters):
        return meters / 111000
    
    # ===== MRT STATIONS (Blue) =====
    if amenity_data.get('NEAREST_MRT_DISTANCE_M') and pd.notna(amenity_data['NEAREST_MRT_DISTANCE_M']):
        distance_m = amenity_data['NEAREST_MRT_DISTANCE_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🚇 {amenity_data.get('NEAREST_MRT_NAME', 'MRT')}",
            'type': 'MRT',
            'color': [0, 100, 255, 220],  # Blue
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== HAWKER CENTERS (Orange) =====
    if amenity_data.get('NEAREST_HAWKER_DISTANCE_M') and pd.notna(amenity_data['NEAREST_HAWKER_DISTANCE_M']):
        distance_m = amenity_data['NEAREST_HAWKER_DISTANCE_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        count_text = f" ({int(amenity_data['HAWKERS_WITHIN_500M'])} within 500m)" if amenity_data.get('HAWKERS_WITHIN_500M') else ""
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🍜 Hawker Center{count_text}",
            'type': 'Hawker',
            'color': [255, 140, 0, 220],  # Orange
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== SUPERMARKETS (Green) =====
    if amenity_data.get('NEAREST_SUPERMARKET_DISTANCE_M') and pd.notna(amenity_data['NEAREST_SUPERMARKET_DISTANCE_M']):
        distance_m = amenity_data['NEAREST_SUPERMARKET_DISTANCE_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        count_text = f" ({int(amenity_data['SUPERMARKETS_WITHIN_500M'])} within 500m)" if amenity_data.get('SUPERMARKETS_WITHIN_500M') else ""
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🛒 Supermarket{count_text}",
            'type': 'Supermarket',
            'color': [34, 139, 34, 220],  # Forest Green
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== PARKS (Light Green) =====
    if amenity_data.get('NEAREST_PARK_DISTANCE_M') and pd.notna(amenity_data['NEAREST_PARK_DISTANCE_M']):
        distance_m = amenity_data['NEAREST_PARK_DISTANCE_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🌳 Park",
            'type': 'Park',
            'color': [50, 205, 50, 220],  # Lime Green
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== GYMS (Purple) =====
    if amenity_data.get('NEAREST_GYM_DISTANCE_M') and pd.notna(amenity_data['NEAREST_GYM_DISTANCE_M']):
        distance_m = amenity_data['NEAREST_GYM_DISTANCE_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🏋️ Gym",
            'type': 'Gym',
            'color': [138, 43, 226, 220],  # Blue Violet
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== CLINICS (Pink) =====
    if amenity_data.get('NEAREST_CLINIC_M') and pd.notna(amenity_data['NEAREST_CLINIC_M']):
        distance_m = amenity_data['NEAREST_CLINIC_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🏥 Clinic",
            'type': 'Clinic',
            'color': [255, 105, 180, 220],  # Hot Pink
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== HOSPITALS (Red Cross) =====
    if amenity_data.get('NEAREST_HOSPITAL_M') and pd.notna(amenity_data['NEAREST_HOSPITAL_M']):
        distance_m = amenity_data['NEAREST_HOSPITAL_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🏥 Hospital",
            'type': 'Hospital',
            'color': [220, 20, 60, 220],  # Crimson
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== PRESCHOOLS (Yellow) =====
    if amenity_data.get('NEAREST_PRESCHOOL_M') and pd.notna(amenity_data['NEAREST_PRESCHOOL_M']):
        distance_m = amenity_data['NEAREST_PRESCHOOL_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        count_text = f" ({int(amenity_data['PRESCHOOLS_WITHIN_1KM'])} within 1km)" if amenity_data.get('PRESCHOOLS_WITHIN_1KM') else ""
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"👶 Preschool{count_text}",
            'type': 'Preschool',
            'color': [255, 215, 0, 220],  # Gold
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== SHOPPING MALLS (Magenta) =====
    if amenity_data.get('NEAREST_MALL_M') and pd.notna(amenity_data['NEAREST_MALL_M']):
        distance_m = amenity_data['NEAREST_MALL_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"🏬 Shopping Mall",
            'type': 'Mall',
            'color': [255, 0, 255, 220],  # Magenta
            'distance': f"{int(distance_m)}m"
        })
    
    # ===== PHARMACIES (Teal) =====
    if amenity_data.get('NEAREST_PHARMACY_M') and pd.notna(amenity_data['NEAREST_PHARMACY_M']):
        distance_m = amenity_data['NEAREST_PHARMACY_M']
        distance_deg = meters_to_degrees(distance_m)
        angle = random.uniform(0, 2 * math.pi)
        
        amenities.append({
            'lat': prop_lat + distance_deg * math.sin(angle),
            'lon': prop_lon + distance_deg * math.cos(angle),
            'name': f"💊 Pharmacy",
            'type': 'Pharmacy',
            'color': [0, 128, 128, 220],  # Teal
            'distance': f"{int(distance_m)}m"
        })
    
    return pd.DataFrame(amenities)

# MAIN APP 

# Get Snowflake session
session = get_session()


# Get dropdown lists
towns, flat_types, storey_ranges = get_dropdown_data()  # serializable lists for UI


# Sidebar
with st.sidebar:
    st.image("https://img.icons8.com/fluency/96/home.png", width=60)
    st.markdown("<h2 style='margin-bottom:0;'>PropWise Smart Valuator</h2>", unsafe_allow_html=True)
    st.markdown("<p style='opacity:0.7; font-size:0.9rem;'>Snowflake ML-Powered HDB Valuation</p>", unsafe_allow_html=True)
    st.write("---")
    page = st.radio("Navigation", ["🧠 Price Prediction", "🔎 User Specific Data"])
    st.markdown("---")


# PAGE 1: PRICE PREDICTION
if page == "🧠 Price Prediction":
    st.markdown("## 🏠 Production ML Predictor")
    st.caption("#### Your home's true value, Powered by Data")
    
    # POWER BI DASHBOARD - Market Overview
    st.markdown("### 📊 Market Overview")
    st.caption("Understand the Resale Price Trends")
    
    # Show dashboard preview image
    st.image("ADO_Dashboard.png", use_container_width=True)
    
    # Direct link to Power BI
    power_bi_url = "https://app.powerbi.com/links/4OVr7OpOaD?ctid=cba9e115-3016-4462-a1ab-a565cba0cdf1&pbi_source=linkShare"
    col1, col2, col3 = st.columns([1, 2, 1])
    with col2:
        st.link_button(
            "📊 Open Interactive Dashboard",
            power_bi_url,
            type="primary",
            use_container_width=True
        )        
    
    st.markdown("---")
    col1, col2 = st.columns(2)
    
    with col1:
        st.markdown("#### 📋 Amenities Nearby")
        fitness_recreation = st.checkbox("🏋️ Fitness & Recreation", value=False)
        food_daily_groceries = st.checkbox("🛒 Food & Daily Groceries", value=False)
        healthcare_access = st.checkbox("🏥 Healthcare Access", value=False)
        childcare_family = st.checkbox("👨‍👩‍👧 Childcare & Family", value=False)
        
        st.markdown("#### 🚶 MRT Distance")
        mrt_distance = st.slider("Nearest MRT Distance (Metres)", 30, 1000, 500, 50)
    
    with col2:
        st.markdown("#### 🏢 Flat Information")
        age_category = st.selectbox(
            "🏗️ House Age",
            options=sorted(label_encoders["age_category"].classes_)
        )
        town = st.selectbox(
            "🏘️ Town",
            options=sorted(label_encoders["TOWN"].classes_)
        )
        flat_type = st.selectbox(
            "🏠 Flat Type",
            options=sorted(label_encoders["FLAT_TYPE"].classes_)
        )
        storey_range = st.selectbox(
            "📊 Storey Range",
            options=sorted(label_encoders["STOREY_RANGE"].classes_)
        )
    
    if st.button("🔮 Predict Resale Price", type="primary", use_container_width=True):
        input_data = {
            "fitness_recreation": int(fitness_recreation),
            "food_daily_groceries": int(food_daily_groceries),
            "healthcare_access": int(healthcare_access),
            "childcare_family": int(childcare_family),
            "NEAREST_MRT_DISTANCE_M": float(mrt_distance),
            "age_category": label_encoders["age_category"].transform([age_category])[0],
            "TOWN": label_encoders["TOWN"].transform([town])[0],
            "FLAT_TYPE": label_encoders["FLAT_TYPE"].transform([flat_type])[0],
            "STOREY_RANGE": label_encoders["STOREY_RANGE"].transform([storey_range])[0],
        }
        
        # Reorder to exact training feature order
        X_input = pd.DataFrame([input_data])[feature_columns]
        
        prediction = model.predict(X_input)[0]
        
        # Hero result
        st.markdown(f"""
            <style>
            .prediction-card {{
                background: linear-gradient(135deg, #800000 0%, #A52A2A 100%) !important;
                padding: 3rem 2rem !important;
                border-radius: 20px !important;
                text-align: center !important;
                box-shadow: 0 15px 40px rgba(128,0,0,0.4) !important;
                margin: 2rem 0 !important;
                isolation: isolate !important;
                position: relative !important;
            }}
            
            .prediction-price {{
                font-size: 4.5rem !important;
                font-weight: 900 !important;
                color: #FFFFFF !important;
                -webkit-text-fill-color: #FFFFFF !important !important;
                -webkit-text-stroke: 0.1px transparent !important;
                text-shadow: 0 3px 8px rgba(0,0,0,0.5) !important;
                display: block !important;
                line-height: 1.1 !important;
                letter-spacing: -1px !important;
                margin-bottom: 1rem !important;
            }}
            
            .prediction-label {{
                font-size: 1.4rem !important;
                color: #FFFFFF !important;
                -webkit-text-fill-color: #FFFFFF !important;
                margin: 0 0 0.5rem 0 !important;
                font-weight: 500 !important;
                opacity: 0.95 !important;
            }}
            
            .prediction-details {{
                font-size: 1.1rem !important;
                color: #F0F0F0 !important;
                margin: 0 !important;
                font-weight: 400 !important;
                opacity: 0.9 !important;
            }}
            </style>
            
            <div class="prediction-card">
                <span class="prediction-price">${int(prediction):,.0f}</span>
                <p class="prediction-label">Production ML Prediction</p>
                <p class="prediction-details">
                    {town} | {flat_type} | {storey_range} | {age_category}
                </p>
            </div>
            """, unsafe_allow_html=True)



#PAGE 2: ROLE SELECTION & DASHBOARDS
elif page == "🔎 User Specific Data":
    st.markdown("## 👥 Role-Based Property Intelligence")
    
    # ROLE SELECTION DROPDOWN
    role = st.selectbox(
        "🎭 Select Your Role", 
        ["🏠 Home Buyer", "💰 Home Seller", "🏢 Property Agent"], 
        key="role_select",
        help="Choose your role to access specialized tools and insights"
    )
    
    st.markdown("---")

    # Home buyer page 
    if role == "🏠 Home Buyer":
        # HOME BUYER POWER BI DASHBOARD
        st.markdown("### 📊 Home Buyer Market Insights")
        st.info("Navigating Resale Values and Amenities")
        
        st.image("ADO_DASHBOARD_RISHITHA.png", use_container_width=True)
        
        buyer_powerbi_url = "https://app.powerbi.com/links/BVtmvF2Ats?ctid=cba9e115-3016-4462-a1ab-a565cba0cdf1&pbi_source=linkShare"
        
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            st.link_button(
                "📊 Open Home Buyer Analytics Dashboard",
                buyer_powerbi_url,
                type="primary",
                use_container_width=True
            )
        
        st.markdown("---")

        st.markdown("### 🏠 Home Buyer - Amenities Explorer")
        st.info("🎯 **Find Your Dream Home**: Select a town and address to visualize nearby amenities on an interactive map")
    
        st.markdown("### 📍 Select Property Location")
        
        col1, col2 = st.columns(2)
        
        with col1:
            # STEP 1: Select Town (Primary filter)
            selected_town = st.selectbox(
                "🏘️ Select Town",
                options=towns,
                key="buyer_town",
                help="Choose the town/planning area you're interested in"
            )
        
        with col2:
            # STEP 2: Select Address (Filtered by town)
            if selected_town:
                # Fetch addresses only for the selected town
                with st.spinner(f"Loading addresses in {selected_town}..."):
                    available_addresses = get_addresses_in_town(selected_town)
                
                if available_addresses:
                    selected_address = st.selectbox(
                        "🏢 Select Address",
                        options=available_addresses,
                        key="buyer_address",
                        help="Choose the specific street/block"
                    )
                else:
                    st.selectbox("🏢 Select Address", ["No addresses found"], disabled=True)
                    selected_address = None
            else:
                st.selectbox("🏢 Select Address", ["Select town first"], disabled=True)
                selected_address = None
        
        st.markdown("---")
        
        # SECTION 2: MAP VISUALIZATION
        # Shows property pin + amenity pins on MapBox
        if selected_town and selected_address:
            # Center-aligned button for better UX
            col_btn1, col_btn2, col_btn3 = st.columns([1, 2, 1])
            with col_btn2:
                show_map = st.button(
                    "🗺️ Show Amenities Map", 
                    type="primary", 
                    use_container_width=True
                )
            
            if show_map:
                # ===== FETCH PROPERTY DATA =====
                with st.spinner("🔍 Loading property and amenity data..."):
                    property_df = get_property_by_address(selected_town, selected_address)
                
                # ===== ERROR HANDLING =====
                if property_df.empty:
                    st.error(f"⚠️ No property found for: **{selected_address}** in **{selected_town}**")
                    st.info("💡 This might be a data issue. Try selecting a different address.")
                
                else:
                    # Extract property data (first row)
                    prop = property_df.iloc[0].to_dict()
                    
                    # ========================================
                    # DISPLAY: PROPERTY OVERVIEW
                    # ========================================
                    st.markdown("### 🏡 Property Information")
                    
                    # Row 1: Address & Amenity Score
                    info_col1, info_col2 = st.columns(2)
                    
                    with info_col1:
                        st.metric("🚉 Nearest MRT", prop['NEAREST_MRT_DISTANCE_M'])
                    
                    with info_col2:
                        st.metric("⭐ Amenity Score", f"{prop['OVERALL_AMENITY_SCORE']:.1f}/10" if pd.notna(prop['OVERALL_AMENITY_SCORE']) else "N/A")
                    
                    # Row 2: Amenities Distances
                    st.markdown("#### 🏃 Nearby Amenities (Distance in Metres)")
                    
                    amenity_col1, amenity_col2, amenity_col3 = st.columns(3)
                    
                    with amenity_col1:
                        st.metric(
                            "🏋️ Nearest Gym", 
                            f"{int(prop['NEAREST_GYM_DISTANCE_M'])}m" if pd.notna(prop['NEAREST_GYM_DISTANCE_M']) else "-"
                        )
                        st.metric(
                            "🍜 Nearest Hawker", 
                            f"{int(prop['NEAREST_HAWKER_DISTANCE_M'])}m" if pd.notna(prop['NEAREST_HAWKER_DISTANCE_M']) else "-"
                        )
                    
                    with amenity_col2:
                        st.metric(
                            "🛒 Nearest Supermarket", 
                            f"{int(prop['NEAREST_SUPERMARKET_DISTANCE_M'])}m" if pd.notna(prop['NEAREST_SUPERMARKET_DISTANCE_M']) else "-"
                        )
                        st.metric(
                            "🏥 Nearest Clinic", 
                            f"{int(prop['NEAREST_CLINIC_M'])}m" if pd.notna(prop['NEAREST_CLINIC_M']) else "-"
                        )
                    
                    with amenity_col3:
                        st.metric(
                            "👶 Nearest Preschool", 
                            f"{int(prop['NEAREST_PRESCHOOL_M'])}m" if pd.notna(prop['NEAREST_PRESCHOOL_M']) else "-"
                        )
                        st.metric(
                            "🏬 Nearest Mall", 
                            f"{int(prop['NEAREST_MALL_M'])}m" if pd.notna(prop['NEAREST_MALL_M']) else "-"
                        )
                    
                    st.markdown("---")
    
                    # ========================================
                    # MAPBOX INTERACTIVE MAP
                    # ========================================
                    st.markdown("### 🗺️ Interactive Amenities Map")
                    st.caption("🔴 **Red** = Your Property | 🔵 **Blue** = MRT | 🟠 **Orange** = Hawker | 🟢 **Green** = Supermarket | 🟣 **Purple** = Gym | 🩷 **Pink** = Clinic | 🟡 **Yellow** = Preschool | 🟪 **Magenta** = Mall")
                    
                    # Get property coordinates
                    prop_lat = prop['LATITUDE']
                    prop_lon = prop['LONGITUDE']
                    
                    # ===== LAYER 1: PROPERTY PIN (Red) =====
                    property_data = pd.DataFrame([{
                        'lat': prop_lat,
                        'lon': prop_lon,
                        'name': '🏠 Your Selected Property',
                        'address': prop['ADDRESS'],
                        'price': f"${int(prop['RESALE_PRICE']):,}" if pd.notna(prop['RESALE_PRICE']) else "N/A"
                    }])
                    
                    property_layer = pdk.Layer(
                        "ScatterplotLayer",
                        data=property_data,
                        get_position='[lon, lat]',
                        get_fill_color=[200, 30, 0, 255],  # Bright Red
                        get_radius=30,  # Larger size for property
                        pickable=True,
                        auto_highlight=True,
                    )
                    
                    # ===== LAYER 2: AMENITY PINS (Color-coded) =====
                    amenity_pins = generate_amenity_pins(prop_lat, prop_lon, prop)
                    
                    if not amenity_pins.empty:
                        amenity_layer = pdk.Layer(
                            "ScatterplotLayer",
                            data=amenity_pins,
                            get_position='[lon, lat]',
                            get_fill_color='color',  # Uses color column (RGBA array)
                            get_radius=20,  # Smaller size for amenities
                            pickable=True,
                            auto_highlight=True,
                        )
                        map_layers = [property_layer, amenity_layer]
                    else:
                        map_layers = [property_layer]
                        st.warning("⚠️ No nearby amenity data available for this property")
                    
                    # ===== MAP VIEWPORT =====
                    view_state = pdk.ViewState(
                        latitude=prop_lat,
                        longitude=prop_lon,
                        zoom=14.5,  # Street-level zoom
                        pitch=50,   # 3D tilt angle
                        bearing=0   # North-up orientation
                    )
                    
                    # ===== TOOLTIP CONFIGURATION =====
                    tooltip_config = {
                        "html": """
                            <div style="font-family: Arial;">
                                <b>{name}</b><br/>
                                <span style="color: #666;">{distance}</span>
                            </div>
                        """,
                        "style": {
                            "backgroundColor": "#800000",
                            "color": "white",
                            "fontSize": "13px",
                            "padding": "8px 12px",
                            "borderRadius": "6px",
                            "boxShadow": "0 2px 8px rgba(0,0,0,0.3)"
                        }
                    }
                    
                    # ===== RENDER MAP =====
                    deck = pdk.Deck(
                        layers=map_layers,
                        initial_view_state=view_state,
                        map_style='mapbox://styles/mapbox/streets-v11',
                        tooltip=tooltip_config
                    )
                    
                    st.pydeck_chart(deck, use_container_width=True, height=600)
    
                    
                    st.markdown("---")
                    
                    # ========================================
                    # AMENITY DETAILS TABLE
                    # ========================================
                    st.markdown("### 📊 Nearby Amenities Breakdown")
                    
                    # Create detailed amenity summary table
                    amenity_table = {
                        '🏷️ Category': [],
                        '📏 Distance': [],
                        '🔢 Count Nearby': [],
                        '⭐ Rating': []
                    }
                    
                    # MRT
                    amenity_table['🏷️ Category'].append('🚇 MRT Station')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_MRT_DISTANCE_M'])}m - {prop['NEAREST_MRT_NAME']}" 
                        if pd.notna(prop['NEAREST_MRT_DISTANCE_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['MRT_WITHIN_500M'])} within 500m" 
                        if pd.notna(prop['MRT_WITHIN_500M']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append(
                        '⭐⭐⭐⭐⭐' if pd.notna(prop['NEAREST_MRT_DISTANCE_M']) and prop['NEAREST_MRT_DISTANCE_M'] < 500 
                        else '⭐⭐⭐' if pd.notna(prop['NEAREST_MRT_DISTANCE_M']) 
                        else 'N/A'
                    )
                    
                    # Hawker Centers
                    amenity_table['🏷️ Category'].append('🍜 Hawker Centers')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_HAWKER_DISTANCE_M'])}m" 
                        if pd.notna(prop['NEAREST_HAWKER_DISTANCE_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['HAWKERS_WITHIN_500M'])} within 500m | {int(prop['HAWKERS_WITHIN_1KM'])} within 1km" 
                        if pd.notna(prop['HAWKERS_WITHIN_500M']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append('⭐⭐⭐⭐')
                    
                    # Supermarkets
                    amenity_table['🏷️ Category'].append('🛒 Supermarkets')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_SUPERMARKET_DISTANCE_M'])}m" 
                        if pd.notna(prop['NEAREST_SUPERMARKET_DISTANCE_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['SUPERMARKETS_WITHIN_500M'])} within 500m | {int(prop['SUPERMARKETS_WITHIN_1KM'])} within 1km" 
                        if pd.notna(prop['SUPERMARKETS_WITHIN_500M']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append(
                        f"{prop['SHOPPING_CONVENIENCE_SCORE']:.1f}/10" 
                        if pd.notna(prop['SHOPPING_CONVENIENCE_SCORE']) else 'N/A'
                    )
                    
                    # Parks
                    amenity_table['🏷️ Category'].append('🌳 Parks')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_PARK_DISTANCE_M'])}m" 
                        if pd.notna(prop['NEAREST_PARK_DISTANCE_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['PARKS_WITHIN_1KM'])} within 1km" 
                        if pd.notna(prop['PARKS_WITHIN_1KM']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append('⭐⭐⭐⭐')
                    
                    # Gyms
                    amenity_table['🏷️ Category'].append('🏋️ Gyms')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_GYM_DISTANCE_M'])}m" 
                        if pd.notna(prop['NEAREST_GYM_DISTANCE_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['GYMS_WITHIN_1KM'])} within 1km" 
                        if pd.notna(prop['GYMS_WITHIN_1KM']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append('⭐⭐⭐')
                    
                    # Healthcare
                    amenity_table['🏷️ Category'].append('🏥 Healthcare')
                    amenity_table['📏 Distance'].append(
                        f"Clinic: {int(prop['NEAREST_CLINIC_M'])}m | Hospital: {int(prop['NEAREST_HOSPITAL_M'])}m" 
                        if pd.notna(prop['NEAREST_CLINIC_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['CLINICS_WITHIN_500M'])} clinics within 500m" 
                        if pd.notna(prop['CLINICS_WITHIN_500M']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append(
                        f"{prop['HEALTHCARE_ACCESSIBILITY_SCORE']:.1f}/10" 
                        if pd.notna(prop['HEALTHCARE_ACCESSIBILITY_SCORE']) else 'N/A'
                    )
                    
                    # Preschools
                    amenity_table['🏷️ Category'].append('👶 Preschools')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_PRESCHOOL_M'])}m" 
                        if pd.notna(prop['NEAREST_PRESCHOOL_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append(
                        f"{int(prop['PRESCHOOLS_WITHIN_1KM'])} within 1km" 
                        if pd.notna(prop['PRESCHOOLS_WITHIN_1KM']) else 'N/A'
                    )
                    amenity_table['⭐ Rating'].append('⭐⭐⭐⭐')
                    
                    # Shopping Malls
                    amenity_table['🏷️ Category'].append('🏬 Shopping Malls')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_MALL_M'])}m" 
                        if pd.notna(prop['NEAREST_MALL_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append('N/A')
                    amenity_table['⭐ Rating'].append('⭐⭐⭐')
                    
                    # Pharmacies
                    amenity_table['🏷️ Category'].append('💊 Pharmacies')
                    amenity_table['📏 Distance'].append(
                        f"{int(prop['NEAREST_PHARMACY_M'])}m" 
                        if pd.notna(prop['NEAREST_PHARMACY_M']) else 'N/A'
                    )
                    amenity_table['🔢 Count Nearby'].append('N/A')
                    amenity_table['⭐ Rating'].append('⭐⭐⭐')
                    
                    # Display table
                    st.dataframe(
                        pd.DataFrame(amenity_table), 
                        use_container_width=True, 
                        hide_index=True,
                        height=400
                    )
                    
                    # ===== OVERALL SCORES =====
                    st.markdown("#### 🏆 Overall Location Scores")
                    
                    score_col1, score_col2, score_col3 = st.columns(3)
                    
                    with score_col1:
                        overall = prop['OVERALL_AMENITY_SCORE']
                        st.metric(
                            "Overall Amenity Score",
                            f"{overall:.1f}/10" if pd.notna(overall) else "N/A",
                            delta="Excellent" if pd.notna(overall) and overall >= 7 else "Good" if pd.notna(overall) and overall >= 5 else "Average"
                        )
                    
                    with score_col2:
                        shopping = prop['SHOPPING_CONVENIENCE_SCORE']
                        st.metric(
                            "Shopping Convenience",
                            f"{shopping:.1f}/10" if pd.notna(shopping) else "N/A"
                        )
                    
                    with score_col3:
                        health = prop['HEALTHCARE_ACCESSIBILITY_SCORE']
                        st.metric(
                            "Healthcare Accessibility",
                            f"{health:.1f}/10" if pd.notna(health) else "N/A"
                        )
                        
        else:
            # ===== INSTRUCTIONS =====
            st.info("👆 **Please select a town and address above** to view the interactive amenities map")
            
            st.markdown("""
            ### 📖 How to Use:
            1. **Select Town** from the dropdown (26 HDB towns available)
            2. **Select Address** from the filtered list
            3. Click **"Show Amenities Map"** to visualize
            
            ### 🎨 Map Features:
            - **🔴 Red Pin** = Your selected property location
            - **Colored Pins** = Nearby amenities (MRT, hawkers, supermarkets, gyms, etc.)
            - **Hover over pins** to see amenity names and distances
            - **Scroll & zoom** the map to explore the neighborhood
            
            ### 📊 You'll Also See:
            - Property details (price, flat type, lease remaining)
            - Complete amenity breakdown table with distances
            - Overall location scores (amenity, shopping, healthcare)
            """)


    # HOME SELLER PAGE (Power BI Dashboard)
   
    elif role == "💰 Home Seller":
        st.markdown("### 📊 Home Valuation Dashboard")
        st.info(" 📈 Resale data for strategic home pricing")
        
        st.image("ADO_DASHBOARD_HONGYI.png", use_container_width=True)
        
        seller_powerbi_url = "https://app.powerbi.com/links/83p8TyzrXb?ctid=cba9e115-3016-4462-a1ab-a565cba0cdf1&pbi_source=linkShare&bookmarkGuid=04c0cd41-3a78-4b3d-a373-0844baf31b83"
        
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            st.link_button(
                "📊 Open Home Seller Dashboard",
                seller_powerbi_url,
                type="primary",
                use_container_width=True
            )
            
    # ========================================
    # PROPERTY AGENT PAGE (Power BI Dashboard)
    # ========================================
    else:  # Property Agent
        st.markdown("### 🏢 Property Agent Dashboard")
        st.info("📈 Comprehensive market analytics for property agents")
    
        st.image("ADO_DASHBOARD_LOVETTE.png", use_container_width=True)
        
        agent_powerbi_url = "https://app.powerbi.com/links/9wflj0kwqe?ctid=cba9e115-3016-4462-a1ab-a565cba0cdf1&pbi_source=linkShare&bookmarkGuid=14ce6fde-62d4-47df-a436-62540f05dc1b"
        
        col1, col2, col3 = st.columns([1, 2, 1])
        with col2:
            st.link_button(
                "📊 Open Property Agent Dashboard",
                agent_powerbi_url,
                type="primary",
                use_container_width=True
            )
# footer
st.markdown("---")
col1, col2, col3 = st.columns([1, 3, 1])
with col2:
    st.markdown("<p style='text-align: center; color: #800000; font-weight: 600;'>"
                "© 2026 PropWise Smart Valuator | Powered by Snowflake ML</p>", 
                unsafe_allow_html=True)
    
            