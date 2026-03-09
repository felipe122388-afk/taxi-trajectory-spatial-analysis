# 📊 Query Performance & Execution Analysis

## Overview
To validate the efficiency and computational costs of our spatial-temporal queries, rigorous performance profiling was conducted on a dataset of over 1.7 million taxi trajectories. Every query was tested using three distinct inputs across three different indexing methodologies. 

Benchmarking was recorded using PostgreSQL's `EXPLAIN (ANALYZE ON, BUFFERS ON)` command to evaluate execution times, buffer hits, and query planner strategies.

---

## 1. Query Task 1: Trajectory Similarity (Hausdorff Distance)
**Objective:** Find the trajectory most similar to a given reference trajectory using `ST_HausdorffDistance` coupled with a bounding box filter (`ST_DWithin`).

| Test Case (Target TRIP_ID) | GiST Index (ms) | SP-GiST Index (ms) | BRIN Index (ms) |
| :--- | :--- | :--- | :--- |
| **Case 1** (`...000320`) | 556,941.44 | 239,213.85 | **199,417.93** |
| **Case 2** (`...000546`) | 369,328.80 | 311,804.80 | **240,406.38** |
| **Case 3** (`...000199`) | **46,970.79** | 51,883.05 | 55,246.15 |

**💡 Analytical Takeaway:**
While GiST is traditionally the go-to for spatial geometries, the **Block Range Index (BRIN)** significantly outperformed GiST and SP-GiST in Cases 1 and 2. This suggests that the physical storage of the trajectories on the disk has a natural correlation with the spatial bounding boxes for those specific trips, allowing BRIN to skip massive blocks of data efficiently. However, in Case 3, GiST provided the optimal execution path, highlighting how spatial data distribution heavily impacts index selection.

---

## 2. Query Task 2: Spatiotemporal K-Nearest Neighbors (k-NN)
**Objective:** Identify the top nearest neighbor data points to a reference trajectory for specific dates, simulating localized traffic pattern analysis.

| Test Case (Target Date) | GiST Index (ms) | SP-GiST Index (ms) | BRIN Index (ms) |
| :--- | :--- | :--- | :--- |
| **Case 1** (`2014-02-15`) | 63,998.46 | 120,330.47 | **25,423.32** |
| **Case 2** (`2014-02-13`) | 57,992.71 | 47,580.63 | **25,336.07** |
| **Case 3** (`2014-02-11`) | 79,766.59 | 58,197.27 | **23,896.86** |

**💡 Analytical Takeaway:**
BRIN dominated this query category, consistently slashing execution times by **50% to 70%** compared to GiST and SP-GiST. Because this query involves a strict date filter before the spatial K-NN calculation, BRIN's ability to summarize block ranges proved vastly superior for rapidly filtering the 1.7 million rows down to a specific day before engaging the heavier `ST_Distance` calculations. 

---

## 3. Query Task 3: Skyline Optimization (Multi-Objective)
**Objective:** Identify "Skyline" trips for a specific day—trips that optimize for both minimum travel time and maximum distance, meaning no other trip strictly dominates them in both metrics. This utilized a computationally heavy **Left Anti-Join**.

*Note: Because this query relied heavily on time-series filtering rather than pure spatial bounding, 1D indexes (Hash, BRIN, B-Tree) were benchmarked on the extracted epoch timestamps.*

| Test Case (Target Date) | Hash Index (ms) | BRIN Index (ms) | B-Tree Index (ms) |
| :--- | :--- | :--- | :--- |
| **Case 1** (`2014-02-10`) | **534.89** | 536.05 | 560.84 |
| **Case 2** (`2014-01-15`) | 367.22 | **349.59** | 353.65 |
| **Case 3** (`2014-03-01`) | 966.32 | **844.14** | 895.16 |

**💡 Analytical Takeaway:**
By properly indexing the temporal component of the dataset, the PostgreSQL query planner was able to execute complex Left Anti-Joins across millions of rows in **under 1 second**. Performance across Hash, BRIN, and B-Tree was highly competitive, though BRIN maintained a slight edge in memory and buffer efficiency during the Bitmap Heap Scans. This demonstrates the critical importance of pre-filtering high-dimensional data using lightweight 1D indexes before applying complex relational logic.