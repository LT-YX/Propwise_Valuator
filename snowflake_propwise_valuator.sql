-- USE WAREHOUSE ado_propwise_valuator; 
USE DATABASE propwise_valuator;

CREATE SCHEMA IF NOT EXISTS raw_data;
CREATE SCHEMA IF NOT EXISTS cleaned_data; -- Cleaned data no feature engineering
CREATE SCHEMA IF NOT EXISTS final_data; -- With features
