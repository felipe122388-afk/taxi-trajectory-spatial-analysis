# 🚕 High-Dimensional Spatial-Temporal Data Analysis: Taxi Trajectories

**Tech Stack:** PostgreSQL, PostGIS, Python (Pandas), SQL

## 📌 Project Overview
This project tackles the challenge of optimizing database queries for massive spatial-temporal datasets. Using a high-dimensional dataset of over 1.7 million taxi trajectories, this repository demonstrates advanced spatial data manipulation, custom PostGIS geometry creation, and rigorous database performance tuning. The raw data was preprocessed in Python to ensure entity integrity before being converted into PostGIS geometries for advanced spatial analysis.

## 🏗️ Architecture & Query Optimization
To evaluate execution strategies and computational costs, three complex real-world query scenarios were conceptualized and tested across varying indexing algorithms:

### 1. Trajectory Similarity (Hausdorff Distance)
* **Concept:** Finding the route most similar to a given reference trajectory using `ST_HausdorffDistance` coupled with spatial bounding box filtering (`ST_DWithin`).
* **Indexes Evaluated:** GiST, SP-GiST, BRIN

### 2. Spatiotemporal K-Nearest Neighbors (k-NN)
* **Concept:** Retrieving the top $K$ closest trajectory points to a reference route on specific dates to simulate localized traffic pattern analysis.
* **Indexes Evaluated:** GiST, SP-GiST, BRIN

### 3. Skyline Queries (Multi-Objective Optimization)
* **Concept:** Identifying "Skyline" data points for specific days—finding trips that optimize for both minimum travel time and maximum distance simultaneously (i.e., identifying trips where no other trip strictly dominates them). This was implemented using complex Left Anti-Joins.
* **Indexes Evaluated:** Hash, BRIN, B-Tree (on extracted epoch timestamps)

## 📈 Performance Profiling
Query performance was rigorously profiled using `EXPLAIN (ANALYZE ON, BUFFERS ON)` to analyze query operations, buffer hits, and execution costs. 

**Key Finding:** While GiST and SP-GiST indexes performed exceptionally well for localized spatial bounding, the **Block Range Index (BRIN)** consistently slashed execution times by up to 70% when queries involved strict time-series filtering prior to spatial calculations. Additionally, utilizing lightweight 1D indexes (Hash/B-Tree) on temporal components allowed the query planner to execute complex Left Anti-Joins across millions of rows in under 1 second.

*(Full execution plans, benchmark data, and buffer hit analyses can be found in the `/results` directory).*
