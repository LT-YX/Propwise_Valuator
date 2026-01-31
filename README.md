# Propwise_Valuator
Our solution “Propwise Valuator” serves as a comprehensive digital platform designed to address data fragmentation within the public housing market. By centralising HDB pricing and urban amenity datasets into a secure cloud environment (snowflake), the project provides a single source of truth for all property related inquiries. Our interactive Streamlit website integrates a machine learning price prediction model and other specialised analytical features for each target group. Each member of the team created a unique dashboard, each specifically designed to meet the distinct informational needs of home buyers, sellers, and property agents.

### Important Links
Link to Trello Board: [https://trello.com/invite/b/69245bc27e74602b13091001/ATTI85ca6c923be2873e32cab67a48253d3b574FF329/propwise](url)
Link to Recordings: 

## Table of Contents

## Project Overview
The primary goal of this project is to centralise disparate public housing datasets from government portals (data.gov.sg) into a unified cloud environment. By consolidating official pricing information from the Housing Development Board (HDB) with relevant amenity metrics such as proximity to MRT stations and healthcare facilities, the project aims to enhance data security and operational functionality.

### Architecture

### Features

## Project Setup 
(Include dependencies and scripts / How to run project)

## Data Pipeline Workflow
### Datasets
#### Raw Data
HDB Resale Flat Prices [https://data.gov.sg/collections/189/view] 
Resale Flat Prices Based On Registration Date From Jan 2015 to Dec 2016 & Resale Flat Prices Based On Registration Date From Jan 2017 onwards
- Transacted prices of HDB resale flats based on registration date 
- Initial Features: Month, Town, Flat Type, Block, Street Name, Storey Range, Floor Area (sqm), Flat Model, Lease Commence Date, Remaining Lease, Resale Price

HDB Price Range Dataset [https://data.gov.sg/datasets/d_2d493bdcc1d9a44828b6e71cb095b88d/view]
- Price Range of BTO across the different financial year and town
- Initial Features: Financial year, Town, Room Type, Min Selling Price, Max Selling Price

HDB Median Resale Price [https://data.gov.sg/datasets/d_b51323a474ba789fb4cc3db58a3116d4/view]
- Median Price of HDB Resales by Housing Type and Year
- Initial Features

HDB Resale Index [https://data.gov.sg/datasets/d_14f63e595975691e7c24a27ae4c07c79/view]
- Resale Index for HDB by Quarter
- Resale Index: Tracks general trends of HDB Resale Prices, Uses regression

HDB Property Information [https://data.gov.sg/datasets/d_17f5382f26140b1fdae0ba2ef6239d2f/view]
- Other relevant information of HDB, May affect valuation

CHAS Clinics Dataset [https://data.gov.sg/datasets/d_548c33ea2d99e29ec63a7cc9edcccedc/view](url)
- CHAS Clinics Locations across Singapore
- Initial Features: Name, Description

Community Club Dataset [https://data.gov.sg/datasets/d_f706de1427279e61fe41e89e24d440fa/view](url)
- Locations of Community Clubs across Singapore
- Initial Features: Name, Description

Eldercare Services Dataset [https://data.gov.sg/datasets/d_f0fd1b3643ed8bd34bd403dedd7c1533/view](url)
- Locations of Eldercare Service Centres across Singapore
- Initial Features: Name, Description

School Location Dataset [https://data.gov.sg/datasets/d_688b934f82c1059ed0a6993d2a829089/view](url)
- Locations of Primary and Secondary Schools, and Junior Colleges from Sep 2025 to Dec 2025
- Initial Description: School Name, Url Address, Address, Postal Code, Telephone No, Telephone No 2, Fax No, Fax No 2, Email Address, Mrt Desc, Bus Desc, Principal Name, First Vp Name, Second Vp Name, Third Vp Name, Fourth Vp Name, Fifth Vp Name, Sixth Vp Name, Dgp Code, Zone Code, Type Code, Nature Code, Session Code, Mainlevel Code, Sap Ind Autonomous Ind, Gifted Ind, Ip Ind, Mothertongue1 Code, Mothertongue2 Code, Mothertongue3 Code

Public Gym Location Dataset [https://data.gov.sg/datasets/d_b3ae090692ecf632116c9885cfbd3424/view](url)
- Locations of public gyms across Singapore
- Initial Features: Name, Description

Hawker Centre Location Dataset [https://data.gov.sg/datasets/d_4a086da0a5553be1d89383cd90d07ecd/view](url)
- Locations of Hawker Centres across Singapore
- This is a live dataset hence this is the public API URL: [https://api-open.data.gov.sg/v1/public/api/datasets/d_4a086da0a5553be1d89383cd90d07ecd/poll-download](url)
- Initial Attributes: OBJECTID, LANDXADDRESSPOINT, LANDYADDRESSPOINT, ADDRESSBUILDINGNAME, ADDRESSPOSTALCODE, ADDRESSSTREETNAME, DESCRIPTION, NAME, PHOTOURL, ADDRESSBLOCKHOUSENUMBER, STATUS, AWARDED_DATE, IMPLEMENTATION_DATE, INFO_ON_CO_LOCATORS, ADDRESS_MYENV, EST_ORIGINAL_COMPLETION_DATE, HUP_COMPLETION_DATE, NUMBER_OF_COOKED_FOOD_STALLS, INC_CRC, FMEL_UPD_D

MRT Stations Dataset [https://www.kaggle.com/datasets/shengjunlim/singapore-mrt-lrt-stations-with-coordinates](url)
- Coordinates and details of the MRT and LRT Stations
- Last updated was 4 years ago hence, the dataset is missing the newest MRT and LRT stations (Thomson-East Coast Line)
- Initial Attributes: OBJECTID, STN_NAME, STN_NO, geometry, Latitude, Longitude

Parks Location Dataset[https://data.gov.sg/datasets/d_0542d48f0991541706b58059381a6eca/view](url)
- Locations of various parks around Singapore
- Initial Attributes: OBJECTID, NAME, X, Y, INC_CRC, FMEL_UPD_D

Pre-School Location Dataset[https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view](url)
- Locations of pre-schools across Singapore
- Initial Features: Name, Description

Retail Pharmacy Location Dataset [https://data.gov.sg/datasets/d_bb92615f43de22933e4479558b1f6c36/view](url)
- Locations of retail pharmacy stores across Singapore
- Initial Attributes: OBJECTID_1, POSTAL_CODE, BUILDING_NAME, UNIT_NO, LEVEL_NO, ROAD_NAME, HOUSE_BLK_NO, PHARMACY_NAME, INC_CRC, FMEL_UPD_D

Supermarket Location Dataset [https://data.gov.sg/datasets/d_cac2c32f01960a3ad7202a99c27268a0/view](url)
- Locations of supermarkets across Singapore
- Initial Features: Name, Description

Water Activity Area Location Dataset [https://data.gov.sg/datasets/d_3db7e1a18c685a2a61ced5a0deb83dae/view](url)
- Locations of water activity areas such as swimming complexes, and water venture spots for fishing and kayaking
- Initial Features: Name, Description

Hospital Location Dataset [https://www.kaggle.com/datasets/muhdirshath/hospitals-in-singapore](url)
- Locations of Hospitals across Singapore
- Initial Attributes: hospital_name, address, postal_code, hospital_type, latitude, longitude, town

Shopping Mall Dataset[https://www.kaggle.com/datasets/sunnysharma432/singapore-malls-pois](url)
- Locations of shopping malls across Singapore
- Initial Attributes: name, category, lat, lon, brand, address, website, phone

Supplement: Shopping Mall Coordinate Dataset [https://www.kaggle.com/datasets/karthikgangula/shopping-mall-coordinates](url)
- Coordinates of the shopping malls for cross-referencing
- Intial Attributes: Mall Name, LATITUDE, LONGITUDE

Clincs Dataset [https://www.kaggle.com/datasets/sunnysharma432/singapore-clinic-pois](url)
- Locations of GP Clinics and Polyclinics
- Initial Attributes: name, category, lat, lon, brand, address, website, phone

Bus Stops Dataset [https://datamall2.mytransport.sg/ltaodataservice/BusStops](url)
-  Information for all bus stops currently being serviced by buses
-  Initial File Type: json
-  Initial Features: BUSSTOPCOD, DESCRIPTION, LATITUDE, LONGITUDE, ROADNAME

### Data Migration

### Data Cleaning 

### Feature Engineering 

### Joining of Data

### Final Data
#### HDB Amenity Master Data
#### HDB Price Master
#### Propwise Master Data

### Continuous Integration & Continuous Deployment

## Machine Learning Model
The final selected model was a XGBoost Regressor. [Insert description]

## Streamlit App 
The streamlit app built on snowflake contains the following features:
