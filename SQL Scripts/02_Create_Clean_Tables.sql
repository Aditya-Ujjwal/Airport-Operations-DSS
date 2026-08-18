/*=========================================================================
Project : Airport Operations Decision Support System
File    : 02_Create_Clean_Tables.sql
Author  : Aditya Ujjwal

Purpose:
Creates the cleaned operational tables used by the Airport Operations
Decision Support System. These tables are populated from the Raw_ staging
tables during the ETL process.

===========================================================================*/

USE Airport_Operations_DSS;

-- ============================================================
-- FLIGHTS
-- ============================================================

DROP TABLE IF EXISTS Flights;

CREATE TABLE Flights
(
    flight_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    airline_name VARCHAR(100) NOT NULL,
    airline_code CHAR(2) NOT NULL,
    departure_airport CHAR(3) NOT NULL,
    arrival_airport CHAR(3) NOT NULL,
    scheduled_departure DATETIME NOT NULL,
    actual_departure DATETIME,
    scheduled_arrival DATETIME NOT NULL,
    actual_arrival DATETIME,
    aircraft_model VARCHAR(30),
    aircraft_registration VARCHAR(15),
    aircraft_capacity SMALLINT,
    passengers_onboard SMALLINT,
    flight_status VARCHAR(30),
    departure_delay_minutes SMALLINT,
    delay_reason VARCHAR(100),
    terminal VARCHAR(10),
    gate VARCHAR(10),
    international_flight BOOLEAN,
    flight_distance_km INT,
    fuel_consumption_liters DECIMAL(10,2),
    boarding_start_time DATETIME,
    boarding_completed BOOLEAN,
    operational_score DECIMAL(10,4),
    occupancy_percentage DECIMAL(5,2),
    load_factor DECIMAL(6,4),
    departure_shift VARCHAR(20),
    day_of_week VARCHAR(10),
    holiday_flag BOOLEAN,
    season VARCHAR(20),
    route_type VARCHAR(30),
    INDEX idx_flight_number (flight_number)
);

-- ============================================================
-- PASSENGERS
-- ============================================================

DROP TABLE IF EXISTS Passengers;

CREATE TABLE Passengers
(
    passenger_id VARCHAR(10) PRIMARY KEY,
    booking_reference BIGINT NOT NULL,
    passport_number VARCHAR(20),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    nationality VARCHAR(50),
    date_of_birth DATE,
    gender CHAR(1),
    seat_number VARCHAR(5),
    travel_class VARCHAR(20),
    flight_number VARCHAR(10),
    checkin_time DATETIME,
    boarding_time DATETIME,
    boarding_gate VARCHAR(5),
    baggage_count TINYINT,
    email VARCHAR(100),
    phone_number VARCHAR(20),
    special_assistance BOOLEAN,
    passenger_score DECIMAL(10,6),
    INDEX idx_passport (passport_number),
    INDEX idx_passenger_flight (flight_number),
    cabin_class VARCHAR(20),
	age INT,
	age_group VARCHAR(20)
);

-- ============================================================
-- BAGGAGE
-- ============================================================

DROP TABLE IF EXISTS Baggage;

CREATE TABLE Baggage
(
    baggage_tag          VARCHAR(20) PRIMARY KEY,
	baggage_reference    VARCHAR(10),
	flight_number        VARCHAR(10),
	passport_number      VARCHAR(20),
	baggage_weight_kg    DECIMAL(6,2),
	baggage_dimensions   VARCHAR(20),
	checkin_location     VARCHAR(30),
	destination_gate     VARCHAR(10),
	checkin_time         DATETIME,
	loading_time         DATETIME,
	baggage_priority     INT,
	baggage_status       VARCHAR(20),
	fragile_flag         BOOLEAN,
	security_flag        INT,
	storage_location     VARCHAR(30),
	last_scan_time       DATETIME,
	mishandled_flag      BOOLEAN
);

-- ============================================================
-- GATE EVENTS
-- ============================================================

DROP TABLE IF EXISTS Gate_Events;

CREATE TABLE Gate_Events
(
    gate_event_id           VARCHAR(20) PRIMARY KEY,
    flight_number           VARCHAR(10) NOT NULL,
    gate_number             VARCHAR(10),
    terminal                VARCHAR(10),
    event_type              VARCHAR(50),
    scheduled_event_time    DATETIME,
    staff_id                VARCHAR(20),
    passengers_processed    INT,
    event_category          VARCHAR(30),
    delay_flag              BOOLEAN,
    actual_event_time       DATETIME,
    gate_open_time          DATETIME,
    gate_close_time         DATETIME
);
-- ============================================================
-- SECURITY SCREENING
-- ============================================================

DROP TABLE IF EXISTS Security_Screening;

CREATE TABLE Security_Screening
(
    screening_id                    VARCHAR(20) PRIMARY KEY,
    passport_number                 VARCHAR(20) NOT NULL,
    screening_reference             VARCHAR(10),
    security_level                  INT,
    arrival_time                    DATETIME,
    screening_start_time            DATETIME,
    screening_end_time              DATETIME,
    screening_result                VARCHAR(20),
    alarm_triggered                 BOOLEAN,
    security_officer_id             VARCHAR(20),
    scanner_type                    VARCHAR(20),
    screening_duration_minutes      INT,
    prohibited_item_found           BOOLEAN,
    secondary_screening_required    BOOLEAN,
    security_shift                  VARCHAR(20),
    scanner_capacity                INT,
    passengers_processed            INT,
    queue_capacity                  INT,
    vip_passenger                   BOOLEAN
);

-- ============================================================
-- STAFF SHIFTS
-- ============================================================

DROP TABLE IF EXISTS Staff_Shifts;

CREATE TABLE Staff_Shifts
(
    staff_id                VARCHAR(20) PRIMARY KEY,
    staff_name              VARCHAR(100) NOT NULL,
    department              VARCHAR(30),
    job_role                VARCHAR(50),
    joining_date            DATE,
    shift_start             DATETIME,
    shift_end               DATETIME,
    terminal                VARCHAR(10),
    gate_number             VARCHAR(10),
    supervisor_id           VARCHAR(20),
    shift_hours             INT,
    overtime_flag           BOOLEAN,
    last_training_date      DATE,
    preferred_language      VARCHAR(30)
);

-- ============================================================
-- MAINTENANCE LOGS
-- ============================================================

DROP TABLE IF EXISTS Maintenance_Logs;

CREATE TABLE Maintenance_Logs
(
    maintenance_log_id INT AUTO_INCREMENT PRIMARY KEY,
    work_order_id VARCHAR(20),
    aircraft_registration VARCHAR(20),
    flight_number VARCHAR(10),
    maintenance_type VARCHAR(30),
    technician_id VARCHAR(20),
    maintenance_start DATETIME,
    maintenance_end DATETIME,
    priority_level INT,
    estimated_duration_hours INT,
    issue_description VARCHAR(100),
    replaced_component VARCHAR(50),
    severity_level INT,
    supervisor_id VARCHAR(20),
    maintenance_completed BOOLEAN,
    inspection_passed BOOLEAN
);
