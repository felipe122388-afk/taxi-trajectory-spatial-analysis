---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------Query Task 1 Starts Here------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
-- Query 1: find the trajectory that is most similar to a given trajectory.
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;

-- Indexing Methods: 1) GiST (Generalized Search Tree) indexing
CREATE INDEX idx_polyline_geom ON project.taxi USING GIST (polyline_geom);

-- Test Case 1: find the nearest trajectory most similar to 1372636951620000320
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1395672234620000397 distance 0.004791804879165475
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47993.79..47993.79 rows=1 width=16) (actual time=556941.297..556941.300 rows=1 loops=1)"
"  Buffers: shared hit=120225 read=1387093"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.052..0.053 rows=1 loops=1)"
"          Index Cond: (trip_id = '1372636951620000320'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=47985.34..47989.64 rows=1719 width=16) (actual time=556941.295..556941.296 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=120225 read=1387093"
"        ->  Nested Loop  (cost=0.54..47976.75 rows=1719 width=16) (actual time=3.840..554539.645 rows=1254162 loops=1)"
"              Buffers: shared hit=120225 read=1387093"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.059..0.066 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.057..0.058 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.000..0.005 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_geom on taxi t  (cost=0.54..4999.98 rows=172 width=819) (actual time=3.699..385248.946 rows=1254162 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1372636951620000320'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 236665"
"                    Buffers: shared hit=116611 read=1387090"
"Planning Time: 0.313 ms"
"Execution Time: 556941.446 ms"

-- Test Case 2: find the nearest trajectory most similar to 1396006723620000546
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1379419343620000633 distance 0.0009720416657780442
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47764.72..47764.72 rows=1 width=16) (actual time=369328.603..369328.606 rows=1 loops=1)"
"  Buffers: shared hit=137374 read=1389031"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.096..0.099 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396006723620000546'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=47756.27..47760.55 rows=1711 width=16) (actual time=369328.599..369328.601 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=137374 read=1389031"
"        ->  Nested Loop  (cost=0.54..47747.72 rows=1711 width=16) (actual time=4.751..368389.582 rows=1110245 loops=1)"
"              Buffers: shared hit=137374 read=1389031"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.108..0.118 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.103..0.105 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.003..0.010 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_geom on taxi t  (cost=0.54..4970.96 rows=171 width=819) (actual time=4.604..207978.197 rows=1110245 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1396006723620000546'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 401314"
"                    Buffers: shared hit=134070 read=1389028"
"Planning Time: 0.501 ms"
"Execution Time: 369328.800 ms"

-- Test Case 3: find the nearest trajectory most similar to 1396008744620000199
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1392207015620000153 distance 7.739704403197165e-05
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47764.72..47764.72 rows=1 width=16) (actual time=46970.611..46970.613 rows=1 loops=1)"
"  Buffers: shared hit=69334 read=844905"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.060..0.063 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396008744620000199'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=47756.27..47760.55 rows=1711 width=16) (actual time=46970.609..46970.611 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=69334 read=844905"
"        ->  Nested Loop  (cost=0.54..47747.72 rows=1711 width=16) (actual time=5.535..46736.153 rows=632088 loops=1)"
"              Buffers: shared hit=69334 read=844905"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.065..0.071 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.064..0.064 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.000..0.005 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_geom on taxi t  (cost=0.54..4970.96 rows=171 width=819) (actual time=5.413..31767.974 rows=632088 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1396008744620000199'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 269104"
"                    Buffers: shared hit=67061 read=844902"
"Planning Time: 0.436 ms"
"Execution Time: 46970.791 ms"

-- Drop index idx_polyline_geom
DROP INDEX project.idx_polyline_geom;

-- Indexing Methods: 2) SP-GiST (Space-Partitioned GiST) indexing
CREATE INDEX idx_polyline_spgist ON project.taxi USING SPGIST (polyline_geom);

-- Test Case 1: find the nearest trajectory most similar to 1372636951620000320
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1395672234620000397 distance 0.004791804879165475
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47760.59..47760.60 rows=1 width=16) (actual time=239213.660..239213.662 rows=1 loops=1)"
"  Buffers: shared hit=140627 read=1462392"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.083..0.085 rows=1 loops=1)"
"          Index Cond: (trip_id = '1372636951620000320'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=47752.15..47756.42 rows=1711 width=16) (actual time=239213.657..239213.658 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=140627 read=1462392"
"        ->  Nested Loop  (cost=0.41..47743.59 rows=1711 width=16) (actual time=4.649..238575.769 rows=1254162 loops=1)"
"              Buffers: shared hit=140627 read=1462392"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.095..0.103 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.091..0.092 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.002..0.008 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_spgist on taxi t  (cost=0.41..4966.83 rows=171 width=819) (actual time=4.382..112586.230 rows=1254162 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1372636951620000320'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 236665"
"                    Buffers: shared hit=137013 read=1462389"
"Planning Time: 0.654 ms"
"Execution Time: 239213.851 ms"

-- Test Case 2: find the nearest trajectory most similar to 1396006723620000546
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1379419343620000633 distance 0.0009720416657780442
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47760.59..47760.60 rows=1 width=16) (actual time=311804.626..311804.629 rows=1 loops=1)"
"  Buffers: shared hit=142378 read=1482397"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.081..0.083 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396006723620000546'::bigint)"
"          Buffers: shared read=4"
"  ->  Sort  (cost=47752.15..47756.42 rows=1711 width=16) (actual time=311804.624..311804.625 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=142378 read=1482397"
"        ->  Nested Loop  (cost=0.41..47743.59 rows=1711 width=16) (actual time=5.001..311098.921 rows=1110245 loops=1)"
"              Buffers: shared hit=142378 read=1482397"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.090..0.097 rows=1 loops=1)"
"                    Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.086..0.087 rows=1 loops=1)"
"                          Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.001..0.006 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_spgist on taxi t  (cost=0.41..4966.83 rows=171 width=819) (actual time=4.767..162650.869 rows=1110245 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1396006723620000546'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 401314"
"                    Buffers: shared hit=139075 read=1482393"
"Planning Time: 0.398 ms"
"Execution Time: 311804.803 ms"

-- Test Case 3: find the nearest trajectory most similar to 1396008744620000199
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1392207015620000153 distance 7.739704403197165e-05
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=47760.59..47760.60 rows=1 width=16) (actual time=51882.903..51882.905 rows=1 loops=1)"
"  Buffers: shared hit=85443 read=888177"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.084..0.086 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396008744620000199'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=47752.15..47756.42 rows=1711 width=16) (actual time=51882.902..51882.902 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=85443 read=888177"
"        ->  Nested Loop  (cost=0.41..47743.59 rows=1711 width=16) (actual time=1.074..51643.044 rows=632088 loops=1)"
"              Buffers: shared hit=85443 read=888177"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.090..0.094 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.087..0.088 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.001..0.004 rows=1 loops=1)"
"              ->  Index Scan using idx_polyline_spgist on taxi t  (cost=0.41..4966.83 rows=171 width=819) (actual time=0.881..36942.287 rows=632088 loops=1)"
"                    Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                    Filter: ((trip_id <> '1396008744620000199'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 269104"
"                    Buffers: shared hit=83170 read=888174"
"Planning Time: 0.506 ms"
"Execution Time: 51883.052 ms"

-- Drop Index
DROP INDEX project.idx_polyline_spgist;

-- Indexing Methods: 3) BRIN (Block Range Index) indexing
CREATE INDEX idx_polyline_brin ON project.taxi USING BRIN (polyline_geom);

-- Test Case 1: find the nearest trajectory most similar to 1372636951620000320
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1395672234620000397 distance 0.004791804879165475
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1372636951620000320
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1372636951620000320
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=1690710.16..1690710.16 rows=1 width=16) (actual time=199417.256..199417.259 rows=1 loops=1)"
"  Buffers: shared hit=5861 read=529583 dirtied=1 written=2"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.662..0.665 rows=1 loops=1)"
"          Index Cond: (trip_id = '1372636951620000320'::bigint)"
"          Buffers: shared hit=1 read=3"
"  ->  Sort  (cost=1690701.72..1690705.99 rows=1711 width=16) (actual time=199417.254..199417.255 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=5861 read=529583 dirtied=1 written=2"
"        ->  Nested Loop  (cost=91.72..1690693.16 rows=1711 width=16) (actual time=31.125..198924.896 rows=1254162 loops=1)"
"              Buffers: shared hit=5861 read=529583 dirtied=1 written=2"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.669..0.675 rows=1 loops=1)"
"                    Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.666..0.666 rows=1 loops=1)"
"                          Buffers: shared hit=1 read=3"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.001..0.006 rows=1 loops=1)"
"              ->  Bitmap Heap Scan on taxi t  (cost=91.72..1647916.40 rows=171 width=819) (actual time=30.391..80171.994 rows=1254162 loops=1)"
"                    Filter: ((trip_id <> '1372636951620000320'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 456403"
"                    Heap Blocks: lossy=341462"
"                    Buffers: shared hit=2247 read=529580 dirtied=1 written=2"
"                    ->  Bitmap Index Scan on idx_polyline_brin  (cost=0.00..91.68 rows=59116 width=0) (actual time=23.740..23.740 rows=5268560 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                          Buffers: shared hit=35 read=3 dirtied=1"
"Planning:"
"  Buffers: shared hit=22 read=6 dirtied=5"
"Planning Time: 4.480 ms"
"Execution Time: 199417.934 ms"

-- Test Case 2: find the nearest trajectory most similar to 1396006723620000546
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1379419343620000633 distance 0.0009720416657780442
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396006723620000546
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396006723620000546
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=1268070.90..1268070.90 rows=1 width=16) (actual time=240397.895..240397.901 rows=1 loops=1)"
"  Buffers: shared hit=7818 read=340366"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=820) (actual time=1.247..1.255 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396006723620000546'::bigint)"
"          Buffers: shared read=4"
"  ->  Sort  (cost=1268062.45..1268066.73 rows=1711 width=16) (actual time=240397.891..240397.895 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=7818 read=340366"
"        ->  Nested Loop  (cost=59.36..1268053.90 rows=1711 width=16) (actual time=27.838..239945.817 rows=1110245 loops=1)"
"              Buffers: shared hit=7815 read=340366"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=1.256..1.271 rows=1 loops=1)"
"                    Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=1.253..1.254 rows=1 loops=1)"
"                          Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.001..0.013 rows=1 loops=1)"
"              ->  Bitmap Heap Scan on taxi t  (cost=59.36..1225277.14 rows=171 width=828) (actual time=20.930..114413.846 rows=1110245 loops=1)"
"                    Filter: ((trip_id <> '1396006723620000546'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 600334"
"                    Heap Blocks: lossy=339750"
"                    Buffers: shared hit=4451 read=340362"
"                    ->  Bitmap Index Scan on idx_polyline_brin  (cost=0.00..59.32 rows=44096 width=0) (actual time=17.832..17.833 rows=3397500 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                          Buffers: shared hit=25"
"Planning:"
"  Buffers: shared hit=166 read=28"
"Planning Time: 28.850 ms"
"Execution Time: 240406.381 ms"

-- Test Case 3: find the nearest trajectory most similar to 1396008744620000199
-- Code:
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- result trip_id 1392207015620000153 distance 7.739704403197165e-05
-- Query Plan Review
EXPLAIN (ANALYZE ON, BUFFERS ON)
WITH ReferenceTrajectory AS (
    SELECT polyline_geom AS given_traj
    FROM project.taxi
    WHERE TRIP_ID = 1396008744620000199
),
FilteredTrajectories AS (
    SELECT TRIP_ID, polyline_geom
    FROM project.taxi t, ReferenceTrajectory r
    WHERE ST_DWithin(t.polyline_geom, r.given_traj, 0.01)
)
SELECT 
    t.TRIP_ID, 
    ST_HausdorffDistance(t.polyline_geom, r.given_traj) AS distance
FROM 
    FilteredTrajectories t,
    ReferenceTrajectory r
WHERE
    t.TRIP_ID != 1396008744620000199
ORDER BY 
    distance ASC
LIMIT 1;
-- Query Plan Result
"Limit  (cost=1690710.16..1690710.16 rows=1 width=16) (actual time=55245.997..55245.999 rows=1 loops=1)"
"  Buffers: shared hit=4414 read=529035"
"  CTE referencetrajectory"
"    ->  Index Scan using taxi_pkey on taxi  (cost=0.43..8.45 rows=1 width=811) (actual time=0.097..0.106 rows=1 loops=1)"
"          Index Cond: (trip_id = '1396008744620000199'::bigint)"
"          Buffers: shared read=4"
"  ->  Sort  (cost=1690701.72..1690705.99 rows=1711 width=16) (actual time=55245.996..55245.997 rows=1 loops=1)"
"        Sort Key: (st_hausdorffdistance(t.polyline_geom, r.given_traj))"
"        Sort Method: top-N heapsort  Memory: 25kB"
"        Buffers: shared hit=4414 read=529035"
"        ->  Nested Loop  (cost=91.72..1690693.16 rows=1711 width=16) (actual time=34.748..55003.692 rows=632088 loops=1)"
"              Buffers: shared hit=4414 read=529035"
"              ->  Nested Loop  (cost=0.00..0.05 rows=1 width=64) (actual time=0.102..0.114 rows=1 loops=1)"
"                    Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r  (cost=0.00..0.02 rows=1 width=32) (actual time=0.100..0.100 rows=1 loops=1)"
"                          Buffers: shared read=4"
"                    ->  CTE Scan on referencetrajectory r_1  (cost=0.00..0.02 rows=1 width=32) (actual time=0.001..0.011 rows=1 loops=1)"
"              ->  Bitmap Heap Scan on taxi t  (cost=91.72..1647916.40 rows=171 width=819) (actual time=34.599..39373.412 rows=632088 loops=1)"
"                    Filter: ((trip_id <> '1396008744620000199'::bigint) AND st_dwithin(polyline_geom, r_1.given_traj, '0.01'::double precision))"
"                    Rows Removed by Filter: 1078434"
"                    Heap Blocks: lossy=341420"
"                    Buffers: shared hit=2142 read=529031"
"                    ->  Bitmap Index Scan on idx_polyline_brin  (cost=0.00..91.68 rows=59116 width=0) (actual time=26.555..26.555 rows=5262160 loops=1)"
"                          Index Cond: (polyline_geom && st_expand(r_1.given_traj, '0.01'::double precision))"
"                          Buffers: shared hit=7 read=22"
"Planning:"
"  Buffers: shared hit=1"
"Planning Time: 0.403 ms"
"Execution Time: 55246.150 ms"

--Drop Index
DROP INDEX project.idx_polyline_brin;