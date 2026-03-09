## PREPROCESSING (DROP DUPLICATE, DROP MISSING DATA, DROP DUPLICATE TRIP_ID)
import pandas as pd
preview_data = pd.read_csv('C:\\Users\\jimmy\\Desktop\\High Dimensional Data\\Project\\train\\train.csv')
drop_missing_data = preview_data[preview_data['MISSING_DATA'] != True]
df_unique = drop_missing_data.drop_duplicates()
df_unique = df_unique.drop_duplicates(subset='TRIP_ID')
df_unique.to_csv('taxi.csv', index=False)