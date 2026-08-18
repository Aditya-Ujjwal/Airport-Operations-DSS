/*======================================================================
Project : Airport Operations Decision Support System
File    : 03_Data_Profiling.sql
Author  : Aditya Ujjwal

Purpose:
Profiles all raw datasets before ETL. This script performs database
overview, row counts, sample inspection, duplicate checks, NULL analysis,
domain validation, numeric summaries, date validation and relationship
validation.

NOTE:
- Raw tables use anonymous column names (`0`,`1`,`2`,...).
- Update column references if your imported tables differ.
======================================================================*/

USE Airport_Operations_DSS;

-- ==========================================================
-- 1. DATABASE OVERVIEW
-- ==========================================================

SHOW TABLES;

-- ==========================================================
-- 2. ROW COUNTS
-- ==========================================================

SELECT 'Raw_Flights' AS Table_Name, COUNT(*) AS Total_Records FROM Raw_Flights
UNION ALL
SELECT 'Raw_Passengers', COUNT(*) FROM Raw_Passengers
UNION ALL
SELECT 'Raw_Baggage', COUNT(*) FROM Raw_Baggage
UNION ALL
SELECT 'Raw_Gate_Events', COUNT(*) FROM Raw_Gate_Events
UNION ALL
SELECT 'Raw_Security_Screening', COUNT(*) FROM Raw_Security_Screening
UNION ALL
SELECT 'Raw_Staff_Shifts', COUNT(*) FROM Raw_Staff_Shifts
UNION ALL
SELECT 'Raw_Maintenance_Logs', COUNT(*) FROM Raw_Maintenance_Logs

-- ==========================================================
-- 3. SAMPLE DATA
-- ==========================================================

SELECT * FROM Raw_Flights LIMIT 5;
SELECT * FROM Raw_Passengers LIMIT 5;
SELECT * FROM Raw_Baggage LIMIT 5;
SELECT * FROM Raw_Gate_Events LIMIT 5;
SELECT * FROM Raw_Security_Screening LIMIT 5;
SELECT * FROM Raw_Staff_Shifts LIMIT 5;
SELECT * FROM Raw_Maintenance_Logs LIMIT 5;

-- ==========================================================
-- 4. DUPLICATE CHECKS
-- ==========================================================

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Flights
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Passengers
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Baggage
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Gate_Events
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Security_Screening
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Staff_Shifts
GROUP BY `0`
HAVING COUNT(*)>1;

SELECT `0`,COUNT(*) Duplicate_Count
FROM Raw_Maintenance_Logs
GROUP BY `0`
HAVING COUNT(*)>1;

-- ==========================================================
-- 5. NULL ANALYSIS (examples)
-- ==========================================================

SELECT
SUM(`0` IS NULL) AS Col0_Nulls,
SUM(`1` IS NULL) AS Col1_Nulls,
SUM(`5` IS NULL) AS Col5_Nulls,
SUM(`6` IS NULL) AS Col6_Nulls,
SUM(`13` IS NULL) AS Col13_Nulls
FROM Raw_Flights;

SELECT
SUM(`0` IS NULL) AS Col0_Nulls,
SUM(`10` IS NULL) AS Flight_Nulls,
SUM(`17` IS NULL) AS Email_Nulls,
SUM(`18` IS NULL) AS Phone_Nulls
FROM Raw_Passengers;

SELECT
SUM(`0` IS NULL) AS Col0_Nulls,
SUM(`4` IS NULL) AS Passport_Nulls,
SUM(`12` IS NULL) AS Status_Nulls
FROM Raw_Baggage;

-- ==========================================================
-- 6. DOMAIN VALIDATION
-- ==========================================================

SELECT DISTINCT `13` AS Flight_Status FROM Raw_Flights;
SELECT DISTINCT `15` AS Delay_Reason FROM Raw_Flights;
SELECT DISTINCT `23` AS Weather FROM Raw_Flights;
SELECT DISTINCT `30` AS Season FROM Raw_Flights;

SELECT DISTINCT `9` AS Travel_Class FROM Raw_Passengers;
SELECT DISTINCT `7` AS Screening_Result FROM Raw_Security_Screening;
SELECT DISTINCT `2` AS Department FROM Raw_Staff_Shifts;
SELECT DISTINCT `3` AS Maintenance_Type FROM Raw_Maintenance_Logs;

-- ==========================================================
-- 7. NUMERIC STATISTICS
-- ==========================================================

SELECT
MIN(`11`) Min_Capacity,
MAX(`11`) Max_Capacity,
AVG(`11`) Avg_Capacity,
MIN(`14`) Min_Delay,
MAX(`14`) Max_Delay,
AVG(`14`) Avg_Delay
FROM Raw_Flights;

SELECT
MIN(`5`) Min_Baggage_Weight,
MAX(`5`) Max_Baggage_Weight,
AVG(`5`) Avg_Baggage_Weight
FROM Raw_Baggage;

-- ==========================================================
-- 8. DATE VALIDATION
-- ==========================================================

SELECT MIN(`5`) First_Departure,
MAX(`5`) Last_Departure
FROM Raw_Flights;

SELECT MIN(`11`) First_Checkin,
MAX(`11`) Last_Checkin
FROM Raw_Passengers;

-- ==========================================================
-- 9. RELATIONSHIP VALIDATION
-- ==========================================================

-- Passenger flight numbers missing in Flights
SELECT DISTINCT p.`10`
FROM Raw_Passengers p
LEFT JOIN Raw_Flights f
ON p.`10`=f.`0`
WHERE f.`0` IS NULL;

-- Baggage passport missing in Passengers
SELECT DISTINCT b.`4`
FROM Raw_Baggage b
LEFT JOIN Raw_Passengers p
ON b.`4`=p.`2`
WHERE p.`2` IS NULL;

-- Retail flight missing in Flights
SELECT DISTINCT r.`5`
FROM Raw_Retail_Transactions r
LEFT JOIN Raw_Flights f
ON r.`5`=f.`0`
WHERE f.`0` IS NULL;

-- ==========================================================
-- 10. DATA QUALITY SUMMARY
-- ==========================================================

/*
After executing this script, document:
1. Duplicate records
2. Missing values
3. Invalid categories
4. Missing relationships
5. Date inconsistencies
6. Recommended ETL actions
*/
