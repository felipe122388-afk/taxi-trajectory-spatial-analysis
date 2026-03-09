# 🧹 Data Cleaning & Preprocessing Notes

## Overview
Before ingesting the Taxi Trajectory dataset into PostgreSQL, it was necessary to perform an initial data cleaning pass using Python and Pandas. We ran this preprocessing step because we needed to ensure there were no duplicate primary keys (`TRIP_ID`), duplicate row values, or records containing missing data before conducting further spatial analysis.

## Preprocessing Pipeline (`preprocessing.py`)
The preprocessing script was designed to enforce entity integrity and ensure data quality prior to database table creation. The pipeline executes three primary operations:

1. **Missing Data Elimination:** The dataset includes a `MISSING_DATA` boolean flag. Any trajectory flagged as missing data was dropped (`MISSING_DATA != True`) to ensure that downstream PostGIS functions (like `ST_MakeLine`) would not fail or create invalid geometries.
2. **General Deduplication:** We executed a standard `.drop_duplicates()` pass to remove any exact row-level duplicates caused by potential logging errors in the source taxi tracking systems.
3. **Primary Key Integrity Enforcement:** To ensure smooth ingestion into the PostgreSQL database, we enforced strict uniqueness on the `TRIP_ID` column (`drop_duplicates(subset='TRIP_ID')`). Since `TRIP_ID` serves as the `PRIMARY KEY` in the PostgreSQL table, removing duplicates at the Python level prevents fatal constraint errors during the bulk `COPY` ingestion process.

## Python Implementation

```python
## PREPROCESSING (DROP DUPLICATE, DROP MISSING DATA, DROP DUPLICATE TRIP_ID)
import pandas as pd

preview_data = pd.read_csv('C:\\Users\\jimmy\\Desktop\\High Dimensional Data\\Project\\train\\train.csv')
drop_missing_data = preview_data[preview_data['MISSING_DATA'] != True]
df_unique = drop_missing_data.drop_duplicates()
df_unique = df_unique.drop_duplicates(subset='TRIP_ID')
df_unique.to_csv('taxi.csv', index=False)