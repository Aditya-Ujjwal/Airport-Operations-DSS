/*======================================================================
Project : Airport Operations Decision Support System
File    : 04_ETL_Load.sql
Author  : Aditya Ujjwal

Purpose:
Extracts data from the Raw_* staging tables, applies basic data
transformations and standardization, and loads the processed data into
the cleaned production tables. The script also performs load verification
to ensure successful ETL execution.

NOTE:
- Raw tables are treated as staging tables and remain unchanged.
- Basic transformations include TRIM(), NULLIF(), CAST(),
  STR_TO_DATE(), UPPER()/LOWER(), and CASE statements.
======================================================================*/

USE Airport_Operations_DSS;

START TRANSACTION;

-- ============================================================================
-- ETL : Flights
-- ============================================================================
TRUNCATE TABLE Flights;

-- Load transformed flight data (validated mapping)
-- Replace raw column references if your import headers differ.
INSERT INTO Flights
(
flight_number,airline_name,airline_code,departure_airport,arrival_airport,
scheduled_departure,actual_departure,scheduled_arrival,actual_arrival,
aircraft_model,aircraft_registration,aircraft_capacity,passengers_onboard,
flight_status,departure_delay_minutes,delay_reason,terminal,gate,
international_flight,flight_distance_km,fuel_consumption_liters,
boarding_start_time,boarding_completed,operational_score,
occupancy_percentage,load_factor,departure_shift,day_of_week,
holiday_flag,season,route_type
)
SELECT
TRIM(`0`),TRIM(`1`),UPPER(TRIM(`2`)),UPPER(TRIM(`3`)),UPPER(TRIM(`4`)),
STR_TO_DATE(`5`,'%Y-%m-%d %H:%i:%s'),
STR_TO_DATE(`6`,'%Y-%m-%d %H:%i:%s'),
STR_TO_DATE(`7`,'%Y-%m-%d %H:%i:%s'),
STR_TO_DATE(`8`,'%Y-%m-%d %H:%i:%s'),
TRIM(`9`),TRIM(`10`),
CAST(`11` AS UNSIGNED),
CAST(`12` AS UNSIGNED),
TRIM(`13`),
CAST(`14` AS SIGNED),
NULLIF(TRIM(`15`),''),
UPPER(TRIM(`16`)),
UPPER(TRIM(`17`)),
CASE WHEN UPPER(TRIM(`18`)) IN ('TRUE','YES','1') THEN TRUE ELSE FALSE END,
CAST(`19` AS UNSIGNED),
CAST(`20` AS DECIMAL(10,2)),
STR_TO_DATE(`21`,'%Y-%m-%d %H:%i:%s'),
CASE WHEN UPPER(TRIM(`22`)) IN ('TRUE','YES','1') THEN TRUE ELSE FALSE END,
CAST(`24` AS DECIMAL(10,4)),
CAST(`25` AS DECIMAL(5,2)),
CAST(`26` AS DECIMAL(6,4)),
TRIM(`27`),
TRIM(`28`),
CASE WHEN UPPER(TRIM(`29`)) IN ('TRUE','YES','1') THEN TRUE ELSE FALSE END,
TRIM(`30`),
TRIM(`31`)
FROM Raw_Flights;

SELECT 'Flights' AS Table_Name, COUNT(*) AS Records_Loaded, NOW() AS Load_Time FROM Flights;

/*============================================================
ETL : Passengers
============================================================*/

-- Load Passenger Data

TRUNCATE TABLE Passengers;

INSERT INTO Passengers
(
    passenger_id,
    booking_reference,
    passport_number,
    first_name,
    last_name,
    nationality,
    date_of_birth,
    gender,
    seat_number,
    travel_class,
    flight_number,
    checkin_time,
    boarding_time,
    boarding_gate,
    baggage_count,
    email,
    phone_number,
    special_assistance,
    passenger_score,
    cabin_class,
    age,
    age_group
)

SELECT
TRIM(`0`),
CAST(`1` AS UNSIGNED),
TRIM(`2`),
TRIM(`3`),
TRIM(`4`),
TRIM(`5`),
NULLIF(TRIM(`6`), ''),
UPPER(TRIM(`7`)),
UPPER(TRIM(`8`)),
TRIM(`9`),
TRIM(`10`),
NULLIF(TRIM(`11`), ''),
NULLIF(TRIM(`12`), ''),
UPPER(TRIM(`13`)),
CAST(`14` AS UNSIGNED),
LOWER(NULLIF(TRIM(`18`), '')),
NULLIF(TRIM(`19`), ''),
CASE
	WHEN UPPER(TRIM(`22`)) IN ('TRUE','YES','1')
	THEN TRUE
	ELSE FALSE
END,
CAST(`23` AS DECIMAL(10,6)),
TRIM(`25`),
CASE
    WHEN CAST(`26` AS SIGNED) >= 0
    THEN CAST(`26` AS UNSIGNED)
    ELSE NULL
END,
TRIM(`27`)
FROM Raw_Passengers;

SELECT
COUNT(*) AS Passengers_Loaded
FROM Passengers;

/*============================================================
ETL : Baggage
============================================================*/
select * from baggage;
TRUNCATE TABLE Baggage;

INSERT INTO Baggage
(
    baggage_tag,
	baggage_reference,
	flight_number,
	passport_number,
	baggage_weight_kg,
	baggage_dimensions,
	checkin_location,
	destination_gate,
	checkin_time,
	loading_time,
	baggage_priority,
	baggage_status,
	fragile_flag,
	security_flag,
	storage_location,
	last_scan_time,
	mishandled_flag
)
SELECT
TRIM(`0`),
TRIM(`1`),
UPPER(TRIM(`2`)),
TRIM(`3`),
CAST(`4` AS DECIMAL(6,2)),
TRIM(`5`),
TRIM(`6`),
UPPER(TRIM(`7`)),
NULLIF(TRIM(`8`),''),
NULLIF(TRIM(`9`),''),
CAST(`10` AS UNSIGNED),
TRIM(`11`),
CASE WHEN UPPER(TRIM(`12`))='TRUE' THEN TRUE ELSE FALSE END,
CAST(`13` AS UNSIGNED),
TRIM(`14`),
NULLIF(TRIM(`15`),''),
CASE WHEN UPPER(TRIM(`16`))='TRUE' THEN TRUE ELSE FALSE END
FROM Raw_Baggage;

SELECT
COUNT(*) AS Baggage_Loaded
FROM Baggage;

/*============================================================
ETL : Gate_Events
============================================================*/

TRUNCATE TABLE Gate_Events;

INSERT INTO Gate_Events
(
    gate_event_id,
    flight_number,
    gate_number,
    terminal,
    event_type,
    scheduled_event_time,
    staff_id,
    passengers_processed,
    event_category,
    delay_flag,
    actual_event_time,
    gate_open_time,
    gate_close_time
)

SELECT
TRIM(`0`),
UPPER(TRIM(`1`)),
UPPER(TRIM(`2`)),
UPPER(TRIM(`3`)),
TRIM(`4`),
NULLIF(TRIM(`5`), ''),
TRIM(`6`),
CAST(`7` AS UNSIGNED),
TRIM(`8`),
CASE
    WHEN UPPER(TRIM(`9`)) IN ('TRUE','YES','1')
        THEN TRUE
    ELSE FALSE
END,
NULLIF(TRIM(`11`), ''),
NULLIF(TRIM(`12`), ''),
NULLIF(TRIM(`13`), '')
FROM Raw_Gate_Events;

SELECT
COUNT(*) AS Gate_Events_Loaded
FROM Gate_Events;

/*============================================================
ETL : Security_Screening
============================================================*/

TRUNCATE TABLE Security_Screening;

INSERT INTO Security_Screening
(
    screening_id,
    passport_number,
    screening_reference,
    security_level,
    arrival_time,
    screening_start_time,
    screening_end_time,
    screening_result,
    alarm_triggered,
    security_officer_id,
    scanner_type,
    screening_duration_minutes,
    prohibited_item_found,
    secondary_screening_required,
    security_shift,
    scanner_capacity,
    passengers_processed,
    queue_capacity,
    vip_passenger
)

SELECT
TRIM(`0`),
TRIM(`1`),
TRIM(`2`),
CAST(`3` AS UNSIGNED),
NULLIF(TRIM(`4`),''),
NULLIF(TRIM(`5`),''),
NULLIF(TRIM(`6`),''),
TRIM(`7`),
CASE
    WHEN UPPER(TRIM(`9`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END,
TRIM(`10`),
UPPER(TRIM(`11`)),
CAST(`12` AS UNSIGNED),
CASE
    WHEN UPPER(TRIM(`13`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END,
CASE
    WHEN UPPER(TRIM(`14`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END,
UPPER(TRIM(`15`)),
CAST(`16` AS UNSIGNED),
CAST(`17` AS UNSIGNED),
CAST(`18` AS UNSIGNED),
CASE
    WHEN UPPER(TRIM(`19`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END
FROM Raw_Security_Screening;

SELECT
COUNT(*) AS Security_Records_Loaded
FROM Security_Screening;

/*============================================================
ETL : Staff_Shifts
============================================================*/

TRUNCATE TABLE Staff_Shifts;

INSERT INTO Staff_Shifts
(
    staff_id,
    staff_name,
    department,
    job_role,
    joining_date,
    shift_start,
    shift_end,
    terminal,
    gate_number,
    supervisor_id,
    shift_hours,
    overtime_flag,
    last_training_date,
    preferred_language
)

SELECT
TRIM(`0`),
TRIM(`1`),
UPPER(TRIM(`2`)),
TRIM(`3`),
NULLIF(TRIM(`4`),''),
NULLIF(TRIM(`5`),''),
NULLIF(TRIM(`6`),''),
UPPER(TRIM(`7`)),
UPPER(TRIM(`8`)),
TRIM(`9`),
CAST(`10` AS UNSIGNED),
CASE
    WHEN UPPER(TRIM(`11`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END,
NULLIF(TRIM(`13`),''),
TRIM(`14`)
FROM Raw_Staff_Shifts;

SELECT
COUNT(*) AS Staff_Records_Loaded
FROM Staff_Shifts;

/*============================================================
ETL : Maintenance_Logs
============================================================*/

TRUNCATE TABLE Maintenance_Logs;

INSERT INTO Maintenance_Logs
(
    work_order_id,
    aircraft_registration,
    flight_number,
    maintenance_type,
    technician_id,
    maintenance_start,
    maintenance_end,
    priority_level,
    estimated_duration_hours,
    issue_description,
    replaced_component,
    severity_level,
    supervisor_id,
    maintenance_completed,
    inspection_passed
)

SELECT
TRIM(`0`),
UPPER(TRIM(`1`)),
UPPER(TRIM(`2`)),
TRIM(`3`),
TRIM(`4`),
NULLIF(TRIM(`5`),''),
NULLIF(TRIM(`6`),''),
CAST(`7` AS UNSIGNED),
CAST(`8` AS UNSIGNED),
TRIM(`9`),
TRIM(`10`),
CAST(`11` AS UNSIGNED),
TRIM(`12`),
CASE
    WHEN UPPER(TRIM(`13`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END,
CASE
    WHEN UPPER(TRIM(`14`)) IN ('TRUE','YES','1')
    THEN TRUE
    ELSE FALSE
END
FROM Raw_Maintenance_Logs;

SELECT
COUNT(*) AS Maintenance_Records_Loaded
FROM Maintenance_Logs;
