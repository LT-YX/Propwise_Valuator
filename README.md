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

CHAS Clinics Dataset [https://data.gov.sg/datasets/d_548c33ea2d99e29ec63a7cc9edcccedc/view]
- CHAS Clinics Locations across Singapore
- Initial Features: Name, Description

Community Club Dataset [https://data.gov.sg/datasets/d_f706de1427279e61fe41e89e24d440fa/view]
- Locations of Community Clubs across Singapore
- Initial Features: Name, Description

Eldercare Services Dataset [https://data.gov.sg/datasets/d_f0fd1b3643ed8bd34bd403dedd7c1533/view]
- Locations of Eldercare Service Centres across Singapore
- Initial Features: Name, Description

School Location Dataset [https://data.gov.sg/datasets/d_688b934f82c1059ed0a6993d2a829089/view]
- Locations of Primary and Secondary Schools, and Junior Colleges from Sep 2025 to Dec 2025
- Initial Description: School Name, Url Address, Address, Postal Code, Telephone No, Telephone No 2, Fax No, Fax No 2, Email Address, Mrt Desc, Bus Desc, Principal Name, First Vp Name, Second Vp Name, Third Vp Name, Fourth Vp Name, Fifth Vp Name, Sixth Vp Name, Dgp Code, Zone Code, Type Code, Nature Code, Session Code, Mainlevel Code, Sap Ind Autonomous Ind, Gifted Ind, Ip Ind, Mothertongue1 Code, Mothertongue2 Code, Mothertongue3 Code

Public Gym Location Dataset [https://data.gov.sg/datasets/d_b3ae090692ecf632116c9885cfbd3424/view]
- Locations of public gyms across Singapore
- Initial Features: Name, Description

Hawker Centre Location Dataset [https://data.gov.sg/datasets/d_4a086da0a5553be1d89383cd90d07ecd/view]
- Locations of Hawker Centres across Singapore
- This is a live dataset hence this is the public API URL: [https://api-open.data.gov.sg/v1/public/api/datasets/d_4a086da0a5553be1d89383cd90d07ecd/poll-download](url)
- Initial Attributes: OBJECTID, LANDXADDRESSPOINT, LANDYADDRESSPOINT, ADDRESSBUILDINGNAME, ADDRESSPOSTALCODE, ADDRESSSTREETNAME, DESCRIPTION, NAME, PHOTOURL, ADDRESSBLOCKHOUSENUMBER, STATUS, AWARDED_DATE, IMPLEMENTATION_DATE, INFO_ON_CO_LOCATORS, ADDRESS_MYENV, EST_ORIGINAL_COMPLETION_DATE, HUP_COMPLETION_DATE, NUMBER_OF_COOKED_FOOD_STALLS, INC_CRC, FMEL_UPD_D

MRT Stations Dataset [https://www.kaggle.com/datasets/shengjunlim/singapore-mrt-lrt-stations-with-coordinates]
- Coordinates and details of the MRT and LRT Stations
- Last updated was 4 years ago hence, the dataset is missing the newest MRT and LRT stations (Thomson-East Coast Line)
- Initial Attributes: OBJECTID, STN_NAME, STN_NO, geometry, Latitude, Longitude

Parks Location Dataset[https://data.gov.sg/datasets/d_0542d48f0991541706b58059381a6eca/view]
- Locations of various parks around Singapore
- Initial Attributes: OBJECTID, NAME, X, Y, INC_CRC, FMEL_UPD_D

Pre-School Location Dataset[https://data.gov.sg/datasets/d_61eefab99958fd70e6aab17320a71f1c/view]
- Locations of pre-schools across Singapore
- Initial Features: Name, Description

Retail Pharmacy Location Dataset [https://data.gov.sg/datasets/d_bb92615f43de22933e4479558b1f6c36/view]
- Locations of retail pharmacy stores across Singapore
- Initial Attributes: OBJECTID_1, POSTAL_CODE, BUILDING_NAME, UNIT_NO, LEVEL_NO, ROAD_NAME, HOUSE_BLK_NO, PHARMACY_NAME, INC_CRC, FMEL_UPD_D

Supermarket Location Dataset [https://data.gov.sg/datasets/d_cac2c32f01960a3ad7202a99c27268a0/view]
- Locations of supermarkets across Singapore
- Initial Features: Name, Description

Water Activity Area Location Dataset [https://data.gov.sg/datasets/d_3db7e1a18c685a2a61ced5a0deb83dae/view]
- Locations of water activity areas such as swimming complexes, and water venture spots for fishing and kayaking
- Initial Features: Name, Description

Hospital Location Dataset [https://www.kaggle.com/datasets/muhdirshath/hospitals-in-singapore]
- Locations of Hospitals across Singapore
- Initial Attributes: hospital_name, address, postal_code, hospital_type, latitude, longitude, town

Shopping Mall Dataset[https://www.kaggle.com/datasets/sunnysharma432/singapore-malls-pois]
- Locations of shopping malls across Singapore
- Initial Attributes: name, category, lat, lon, brand, address, website, phone

Supplement: Shopping Mall Coordinate Dataset [https://www.kaggle.com/datasets/karthikgangula/shopping-mall-coordinates]
- Coordinates of the shopping malls for cross-referencing
- Intial Attributes: Mall Name, LATITUDE, LONGITUDE

Clincs Dataset [https://www.kaggle.com/datasets/sunnysharma432/singapore-clinic-pois]
- Locations of GP Clinics and Polyclinics
- Initial Attributes: name, category, lat, lon, brand, address, website, phone

Bus Stops Dataset [https://datamall2.mytransport.sg/ltaodataservice/BusStops]
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
Our CI/CD pipeline leverages GitHub Actions and Snowflake's native Git integration to automate the deployment of the PropWise data pipeline and Streamlit application, with all SQL scripts, Python notebooks, datasets, and application code stored in this GitHub repository , that enables version control and collaborative development through bidirectional synchronization. We created fine-grained personal access tokens with read/write permissions to enable team members to push changes from Snowflake's UI directly back to GitHub, maintaining a single source of truth across development iterations. The deployment workflow utilizes two GitHub Actions—generate-keys.yml for authentication management and snowflake-deploy.yml for automated pipeline execution—that automatically connect to Snowflake and execute SQL scripts in sequence when changes are pushed to the main branch, eliminating manual execution errors. Following a trunk-based version control approach, all team members work on the main branch with frequent commits and descriptive messages, using Snowflake's integrated "Push to Git" feature for notebooks and Streamlit code updates while maintaining the environment.yml file for reproducible package environments. We use ALTER GIT REPOSITORY ... FETCH to pull the latest changes before running SQL scripts, ensuring Snowflake always executes the most current pipeline version, and while automated unit tests were not implemented due to time constraints and can be considered for future improvements, the CI/CD setup provides rapid feedback loops through GitHub Actions logs and Snowsight visibility, allowing quick identification and resolution of issues before they impact model training or user-facing features.

## Machine Learning Model
The final selected model was a XGBoost Regressor. The XGBoost regression model delivers significant business value to PropWise users through accurate HDB resale price predictions, achieving an R² score of 0.7964 and Mean Absolute Error of $60,732.78, with 43.74% of predictions falling within ±10% of actual prices. The model leverages 9 carefully engineered features including composite amenity scores (fitness_recreation, food_daily_groceries, healthcare_access, childcare_family), location characteristics (NEAREST_MRT_DISTANCE_M, TOWN), and property attributes (FLAT_TYPE, STOREY_RANGE, age_category) to capture complex relationships between neighborhood desirability and property valuation. XGBoost was selected over the Gradient Boosting Regressor baseline due to superior performance—improving R² by 3.5% (from 0.7607 to 0.7964) and reducing RMSE by $4,600 (from $81,703 to $77,097), demonstrating better generalization on unseen properties. This enhanced accuracy enables homebuyers and sellers to receive reliable, data-driven price estimates through the Streamlit interface, reducing the risk of overpaying or undervaluing properties by tens of thousands of dollars in Singapore's competitive housing market.

## Streamlit App : PropWise Smart Valuator 
PropWise Smart Valuator is a streamlit based web application. Its designed to analyse and predict HDB resale prices using data driven insights and machine learning. The application combines market trends, amenity influence analysis and role based dashboards to support better property related decision making for home buyers, home sellers and property agents.

The streamlit app built on snowflake contains the following features :
- Price Prediction : Predicts HDB resale prices using a machine learning model based on the flat attributes, location, amenities and MRT proximity.
- User Specific Data : Delivers role based property insights tailored for home buyers, home sellers and property agents to support different decision making needs.
- Amenities Explorer : Visualises nearby amenities and accessibility of a chosen property through interactive map and amenity scores. 
