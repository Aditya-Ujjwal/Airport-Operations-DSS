USE Airport_Operations_DSS;

/*------------------------------------------------------------*
*Stored Procedure 6.5P.01*
*
*Return operational performance for a selected airline
*
*Usage:
*CALL sp_airline_performance('Singapore Airlines');
*------------------------------------------------------------*/

DROP PROCEDURE IF EXISTS sp_airline_performance;
DELIMITER $$
CREATE PROCEDURE sp_airline_performance(
    IN p_airline_name VARCHAR(100)
)
BEGIN
    SELECT
        airline_name,
        COUNT(*) AS total_flights,
        SUM(passengers_onboard) AS total_passengers,
        ROUND(
            AVG(passengers_onboard),
            2
        ) AS avg_passengers_per_flight,
        ROUND(
            AVG(occupancy_percentage),
            2
        ) AS avg_occupancy_percentage,
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) AS delayed_flights,
        ROUND(
            100.0 *
            SUM(
                CASE
                    WHEN departure_delay_minutes > 0
                    THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS delay_rate_percentage,
        ROUND(
            AVG(departure_delay_minutes),
            2
        ) AS avg_departure_delay_minutes,
        ROUND(
            AVG(operational_score),
            2
        ) AS avg_operational_score
    FROM Flights
    WHERE airline_name = p_airline_name
    GROUP BY airline_name;
END$$
DELIMITER ;
#Test
CALL sp_airline_performance('Air India');

/*------------------------------------------------------------*
*Stored Procedure 7P.02*
*
*Return operational performance for a selected flight number
*
*Usage:
*CALL sp_flight_performance('SQ-1356');
*------------------------------------------------------------*/

DROP PROCEDURE IF EXISTS sp_flight_performance;

DELIMITER $$
CREATE PROCEDURE sp_flight_performance(
    IN p_flight_number VARCHAR(10)
)
BEGIN
    SELECT
        flight_id,
        flight_number,
        airline_name,
        departure_airport,
        arrival_airport,
        scheduled_departure,
        actual_departure,
        passengers_onboard,
        aircraft_capacity,
        ROUND(
            occupancy_percentage,
            2
        ) AS occupancy_percentage,
        departure_delay_minutes,
        ROUND(
            operational_score,
            2
        ) AS operational_score,
        aircraft_model,
        aircraft_registration,
        terminal,
        gate,
        departure_shift
    FROM Flights
    WHERE flight_number = p_flight_number
    ORDER BY scheduled_departure;
END$$
DELIMITER ;
#Test
CALL sp_flight_performance('SQ-1356');

/*------------------------------------------------------------*
*View 7V.01*
*
*Executive Airport KPIs
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_executive_kpis AS

SELECT
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),
        2
    ) AS avg_passengers_per_flight,
    SUM(
        CASE
            WHEN departure_delay_minutes > 0
            THEN 1
            ELSE 0
        END
    ) AS delayed_flights,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS delay_rate_percentage,
    ROUND(
        AVG(departure_delay_minutes),
        2
    ) AS avg_departure_delay_minutes,
    ROUND(
        AVG(occupancy_percentage),
        2
    ) AS avg_occupancy_percentage,
    ROUND(
        AVG(operational_score),
        2
    ) AS avg_operational_score
FROM Flights;

/*------------------------------------------------------------*
*View 6.5V.02*
*
*Airline Performance
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_airline_performance AS

SELECT
    airline_name,
    COUNT(*) AS total_flights,
    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM Flights),
        2
    ) AS flight_share_percentage,

    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),
        2
    ) AS avg_passengers_per_flight,
    ROUND(
        AVG(occupancy_percentage),
        2
    ) AS avg_occupancy_percentage,
    SUM(
        CASE
            WHEN departure_delay_minutes > 0
            THEN 1
            ELSE 0
        END
    ) AS delayed_flights,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS delay_rate_percentage,
    ROUND(
        AVG(departure_delay_minutes),
        2
    ) AS avg_departure_delay_minutes,
    ROUND(
        AVG(operational_score),
        2
    ) AS avg_operational_score
FROM Flights
GROUP BY airline_name;

/*------------------------------------------------------------*
*View 6.5V.03*
*
*Departure Shift Workload
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_shift_workload AS

SELECT
    departure_shift,
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),
        2
    ) AS avg_passengers_per_flight,
    ROUND(
        AVG(occupancy_percentage),
        2
    ) AS avg_occupancy_percentage
FROM Flights
GROUP BY departure_shift;

/*------------------------------------------------------------*
*View 6.5V.04*
*
*Hourly Airport Workload
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_hourly_workload AS

SELECT
    HOUR(scheduled_departure) AS departure_hour,
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),
        2
    ) AS avg_passengers_per_flight,
    ROUND(
        AVG(occupancy_percentage),
        2
    ) AS avg_occupancy_percentage,
    ROUND(
        100.0 *
        SUM(passengers_onboard) /
        (SELECT SUM(passengers_onboard) FROM Flights),
        2
    ) AS passenger_traffic_share_percentage
FROM Flights
GROUP BY HOUR(scheduled_departure);

/*------------------------------------------------------------*
*View 6.5V.05*
*
*Route Performance
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_route_performance AS

SELECT
    departure_airport,
    arrival_airport,
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),
        2
    ) AS avg_passengers_per_flight,
    SUM(
        CASE
            WHEN departure_delay_minutes > 0
            THEN 1
            ELSE 0
        END
    ) AS delayed_flights,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS delay_rate_percentage,
    ROUND(
        AVG(departure_delay_minutes),
        2
    ) AS avg_departure_delay_minutes
FROM Flights
GROUP BY
    departure_airport,
    arrival_airport;
    
/*------------------------------------------------------------*
*View 6.5V.06*
*
*Baggage Workload by Airline
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_baggage_airline AS

SELECT
    f.airline_name,
    COUNT(DISTINCT f.flight_id)
        AS flights_with_baggage,
    COUNT(b.baggage_tag)
        AS total_baggage,
    ROUND(
        COUNT(b.baggage_tag) /
        COUNT(DISTINCT f.flight_id),
        2
    ) AS baggage_per_flight,
    ROUND(
        SUM(b.baggage_weight_kg),
        2
    ) AS total_baggage_weight_kg,
    ROUND(
        AVG(b.baggage_weight_kg),
        2
    ) AS avg_baggage_weight_kg
FROM Flights f
INNER JOIN Baggage b
    ON f.flight_number = b.flight_number
GROUP BY f.airline_name;

/*------------------------------------------------------------*
*View 6.5V.07*
*
*Aircraft Utilization and Recorded Maintenance
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_aircraft_maintenance AS

SELECT
    fo.aircraft_model,
    fo.total_flights,
    fo.total_passengers,
    ROUND(
        fo.avg_occupancy_percentage,
        2
    ) AS avg_occupancy_percentage,
    COALESCE(
        mw.maintenance_linked_flights,
        0
    ) AS maintenance_linked_flights,
    COALESCE(
        mw.maintenance_jobs,
        0
    ) AS maintenance_jobs,
    COALESCE(
        mw.total_maintenance_hours,
        0
    ) AS total_maintenance_hours,
    COALESCE(
        mw.avg_maintenance_duration_hours,
        0
    ) AS avg_maintenance_duration_hours
FROM
(
    SELECT
        aircraft_model,
        COUNT(*) AS total_flights,
        SUM(passengers_onboard) AS total_passengers,
        AVG(occupancy_percentage)
            AS avg_occupancy_percentage
    FROM Flights
    GROUP BY aircraft_model
) fo
LEFT JOIN
(
    SELECT
        v.aircraft_model,
        COUNT(DISTINCT m.flight_number)
            AS maintenance_linked_flights,
        COUNT(m.maintenance_log_id)
            AS maintenance_jobs,
        SUM(m.estimated_duration_hours)
            AS total_maintenance_hours,
        AVG(m.estimated_duration_hours)
            AS avg_maintenance_duration_hours
    FROM Maintenance_Logs m
    INNER JOIN
    (
        SELECT
            flight_number,
            MAX(aircraft_model) AS aircraft_model
        FROM Flights
        GROUP BY flight_number
        HAVING COUNT(DISTINCT aircraft_model) = 1
    ) v
        ON m.flight_number = v.flight_number
    GROUP BY v.aircraft_model
) mw
    ON fo.aircraft_model = mw.aircraft_model;
    
/*------------------------------------------------------------*
*View 6.5V.08*
*
*Maintenance Workload by Maintenance Type
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_maintenance_type AS

SELECT
    maintenance_type,
    COUNT(*) AS maintenance_jobs,
    ROUND(
        SUM(estimated_duration_hours),
        2
    ) AS total_maintenance_hours,
    ROUND(
        AVG(estimated_duration_hours),
        2
    ) AS avg_maintenance_duration_hours,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN maintenance_completed = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS completion_rate_percentage,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN inspection_passed = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS inspection_pass_rate_percentage
FROM Maintenance_Logs
GROUP BY maintenance_type;

/*------------------------------------------------------------*
*View 6.5V.09*
*
*Maintenance Workload by Severity
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_maintenance_severity AS

SELECT
    severity_level,
    COUNT(*) AS maintenance_jobs,
    ROUND(
        SUM(estimated_duration_hours),
        2
    ) AS total_maintenance_hours,
    ROUND(
        AVG(estimated_duration_hours),
        2
    ) AS avg_maintenance_duration_hours,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN maintenance_completed = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS completion_rate_percentage,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN inspection_passed = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS inspection_pass_rate_percentage
FROM Maintenance_Logs
GROUP BY severity_level;

/*------------------------------------------------------------*
*View 6.5V.10*
*
*Passenger Assistance Analysis
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_passenger_assistance AS

SELECT
    travel_class,
    age_group,
    COUNT(*) AS total_passengers,
    SUM(
        CASE
            WHEN special_assistance = 1
            THEN 1
            ELSE 0
        END
    ) AS special_assistance_passengers,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN special_assistance = 1
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS special_assistance_rate_percentage,
    ROUND(
        AVG(passenger_score),
        2
    ) AS avg_passenger_score
FROM Passengers
GROUP BY
    travel_class,
    age_group;
    
/*------------------------------------------------------------*
*View 6.5V.11*
*
*Recorded Security Screening Workload
*
*Note:
*This represents recorded screening activity only.
*Security screening coverage is partial across airport flights.
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_security_workload AS

SELECT
    security_level,
    COUNT(*) AS recorded_screenings,
    SUM(passengers_processed)
        AS recorded_passengers_processed,
    ROUND(
        AVG(screening_duration_minutes),
        2
    ) AS avg_screening_duration_minutes,
    ROUND(
        AVG(queue_capacity),
        2
    ) AS avg_queue_capacity,
    ROUND(
        AVG(scanner_capacity),
        2
    ) AS avg_scanner_capacity
FROM Security_Screening
GROUP BY security_level;

/*------------------------------------------------------------*
*View 7V.12*
*
*Airline Management Priority
*------------------------------------------------------------*/

CREATE OR REPLACE VIEW vw_bi_airline_priority AS

WITH Airline_Performance AS
(
    SELECT
        airline_name,
        COUNT(*) AS total_flights,
        SUM(passengers_onboard)
            AS total_passengers,
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS delay_rate,
        AVG(operational_score)
            AS avg_operational_score
    FROM Flights
    GROUP BY airline_name
),
Airline_Exposure AS
(
    SELECT
        airline_name,
        100.0 *
        SUM(
            CASE
                WHEN operational_score <
                     (
                         SELECT AVG(operational_score)
                         FROM Flights
                     )
                THEN passengers_onboard
                ELSE 0
            END
        ) / SUM(passengers_onboard)
        AS passenger_exposure_percentage
    FROM Flights
    GROUP BY airline_name
),
Benchmarks AS
(
    SELECT
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS airport_delay_rate,
        AVG(operational_score)
            AS airport_operational_score
    FROM Flights
),
Exposure_Benchmark AS
(
    SELECT
        AVG(passenger_exposure_percentage)
            AS avg_airline_exposure
    FROM Airline_Exposure
)
SELECT
    a.airline_name,
    a.total_flights,
    a.total_passengers,
    ROUND(a.delay_rate, 2)
        AS delay_rate,
    ROUND(e.passenger_exposure_percentage, 2)
        AS passenger_exposure_percentage,
    ROUND(a.avg_operational_score, 2)
        AS avg_operational_score,
    (
        CASE
            WHEN a.delay_rate > b.airport_delay_rate
            THEN 1 ELSE 0
        END
        +
        CASE
            WHEN e.passenger_exposure_percentage >
                 x.avg_airline_exposure
            THEN 1 ELSE 0
        END
        +
        CASE
            WHEN a.avg_operational_score <
                 b.airport_operational_score
            THEN 1 ELSE 0
        END
    ) AS priority_score
FROM Airline_Performance a
INNER JOIN Airline_Exposure e
    ON a.airline_name = e.airline_name
CROSS JOIN Benchmarks b
CROSS JOIN Exposure_Benchmark x;
