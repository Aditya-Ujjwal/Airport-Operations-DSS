/*======================================================================
Project : Airport Operations Decision Support System
File    : 05_Create_Relationships.sql
Author  : Aditya Ujjwal

Purpose:
Creates relationships between the clean tables by defining foreign key
constraints and indexes. This script establishes referential integrity
and optimizes join performance after the ETL process is completed.

NOTE:
- Execute only after successfully running 04_ETL_Load.sql.
- All parent and child tables must be populated before creating
  foreign key constraints.
======================================================================*/

USE Airport_Operations_DSS;

/*============================================================
Create Indexes
Optimizes JOIN, WHERE, GROUP BY and ORDER BY operations.
============================================================*/

-- ===========================================================
-- Flights
-- ===========================================================

CREATE INDEX idx_flights_flight_number
ON Flights(flight_number);

CREATE INDEX idx_flights_airline
ON Flights(airline_name);

CREATE INDEX idx_flights_route
ON Flights(departure_airport, arrival_airport);

CREATE INDEX idx_flights_departure
ON Flights(scheduled_departure);

CREATE INDEX idx_flights_status
ON Flights(flight_status);

-- ===========================================================
-- Passengers
-- ===========================================================

CREATE INDEX idx_passengers_flight
ON Passengers(flight_number);

CREATE INDEX idx_passengers_passport
ON Passengers(passport_number);

CREATE INDEX idx_passengers_nationality
ON Passengers(nationality);

CREATE INDEX idx_passengers_class
ON Passengers(travel_class);

CREATE INDEX idx_passengers_cabin
ON Passengers(cabin_class);

CREATE INDEX idx_passengers_agegroup
ON Passengers(age_group);

-- ===========================================================
-- Baggage
-- ===========================================================

CREATE INDEX idx_baggage_flight
ON Baggage(flight_number);

CREATE INDEX idx_baggage_passport
ON Baggage(passport_number);

CREATE INDEX idx_baggage_status
ON Baggage(baggage_status);

CREATE INDEX idx_baggage_gate
ON Baggage(destination_gate);

-- ===========================================================
-- Gate Events
-- ===========================================================

CREATE INDEX idx_gateevents_flight
ON Gate_Events(flight_number);

CREATE INDEX idx_gateevents_gate
ON Gate_Events(gate_number);

CREATE INDEX idx_gateevents_terminal
ON Gate_Events(terminal);

CREATE INDEX idx_gateevents_event
ON Gate_Events(event_type);

-- ===========================================================
-- Security Screening
-- ===========================================================

CREATE INDEX idx_security_passport
ON Security_Screening(passport_number);

CREATE INDEX idx_security_result
ON Security_Screening(screening_result);

CREATE INDEX idx_security_officer
ON Security_Screening(security_officer_id);

CREATE INDEX idx_security_shift
ON Security_Screening(security_shift);

-- ===========================================================
-- Staff Shifts
-- ===========================================================

CREATE INDEX idx_staff_department
ON Staff_Shifts(department);

CREATE INDEX idx_staff_terminal
ON Staff_Shifts(terminal);

CREATE INDEX idx_staff_gate
ON Staff_Shifts(gate_number);

CREATE INDEX idx_staff_supervisor
ON Staff_Shifts(supervisor_id);

-- ===========================================================
-- Maintenance Logs
-- ===========================================================

CREATE INDEX idx_maintenance_flight
ON Maintenance_Logs(flight_number);

CREATE INDEX idx_maintenance_aircraft
ON Maintenance_Logs(aircraft_registration);

CREATE INDEX idx_maintenance_type
ON Maintenance_Logs(maintenance_type);

CREATE INDEX idx_maintenance_technician
ON Maintenance_Logs(technician_id);

CREATE INDEX idx_maintenance_priority
ON Maintenance_Logs(priority_level);
