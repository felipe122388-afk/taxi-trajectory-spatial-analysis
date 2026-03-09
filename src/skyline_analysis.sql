-- Query 3: find the skyline data points for specific day
-- Firstly I want to convert polyline_geom from geometry to geography type to calculate the distance in meters
-- Naming the new columns as Distance
ALTER TABLE project.taxi ADD COLUMN distance FLOAT;
UPDATE project.taxi SET distance = ST_Length(polyline_geom::geography);

-- Then calculate the time spent for each journey, naming travel_time
ALTER TABLE project.taxi ADD COLUMN travel_time INTEGER;
UPDATE project.taxi
SET travel_time = (json_array_length(POLYLINE::json) - 1) * 15
WHERE POLYLINE IS NOT NULL AND POLYLINE != '';

-- Finally I will calculate skyline points for specific day
-- The definition for my skyline point is: no other trip can be found that is shorter in time and equal or longer in distance, 
-- or equal in time and longer in distance, in the mean time, it should dominant either in time(less time) or distance(longer distance)

WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Indexing Methods: 1) HASH indexing
CREATE INDEX idx_hash_timestamp ON project.taxi USING HASH(DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second'));

-- Test Case 1: find the skyline data points for 2014-02-10
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time  distance
1392046061620000539 2055        45015.29597859004
1392033344620000337 5325        180215.0683398623
1392055794620000455 1485        32443.96288541276
1392035080620000351 555         14444.837465458722
1392062633620000233 4770        96509.9981003105
1392068617620000324 1050        18903.784795555825
1392068174620000486 1935        37950.32021733608
1392065883620000188 435         10756.820242352154
1392057557620000545 1095        21976.21698334558
1392056223620000539 1425        32146.85357590408
1392032127620000496 2175        55287.672161467366
1392011949620000406 60          9281.852962533772
1392011631620000080 15          395.81328285916237
1391991304620000672 45          6408.019055998595
1392011010620000076 765         15706.804811356827
1392008099620000041 1260        22735.99128830954
1392006937620000904 1035        18848.46008909188
1391990690620000472 405         10732.733771263627
1392022928620000271 2985        56377.4361250254
1392024366620000351 4080        56549.041186351315
1392036453620000140 930         18700.212006248796
1392038221620000514 825         16300.608115694266
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- Query Plan Result
"Nested Loop Anti Join  (cost=30274.96..278230.80 rows=2675 width=20) (actual time=18.447..521.024 rows=25 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 494045"
"  Buffers: shared hit=1332, temp read=64585 written=443"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=268.86..30274.96 rows=2851 width=840) (actual time=0.587..7.752 rows=3932 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 161"
"          Heap Blocks: exact=1310"
"          Buffers: shared hit=1332"
"          ->  Bitmap Index Scan on idx_hash_timestamp  (cost=0.00..268.15 rows=8553 width=0) (actual time=0.434..0.435 rows=4093 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"                Buffers: shared hit=22"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.590..19.142 rows=3932 loops=1)"
"        Buffers: shared hit=23, temp read=3751 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.106 rows=127 loops=3932)"
"        Buffers: shared hit=1309, temp read=60834 written=442"
"Planning:"
"  Buffers: shared hit=18"
"Planning Time: 2.883 ms"
"Execution Time: 534.896 ms"

-- Test Case 2: find the skyline data points for 2014-01-15
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time distance
1389748815620000486 1140        28118.974027674914
1389770277620000904 690         14116.999865299822
1389764776620000424 510         10865.076114175992
1389757893620000686 1635        38392.72711953112
1389746126620000518 75          3889.395742111015
1389780769620000177 1455        30984.950226305045
1389782251620000465 585         11459.003218601483
1389799229620000351 735         20591.79110836946
1389787931620000356 1665        39506.514551576554
1389799149620000166 495         9322.019292764988
1389787981620000902 10935       112258.95447424882
1389805723620000333 600         13626.23857984337
1389776871620000588 1875        80454.50120065194
1389795868620000432 90          8493.624920376784
1389805203620000372 15          189.94468790543132
1389751293620000167 30          1378.533461822585
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30274.96..278230.80 rows=2675 width=20) (actual time=56.294..357.590 rows=16 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 420425"
"  Buffers: shared hit=1312, temp read=38913 written=458"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=268.86..30274.96 rows=2851 width=840) (actual time=0.615..10.121 rows=4081 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 80"
"          Heap Blocks: exact=1301"
"          Buffers: shared hit=1312"
"          ->  Bitmap Index Scan on idx_hash_timestamp  (cost=0.00..268.15 rows=8553 width=0) (actual time=0.423..0.423 rows=4161 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"                Buffers: shared hit=11"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.623..20.041 rows=4081 loops=1)"
"        Buffers: shared hit=12, temp read=4051 written=2"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.065 rows=104 loops=4081)"
"        Buffers: shared hit=1300, temp read=34862 written=456"
"Planning Time: 0.243 ms"
"Execution Time: 367.228 ms"


-- Test Case 3: find the skyline data points for 2014-03-01
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- result
/*
trip_id             travel_time distance
1393692918620000281 1170        21008.126638534526
1393689045620000372 4410        119589.1914648556
1393695228620000591 4350        66120.94252570442
1393710418620000663 1320        31609.831563258045
1393714314620000276 510         13897.219027259403
1393713347620000421 135         5685.105472029188
1393714218620000151 75          4589.743422011342
1393636949620000012 915         18621.365137616434
1393647904620000435 1110        20318.014011125328
1393652708620000199 855         18558.443673656282
1393659811620000118 60          4355.9082310167705
1393659948620000351 1950        47005.34457387665
1393660350620000393 2340        62324.05963262545
1393671396620000351 960         18695.492755868498
1393674281620000344 1005        19397.348213891884
1393669947620000364 1200        24166.438832010062
1393676720620000351 615         14064.388752090044
1393676823620000370 660         16907.106261668978
1393702965620000177 375         12725.977788806878
1393686751620000591 1785        33754.4296409821
1393687354620000351 1980        48536.815605006115
1393634613620000618 15          941.534702347916
1393665772620000541 14685       164256.0020867919
1393648063620000534 1035        20097.124002356362
1393710719620000160 1125        20372.847657733648
1393700054620000180 165         6202.800780130278
1393713559620000640 30          4235.723389483161
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30274.96..278230.80 rows=2675 width=20) (actual time=28.075..960.466 rows=27 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 1015249"
"  Buffers: shared hit=1708 read=81, temp read=94231 written=554"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=268.86..30274.96 rows=2851 width=840) (actual time=1.249..11.918 rows=5687 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 73"
"          Heap Blocks: exact=1774"
"          Buffers: shared hit=1708 read=81"
"          ->  Bitmap Index Scan on idx_hash_timestamp  (cost=0.00..268.15 rows=8553 width=0) (actual time=0.911..0.911 rows=5760 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"                Buffers: shared hit=15"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=1.256..28.368 rows=5687 loops=1)"
"        Buffers: shared hit=16, temp read=5436 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.128 rows=180 loops=5687)"
"        Buffers: shared hit=1692 read=81, temp read=88795 written=553"
"Planning Time: 0.216 ms"
"Execution Time: 966.322 ms"

-- DROP INDEX
DROP INDEX project.idx_hash_timestamp

-- Indexing Methods: 2) BRIN indexing
CREATE INDEX idx_brin_timestamp ON project.taxi USING BRIN(DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second'));

-- Test Case 1: find the skyline data points for 2014-02-10
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time  distance
1392046061620000539 2055        45015.29597859004
1392033344620000337 5325        180215.0683398623
1392055794620000455 1485        32443.96288541276
1392035080620000351 555         14444.837465458722
1392062633620000233 4770        96509.9981003105
1392068617620000324 1050        18903.784795555825
1392068174620000486 1935        37950.32021733608
1392065883620000188 435         10756.820242352154
1392057557620000545 1095        21976.21698334558
1392056223620000539 1425        32146.85357590408
1392032127620000496 2175        55287.672161467366
1392011949620000406 60          9281.852962533772
1392011631620000080 15          395.81328285916237
1391991304620000672 45          6408.019055998595
1392011010620000076 765         15706.804811356827
1392008099620000041 1260        22735.99128830954
1392006937620000904 1035        18848.46008909188
1391990690620000472 405         10732.733771263627
1392022928620000271 2985        56377.4361250254
1392024366620000351 4080        56549.041186351315
1392036453620000140 930         18700.212006248796
1392038221620000514 825         16300.608115694266
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=14.281..521.892 rows=25 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 494045"
"  Buffers: shared hit=1310 read=7, temp read=64585 written=443"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=0.607..4.423 rows=3932 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 161"
"          Heap Blocks: exact=1310"
"          Buffers: shared hit=1310 read=7"
"          ->  Bitmap Index Scan on idx_brin_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=0.425..0.425 rows=4093 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"                Buffers: shared read=7"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.613..18.191 rows=3932 loops=1)"
"        Buffers: shared hit=1 read=7, temp read=3751 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.099 rows=127 loops=3932)"
"        Buffers: shared hit=1309, temp read=60834 written=442"
"Planning:"
"  Buffers: shared hit=24 read=1"
"Planning Time: 3.943 ms"
"Execution Time: 536.059 ms"

-- Test Case 2: find the skyline data points for 2014-01-15
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time distance
1389748815620000486 1140        28118.974027674914
1389770277620000904 690         14116.999865299822
1389764776620000424 510         10865.076114175992
1389757893620000686 1635        38392.72711953112
1389746126620000518 75          3889.395742111015
1389780769620000177 1455        30984.950226305045
1389782251620000465 585         11459.003218601483
1389799229620000351 735         20591.79110836946
1389787931620000356 1665        39506.514551576554
1389799149620000166 495         9322.019292764988
1389787981620000902 10935       112258.95447424882
1389805723620000333 600         13626.23857984337
1389776871620000588 1875        80454.50120065194
1389795868620000432 90          8493.624920376784
1389805203620000372 15          189.94468790543132
1389751293620000167 30          1378.533461822585
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=39.030..340.854 rows=16 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 420425"
"  Buffers: shared hit=1302 read=6, temp read=38913 written=458"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=0.636..4.613 rows=4081 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 80"
"          Heap Blocks: exact=1301"
"          Buffers: shared hit=1302 read=6"
"          ->  Bitmap Index Scan on idx_brin_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=0.493..0.493 rows=4161 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"                Buffers: shared hit=1 read=6"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.640..19.860 rows=4081 loops=1)"
"        Buffers: shared hit=2 read=6, temp read=4051 written=2"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.061 rows=104 loops=4081)"
"        Buffers: shared hit=1300, temp read=34862 written=456"
"Planning Time: 0.242 ms"
"Execution Time: 349.597 ms"


-- Test Case 3: find the skyline data points for 2014-03-01
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- result
/*
trip_id             travel_time distance
1393692918620000281 1170        21008.126638534526
1393689045620000372 4410        119589.1914648556
1393695228620000591 4350        66120.94252570442
1393710418620000663 1320        31609.831563258045
1393714314620000276 510         13897.219027259403
1393713347620000421 135         5685.105472029188
1393714218620000151 75          4589.743422011342
1393636949620000012 915         18621.365137616434
1393647904620000435 1110        20318.014011125328
1393652708620000199 855         18558.443673656282
1393659811620000118 60          4355.9082310167705
1393659948620000351 1950        47005.34457387665
1393660350620000393 2340        62324.05963262545
1393671396620000351 960         18695.492755868498
1393674281620000344 1005        19397.348213891884
1393669947620000364 1200        24166.438832010062
1393676720620000351 615         14064.388752090044
1393676823620000370 660         16907.106261668978
1393702965620000177 375         12725.977788806878
1393686751620000591 1785        33754.4296409821
1393687354620000351 1980        48536.815605006115
1393634613620000618 15          941.534702347916
1393665772620000541 14685       164256.0020867919
1393648063620000534 1035        20097.124002356362
1393710719620000160 1125        20372.847657733648
1393700054620000180 165         6202.800780130278
1393713559620000640 30          4235.723389483161
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=19.309..841.744 rows=27 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 1015249"
"  Buffers: shared hit=1776 read=5, temp read=94231 written=554"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=0.841..5.200 rows=5687 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 73"
"          Heap Blocks: exact=1774"
"          Buffers: shared hit=1776 read=5"
"          ->  Bitmap Index Scan on idx_brin_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=0.605..0.605 rows=5760 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"                Buffers: shared hit=2 read=5"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.852..26.742 rows=5687 loops=1)"
"        Buffers: shared hit=3 read=5, temp read=5436 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.113 rows=180 loops=5687)"
"        Buffers: shared hit=1773, temp read=88795 written=553"
"Planning Time: 0.229 ms"
"Execution Time: 844.148 ms"

-- DROP INDEX
DROP INDEX project.idx_brin_timestamp

-- Indexing Methods: BTREE Index
CREATE INDEX idx_btree_timestamp ON project.taxi USING BTREE(DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second'));

-- Test Case 1: find the skyline data points for 2014-02-10
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time  distance
1392046061620000539 2055        45015.29597859004
1392033344620000337 5325        180215.0683398623
1392055794620000455 1485        32443.96288541276
1392035080620000351 555         14444.837465458722
1392062633620000233 4770        96509.9981003105
1392068617620000324 1050        18903.784795555825
1392068174620000486 1935        37950.32021733608
1392065883620000188 435         10756.820242352154
1392057557620000545 1095        21976.21698334558
1392056223620000539 1425        32146.85357590408
1392032127620000496 2175        55287.672161467366
1392011949620000406 60          9281.852962533772
1392011631620000080 15          395.81328285916237
1391991304620000672 45          6408.019055998595
1392011010620000076 765         15706.804811356827
1392008099620000041 1260        22735.99128830954
1392006937620000904 1035        18848.46008909188
1391990690620000472 405         10732.733771263627
1392022928620000271 2985        56377.4361250254
1392024366620000351 4080        56549.041186351315
1392036453620000140 930         18700.212006248796
1392038221620000514 825         16300.608115694266
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-02-10'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=13.483..557.826 rows=25 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 494045"
"  Buffers: shared hit=1310 read=7, temp read=64585 written=443"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=0.487..3.768 rows=3932 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 161"
"          Heap Blocks: exact=1310"
"          Buffers: shared hit=1310 read=7"
"          ->  Bitmap Index Scan on idx_btree_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=0.334..0.335 rows=4093 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-02-10'::date)"
"                Buffers: shared read=7"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.491..19.520 rows=3932 loops=1)"
"        Buffers: shared hit=1 read=7, temp read=3751 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.114 rows=127 loops=3932)"
"        Buffers: shared hit=1309, temp read=60834 written=442"
"Planning:"
"  Buffers: shared hit=19 read=1"
"Planning Time: 3.129 ms"
"Execution Time: 560.844 ms"

-- Test Case 2: find the skyline data points for 2014-01-15
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;
-- result
/*
trip_id             travel_time distance
1389748815620000486 1140        28118.974027674914
1389770277620000904 690         14116.999865299822
1389764776620000424 510         10865.076114175992
1389757893620000686 1635        38392.72711953112
1389746126620000518 75          3889.395742111015
1389780769620000177 1455        30984.950226305045
1389782251620000465 585         11459.003218601483
1389799229620000351 735         20591.79110836946
1389787931620000356 1665        39506.514551576554
1389799149620000166 495         9322.019292764988
1389787981620000902 10935       112258.95447424882
1389805723620000333 600         13626.23857984337
1389776871620000588 1875        80454.50120065194
1389795868620000432 90          8493.624920376784
1389805203620000372 15          189.94468790543132
1389751293620000167 30          1378.533461822585
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-01-15'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=48.211..339.304 rows=16 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 420425"
"  Buffers: shared hit=1302 read=6, temp read=38913 written=458"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=0.815..5.561 rows=4081 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 80"
"          Heap Blocks: exact=1301"
"          Buffers: shared hit=1302 read=6"
"          ->  Bitmap Index Scan on idx_btree_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=0.595..0.596 rows=4161 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-01-15'::date)"
"                Buffers: shared hit=1 read=6"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.821..19.920 rows=4081 loops=1)"
"        Buffers: shared hit=2 read=6, temp read=4051 written=2"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.060 rows=104 loops=4081)"
"        Buffers: shared hit=1300, temp read=34862 written=456"
"Planning Time: 0.156 ms"
"Execution Time: 353.657 ms"


-- Test Case 3: find the skyline data points for 2014-03-01
-- Code:
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- result
/*
trip_id             travel_time distance
1393692918620000281 1170        21008.126638534526
1393689045620000372 4410        119589.1914648556
1393695228620000591 4350        66120.94252570442
1393710418620000663 1320        31609.831563258045
1393714314620000276 510         13897.219027259403
1393713347620000421 135         5685.105472029188
1393714218620000151 75          4589.743422011342
1393636949620000012 915         18621.365137616434
1393647904620000435 1110        20318.014011125328
1393652708620000199 855         18558.443673656282
1393659811620000118 60          4355.9082310167705
1393659948620000351 1950        47005.34457387665
1393660350620000393 2340        62324.05963262545
1393671396620000351 960         18695.492755868498
1393674281620000344 1005        19397.348213891884
1393669947620000364 1200        24166.438832010062
1393676720620000351 615         14064.388752090044
1393676823620000370 660         16907.106261668978
1393702965620000177 375         12725.977788806878
1393686751620000591 1785        33754.4296409821
1393687354620000351 1980        48536.815605006115
1393634613620000618 15          941.534702347916
1393665772620000541 14685       164256.0020867919
1393648063620000534 1035        20097.124002356362
1393710719620000160 1125        20372.847657733648
1393700054620000180 165         6202.800780130278
1393713559620000640 30          4235.723389483161
*/
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH LongestOfDay AS (
    SELECT
        trip_id,
        polyline_geom,
        travel_time,
        distance
    FROM 
        project.taxi
    WHERE
        DATE(timestamp 'epoch' + timestamp * INTERVAL '1 second') = '2014-03-01'
    AND 
        distance > 0
)
SELECT a.trip_id, a.travel_time, a.distance
FROM LongestOfDay a
LEFT JOIN LongestOfDay b ON 
    b.travel_time <= a.travel_time AND 
    b.distance >= a.distance AND 
    (b.travel_time < a.travel_time OR b.distance > a.distance) AND 
    a.trip_id <> b.trip_id
WHERE b.trip_id IS NULL;

-- Query Plan Result
"Nested Loop Anti Join  (cost=30103.39..278059.23 rows=2675 width=20) (actual time=24.389..892.339 rows=27 loops=1)"
"  Join Filter: ((b.travel_time <= a.travel_time) AND (b.distance >= a.distance) AND (a.trip_id <> b.trip_id) AND ((b.travel_time < a.travel_time) OR (b.distance > a.distance)))"
"  Rows Removed by Join Filter: 1015249"
"  Buffers: shared hit=1776 read=5, temp read=94231 written=554"
"  CTE longestofday"
"    ->  Bitmap Heap Scan on taxi  (cost=97.29..30103.39 rows=2851 width=840) (actual time=1.411..6.458 rows=5687 loops=1)"
"          Recheck Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"          Filter: (distance > '0'::double precision)"
"          Rows Removed by Filter: 73"
"          Heap Blocks: exact=1774"
"          Buffers: shared hit=1776 read=5"
"          ->  Bitmap Index Scan on idx_btree_timestamp  (cost=0.00..96.57 rows=8553 width=0) (actual time=1.059..1.059 rows=5760 loops=1)"
"                Index Cond: (date(('1970-01-01 00:00:00'::timestamp without time zone + ((""timestamp"")::double precision * '00:00:01'::interval))) = '2014-03-01'::date)"
"                Buffers: shared hit=2 read=5"
"  ->  CTE Scan on longestofday a  (cost=0.00..57.02 rows=2851 width=20) (actual time=1.421..33.412 rows=5687 loops=1)"
"        Buffers: shared hit=3 read=5, temp read=5436 written=1"
"  ->  CTE Scan on longestofday b  (cost=0.00..57.02 rows=2851 width=20) (actual time=0.004..0.120 rows=180 loops=5687)"
"        Buffers: shared hit=1773, temp read=88795 written=553"
"Planning Time: 0.268 ms"
"Execution Time: 895.164 ms"

-- DROP INDEX
DROP INDEX project.idx_btree_timestamp