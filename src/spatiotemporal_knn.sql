---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Query Task 2 Starts Here------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
-- Query 2: find k nearest neighbours (data points) of a given trajectory for a given date.
-- Note that I set distance > 0 to exclude itself and trajectory with intersections. 
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;

-- Indexing Methods: 1) GiST (Generalized Search Tree) indexing
CREATE INDEX idx_taxi_polyline_geom ON project.taxi USING GIST (polyline_geom);

-- Test Case 1: find 5 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-15.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;
-- result 
-- trip_id             distance
-- 1392438424620000680 7.090547379847815e-07
-- 1392469341620000384 1.8281713586179918e-06
-- 1392471028620000363 2.6581575095489923e-06
-- 1392438555620000324 3.283606343051537e-06
-- 1392494396620000255 5.180646585995553e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;

-- Query Plan Result
"Limit  (cost=15810.90..15810.91 rows=5 width=16) (actual time=63996.001..63996.003 rows=5 loops=1)"
"  Buffers: shared hit=122073 read=1440772"
"  ->  Sort  (cost=15810.90..15811.56 rows=262 width=16) (actual time=63995.998..63995.999 rows=5 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=122073 read=1440772"
"        ->  Nested Loop  (cost=0.96..15806.55 rows=262 width=16) (actual time=54.426..63991.666 rows=2537 loops=1)"
"              Buffers: shared hit=122073 read=1440772"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.041..0.045 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared hit=1 read=3"
"              ->  Index Scan using idx_taxi_polyline_geom on taxi t  (cost=0.54..9248.09 rows=1 width=828) (actual time=54.347..63577.526 rows=2537 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-15'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1552463"
"                    Buffers: shared hit=122067 read=1440769"
"Planning:"
"  Buffers: shared hit=7 read=15"
"Planning Time: 4.844 ms"
"Execution Time: 63998.469 ms"

-- Test Case 2: find 3 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-13.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392293532620000001 5.879465279264631e-07
-- 1392289720620000515 8.600570406136264e-07
-- 1392309807620000006 2.0000846825219686e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=15809.94..15809.94 rows=3 width=16) (actual time=57992.517..57992.520 rows=3 loops=1)"
"  Buffers: shared hit=122059 read=1440757"
"  ->  Sort  (cost=15809.94..15810.59 rows=262 width=16) (actual time=57992.515..57992.516 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=122059 read=1440757"
"        ->  Nested Loop  (cost=0.96..15806.55 rows=262 width=16) (actual time=113.513..57988.639 rows=2292 loops=1)"
"              Buffers: shared hit=122059 read=1440757"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.066..0.070 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared hit=1 read=3"
"              ->  Index Scan using idx_taxi_polyline_geom on taxi t  (cost=0.54..9248.09 rows=1 width=828) (actual time=113.414..57568.777 rows=2292 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-13'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1552708"
"                    Buffers: shared hit=122058 read=1440754"
"Planning Time: 1.881 ms"
"Execution Time: 57992.716 ms"

-- Test Case 3: find 3 nearest neighbours (data points) of a given trajectory 1388739539620000041 for a 2014-02-11.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392093990620000328 5.748239607405721e-07
-- 1392130680620000337 8.430026901944211e-07
-- 1392140858620000595 1.2297365736163398e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=15809.94..15809.94 rows=3 width=16) (actual time=79766.463..79766.465 rows=3 loops=1)"
"  Buffers: shared hit=116179 read=1509042"
"  ->  Sort  (cost=15809.94..15810.59 rows=262 width=16) (actual time=79766.461..79766.462 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=116179 read=1509042"
"        ->  Nested Loop  (cost=0.96..15806.55 rows=262 width=16) (actual time=139.841..79763.295 rows=1400 loops=1)"
"              Buffers: shared hit=116179 read=1509042"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.107..0.109 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1388739539620000041'::bigint)"
"                    Buffers: shared hit=1 read=3"
"              ->  Index Scan using idx_taxi_polyline_geom on taxi t  (cost=0.54..9248.09 rows=1 width=828) (actual time=139.617..79403.781 rows=1400 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-11'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1615974"
"                    Buffers: shared hit=116178 read=1509039"
"Planning Time: 3.116 ms"
"Execution Time: 79766.596 ms"

-- DROP INDEX
DROP INDEX project.idx_taxi_polyline_geom

-- Indexing Methods: 2) Space-Partitioned GiST (SP-GiST) Index
CREATE INDEX idx_taxi_polyline_geom_spgist ON project.taxi USING SPGiST (polyline_geom);

-- Test Case 1: find 5 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-15.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;
-- result 
-- trip_id             distance
-- 1392438424620000680 7.090547379847815e-07
-- 1392469341620000384 1.8281713586179918e-06
-- 1392471028620000363 2.6581575095489923e-06
-- 1392438555620000324 3.283606343051537e-06
-- 1392494396620000255 5.180646585995553e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;

-- Query Plan Result
"Limit  (cost=15806.78..15806.79 rows=5 width=16) (actual time=120330.272..120330.274 rows=5 loops=1)"
"  Buffers: shared hit=133600 read=1530621 written=6668"
"  ->  Sort  (cost=15806.78..15807.43 rows=262 width=16) (actual time=120330.269..120330.270 rows=5 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=133600 read=1530621 written=6668"
"        ->  Nested Loop  (cost=0.84..15802.42 rows=262 width=16) (actual time=8.474..120322.554 rows=2537 loops=1)"
"              Buffers: shared hit=133600 read=1530621 written=6668"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.379..0.382 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared read=4"
"              ->  Index Scan using idx_taxi_polyline_geom_spgist on taxi t  (cost=0.41..9243.97 rows=1 width=828) (actual time=7.981..119868.689 rows=2537 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-15'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1552463"
"                    Buffers: shared hit=133595 read=1530617 written=6668"
"Planning:"
"  Buffers: shared hit=26 read=11 dirtied=3"
"Planning Time: 8.491 ms"
"Execution Time: 120330.471 ms"

-- Test Case 2: find 3 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-13.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392293532620000001 5.879465279264631e-07
-- 1392289720620000515 8.600570406136264e-07
-- 1392309807620000006 2.0000846825219686e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=15805.81..15805.82 rows=3 width=16) (actual time=47580.478..47580.480 rows=3 loops=1)"
"  Buffers: shared hit=133599 read=1530611"
"  ->  Sort  (cost=15805.81..15806.47 rows=262 width=16) (actual time=47580.477..47580.478 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=133599 read=1530611"
"        ->  Nested Loop  (cost=0.84..15802.42 rows=262 width=16) (actual time=9.968..47573.362 rows=2292 loops=1)"
"              Buffers: shared hit=133599 read=1530611"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.087..0.089 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared hit=1 read=3"
"              ->  Index Scan using idx_taxi_polyline_geom_spgist on taxi t  (cost=0.41..9243.97 rows=1 width=828) (actual time=9.685..47107.552 rows=2292 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-13'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1552708"
"                    Buffers: shared hit=133598 read=1530608"
"Planning Time: 3.078 ms"
"Execution Time: 47580.637 ms"

-- Test Case 3: find 3 nearest neighbours (data points) of a given trajectory 1388739539620000041 for a 2014-02-11.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392093990620000328 5.748239607405721e-07
-- 1392130680620000337 8.430026901944211e-07
-- 1392140858620000595 1.2297365736163398e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=15805.81..15805.82 rows=3 width=16) (actual time=58197.106..58197.109 rows=3 loops=1)"
"  Buffers: shared hit=139516 read=1590938"
"  ->  Sort  (cost=15805.81..15806.47 rows=262 width=16) (actual time=58197.103..58197.105 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=139516 read=1590938"
"        ->  Nested Loop  (cost=0.84..15802.42 rows=262 width=16) (actual time=265.381..58192.411 rows=1400 loops=1)"
"              Buffers: shared hit=139516 read=1590938"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.087..0.091 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1388739539620000041'::bigint)"
"                    Buffers: shared read=4"
"              ->  Index Scan using idx_taxi_polyline_geom_spgist on taxi t  (cost=0.41..9243.97 rows=1 width=828) (actual time=265.124..57806.309 rows=1400 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-11'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1615974"
"                    Buffers: shared hit=139516 read=1590934"
"Planning Time: 1.905 ms"
"Execution Time: 58197.278 ms"

-- DROP INDEX
DROP INDEX project.idx_taxi_polyline_geom_spgist

-- Indexing Methods: 3) Block Range Index (BRIN)
CREATE INDEX idx_taxi_polyline_geom_brin ON project.taxi USING BRIN (polyline_geom);

-- Test Case 1: find 5 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-15.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;
-- result 
-- trip_id             distance
-- 1392438424620000680 7.090547379847815e-07
-- 1392469341620000384 1.8281713586179918e-06
-- 1392471028620000363 2.6581575095489923e-06
-- 1392438555620000324 3.283606343051537e-06
-- 1392494396620000255 5.180646585995553e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-15' AND distance > 0
ORDER BY distance
LIMIT 5;

-- Query Plan Result
"Limit  (cost=858741.47..858741.48 rows=5 width=16) (actual time=25423.011..25423.013 rows=5 loops=1)"
"  Buffers: shared hit=176 read=917882 written=3"
"  ->  Sort  (cost=858741.47..858742.13 rows=262 width=16) (actual time=25423.009..25423.011 rows=5 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=176 read=917882 written=3"
"        ->  Nested Loop  (cost=147.74..858737.12 rows=262 width=16) (actual time=368.867..25419.725 rows=2537 loops=1)"
"              Buffers: shared hit=176 read=917882 written=3"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.326..0.329 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared read=4"
"              ->  Bitmap Heap Scan on taxi t  (cost=147.32..852178.67 rows=1 width=828) (actual time=368.496..24933.747 rows=2537 loops=1)"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-15'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1707920"
"                    Heap Blocks: lossy=376839"
"                    Buffers: shared hit=171 read=917878 written=3"
"                    ->  Bitmap Index Scan on idx_taxi_polyline_geom_brin  (cost=0.00..147.32 rows=15894 width=0) (actual time=46.465..46.465 rows=9179810 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                          Buffers: shared hit=55 read=3"
"Planning:"
"  Buffers: shared hit=23 read=6 dirtied=3"
"Planning Time: 10.866 ms"
"Execution Time: 25423.328 ms"

-- Test Case 2: find 3 nearest neighbours (data points) of a given trajectory 1403165135620000041 for a 2014-02-13.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392293532620000001 5.879465279264631e-07
-- 1392289720620000515 8.600570406136264e-07
-- 1392309807620000006 2.0000846825219686e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1403165135620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-13' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=858740.51..858740.51 rows=3 width=16) (actual time=25335.875..25335.877 rows=3 loops=1)"
"  Buffers: shared hit=18 read=918026"
"  ->  Sort  (cost=858740.51..858741.16 rows=262 width=16) (actual time=25335.874..25335.875 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=18 read=918026"
"        ->  Nested Loop  (cost=147.74..858737.12 rows=262 width=16) (actual time=425.325..25332.319 rows=2292 loops=1)"
"              Buffers: shared hit=18 read=918026"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=0.047..0.050 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1403165135620000041'::bigint)"
"                    Buffers: shared hit=1 read=3"
"              ->  Bitmap Heap Scan on taxi t  (cost=147.32..852178.67 rows=1 width=828) (actual time=425.169..24850.546 rows=2292 loops=1)"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-13'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1708165"
"                    Heap Blocks: lossy=376839"
"                    Buffers: shared hit=17 read=918023"
"                    ->  Bitmap Index Scan on idx_taxi_polyline_geom_brin  (cost=0.00..147.32 rows=15894 width=0) (actual time=48.574..48.574 rows=9179810 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                          Buffers: shared hit=11 read=38"
"Planning:"
"  Buffers: shared hit=2"
"Planning Time: 2.001 ms"
"Execution Time: 25336.074 ms"

-- Test Case 3: find 3 nearest neighbours (data points) of a given trajectory 1388739539620000041 for a 2014-02-11.
-- Code:
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;
-- result 
-- trip_id             distance
-- 1392093990620000328 5.748239607405721e-07
-- 1392130680620000337 8.430026901944211e-07
-- 1392140858620000595 1.2297365736163398e-06

-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH SelectedTrajectory AS (
    SELECT polyline_geom
    FROM project.taxi
    WHERE trip_id = 1388739539620000041
),
filteredTrajectory AS(
    SELECT t.trip_id, ST_Distance(t.polyline_geom, st.polyline_geom) as distance, t.TIMESTAMP
    FROM project.taxi t, SelectedTrajectory st
    WHERE ST_DWithin(t.polyline_geom, st.polyline_geom, 0.01)
)
SELECT trip_id, distance
FROM filteredTrajectory
WHERE DATE(timestamp 'epoch' + TIMESTAMP * INTERVAL '1 second') = '2014-02-11' AND distance > 0
ORDER BY distance
LIMIT 3;

-- Query Plan Result
"Limit  (cost=858740.51..858740.51 rows=3 width=16) (actual time=23896.699..23896.701 rows=3 loops=1)"
"  Buffers: shared hit=17 read=921355"
"  ->  Sort  (cost=858740.51..858741.16 rows=262 width=16) (actual time=23896.697..23896.699 rows=3 loops=1)"
"        Sort Key: (st_distance(t.polyline_geom, taxi.polyline_geom))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=17 read=921355"
"        ->  Nested Loop  (cost=147.74..858737.12 rows=262 width=16) (actual time=394.798..23895.315 rows=1400 loops=1)"
"              Buffers: shared hit=17 read=921355"
"              ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=12.522..12.525 rows=1 loops=1)"
"                    Index Cond: (trip_id = '1388739539620000041'::bigint)"
"                    Buffers: shared read=4"
"              ->  Bitmap Heap Scan on taxi t  (cost=147.32..852178.67 rows=1 width=828) (actual time=382.071..23557.876 rows=1400 loops=1)"
"                    Filter: ((date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-11'::date) AND st_dwithin(polyline_geom, taxi.polyline_geom, '0.01'::double precision) AND (st_distance(polyline_geom, taxi.polyline_geom) > '0'::double precision))"
"                    Rows Removed by Filter: 1709104"
"                    Heap Blocks: lossy=376883"
"                    Buffers: shared hit=17 read=921351"
"                    ->  Bitmap Index Scan on idx_taxi_polyline_geom_brin  (cost=0.00..147.32 rows=15894 width=0) (actual time=44.688..44.688 rows=9213090 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(taxi.polyline_geom, '0.01'::double precision))"
"                          Buffers: shared hit=11 read=38"
"Planning:"
"  Buffers: shared hit=2"
"Planning Time: 2.722 ms"
"Execution Time: 23896.869 ms"

--Drop Index
DROP INDEX project.idx_taxi_polyline_geom_brin