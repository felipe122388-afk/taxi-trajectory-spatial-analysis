-- DATA INGESTION
CREATE TABLE project.taxi (
    TRIP_ID BIGINT PRIMARY KEY,
    CALL_TYPE VARCHAR(255),
    ORIGIN_CALL DECIMAL,
    ORIGIN_STAND DECIMAL,
    TAXI_ID BIGINT,
    TIMESTAMP BIGINT,
    DAY_TYPE VARCHAR(255),
    MISSING_DATA BOOLEAN,
    POLYLINE TEXT
);

--command " "\\copy project.taxi (trip_id, call_type, origin_call, origin_stand, taxi_id, \"timestamp\", day_type, missing_data, polyline) FROM 'C:/Users/jimmy/Desktop/HIGHDI~1/Project/taxi.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8' QUOTE '\"' ESCAPE '''';""

-- DATA QUERY
ALTER TABLE project.taxi ADD COLUMN polyline_geom GEOMETRY;

UPDATE project.taxi
SET polyline_geom = (
    SELECT ST_SetSRID(ST_MakeLine(ARRAY_AGG(ST_MakePoint(coords.lon, coords.lat))), 4326)
    FROM (
        SELECT 
            (json_array_elements(POLYLINE::json)->>0)::FLOAT AS lon, 
            (json_array_elements(POLYLINE::json)->>1)::FLOAT AS lat
        FROM project.taxi AS inner_taxi
        WHERE inner_taxi.TRIP_ID = project.taxi.TRIP_ID
        ORDER BY inner_taxi.TIMESTAMP
    ) AS coords
);