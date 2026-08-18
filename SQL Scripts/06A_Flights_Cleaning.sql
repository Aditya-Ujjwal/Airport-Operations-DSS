USE Airport_Operations_DSS;

/*------------------------------------------------------------*
Audit 6A.1
Check NULL values in Flights
*------------------------------------------------------------*/

SELECT
    SUM(flight_id IS NULL) AS null_flight_id,
    SUM(flight_number IS NULL) AS null_flight_number,
    SUM(airline_name IS NULL) AS null_airline_name,
    SUM(airline_code IS NULL) AS null_airline_code,
    SUM(departure_airport IS NULL) AS null_departure_airport,
    SUM(arrival_airport IS NULL) AS null_arrival_airport,
    SUM(scheduled_departure IS NULL) AS null_scheduled_departure,
    SUM(actual_departure IS NULL) AS null_actual_departure,
    SUM(scheduled_arrival IS NULL) AS null_scheduled_arrival,
    SUM(actual_arrival IS NULL) AS null_actual_arrival,
    SUM(aircraft_model IS NULL) AS null_aircraft_model,
    SUM(aircraft_registration IS NULL) AS null_aircraft_registration,
    SUM(aircraft_capacity IS NULL) AS null_aircraft_capacity,
    SUM(passengers_onboard IS NULL) AS null_passengers_onboard,
    SUM(flight_status IS NULL) AS null_flight_status,
    SUM(departure_delay_minutes IS NULL) AS null_departure_delay,
    SUM(delay_reason IS NULL) AS null_delay_reason,
    SUM(terminal IS NULL) AS null_terminal,
    SUM(gate IS NULL) AS null_gate,
    SUM(international_flight IS NULL) AS null_international_flight,
    SUM(flight_distance_km IS NULL) AS null_flight_distance,
    SUM(fuel_consumption_liters IS NULL) AS null_fuel_consumption,
    SUM(boarding_start_time IS NULL) AS null_boarding_start,
    SUM(boarding_completed IS NULL) AS null_boarding_completed,
    SUM(operational_score IS NULL) AS null_operational_score,
    SUM(occupancy_percentage IS NULL) AS null_occupancy_percentage,
    SUM(load_factor IS NULL) AS null_load_factor,
    SUM(departure_shift IS NULL) AS null_departure_shift,
    SUM(day_of_week IS NULL) AS null_day_of_week,
    SUM(holiday_flag IS NULL) AS null_holiday_flag,
    SUM(season IS NULL) AS null_season,
    SUM(route_type IS NULL) AS null_route_type
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.2
Check duplicate flight_id values in Flights
*------------------------------------------------------------*/

SELECT
    flight_id,
    COUNT(*) AS occurrence_count
FROM Flights
GROUP BY flight_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------*
Audit 6A.3
Compare total rows with unique flight_id values
*------------------------------------------------------------*/

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT flight_id) AS unique_flight_ids
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.4
Check repeated flight_number values
*------------------------------------------------------------*/

SELECT
    flight_number,
    COUNT(*) AS occurrence_count
FROM Flights
GROUP BY flight_number
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

/*------------------------------------------------------------*
Audit 6A.5
Check invalid flight_number format
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number
FROM Flights
WHERE flight_number NOT REGEXP '^[A-Z0-9]{2}-[0-9]{3,4}$'; 
   
/*------------------------------------------------------------*
Audit 6A.6
Check airline_name distribution
*------------------------------------------------------------*/

SELECT
    airline_name,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY airline_name
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.7
Check airline_code distribution
*------------------------------------------------------------*/

SELECT
    airline_code,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY airline_code
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.8
Check whether an airline has multiple airline codes
*------------------------------------------------------------*/

SELECT
    airline_name,
    COUNT(DISTINCT airline_code) AS code_count
FROM Flights
GROUP BY airline_name
HAVING COUNT(DISTINCT airline_code) > 1;

/*------------------------------------------------------------*
Audit 6A.9
Check whether an airline code maps to multiple airline names
*------------------------------------------------------------*/

SELECT
    airline_code,
    COUNT(DISTINCT airline_name) AS airline_count
FROM Flights
GROUP BY airline_code
HAVING COUNT(DISTINCT airline_name) > 1;

/*------------------------------------------------------------*
Audit 6A.10
Check departure_airport values
*------------------------------------------------------------*/

SELECT
    departure_airport,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY departure_airport
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.11
Check arrival_airport values
*------------------------------------------------------------*/

SELECT
    arrival_airport,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY arrival_airport
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.12
Check invalid airport codes*
*------------------------------------------------------------*/

SELECT
    flight_id,
    departure_airport,
    arrival_airport
FROM Flights
WHERE departure_airport NOT REGEXP '^[A-Z]{3}$'
   OR arrival_airport NOT REGEXP '^[A-Z]{3}$';
   
/*------------------------------------------------------------*
Audit 6A.13
Check flights with identical departure and arrival airports
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    departure_airport,
    arrival_airport
FROM Flights
WHERE departure_airport = arrival_airport;

/*------------------------------------------------------------*
Audit 6A.14
Check invalid scheduled flight timeline
Scheduled arrival must be after scheduled departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    scheduled_departure,
    scheduled_arrival
FROM Flights
WHERE scheduled_arrival <= scheduled_departure;

/*------------------------------------------------------------*
Audit 6A.15
Check invalid actual flight timeline
Actual arrival must be after actual departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    actual_departure,
    actual_arrival
FROM Flights
WHERE actual_arrival <= actual_departure;

/*------------------------------------------------------------*
Audit 6A.16
Check actual departure occurring before scheduled departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    scheduled_departure,
    actual_departure
FROM Flights
WHERE actual_departure < scheduled_departure;

/*------------------------------------------------------------*
Audit 6A.17
Compare recorded departure delay with calculated delay
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    departure_delay_minutes,
    TIMESTAMPDIFF(
        MINUTE,
        scheduled_departure,
        actual_departure
    ) AS calculated_delay
FROM Flights
WHERE departure_delay_minutes <>
      TIMESTAMPDIFF(
          MINUTE,
          scheduled_departure,
          actual_departure
      );

/*------------------------------------------------------------*
Audit 6A.18
Check negative departure_delay_minutes
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    departure_delay_minutes
FROM Flights
WHERE departure_delay_minutes < 0;

/*------------------------------------------------------------*
Audit 6A.19
Check aircraft capacity range
*------------------------------------------------------------*/

SELECT
    MIN(aircraft_capacity) AS min_capacity,
    MAX(aircraft_capacity) AS max_capacity,
    AVG(aircraft_capacity) AS avg_capacity
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.20
Check aircraft capacity less than or equal to zero
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    aircraft_capacity
FROM Flights
WHERE aircraft_capacity <= 0;

/*------------------------------------------------------------*
Audit 6A.21
Check passengers_onboard range
*------------------------------------------------------------*/

SELECT
    MIN(passengers_onboard) AS min_passengers,
    MAX(passengers_onboard) AS max_passengers,
    AVG(passengers_onboard) AS avg_passengers
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.22
Check negative passengers_onboard values
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    passengers_onboard
FROM Flights
WHERE passengers_onboard < 0;

/*------------------------------------------------------------*
Audit 6A.23
Check passengers_onboard greater than aircraft_capacity
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    passengers_onboard,
    aircraft_capacity
FROM Flights
WHERE passengers_onboard > aircraft_capacity;

/*------------------------------------------------------------*
Audit 6A.24
Check aircraft_registration format
Expected format: VT-XXX
*------------------------------------------------------------*/

SELECT
    flight_id,
    aircraft_registration
FROM Flights
WHERE aircraft_registration NOT REGEXP '^VT-[A-Z]{3}$';

/*------------------------------------------------------------*
Audit 6A.25
Check repeated aircraft registrations
*------------------------------------------------------------*/

SELECT
    aircraft_registration,
    COUNT(*) AS usage_count
FROM Flights
GROUP BY aircraft_registration
HAVING COUNT(*) > 1
ORDER BY usage_count DESC;

/*------------------------------------------------------------*
Audit 6A.26
Check flight_status values
*------------------------------------------------------------*/

SELECT
    flight_status,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY flight_status
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.27
Check delay_reason values
*------------------------------------------------------------*/

SELECT
    delay_reason,
    COUNT(*) AS occurrence_count
FROM Flights
GROUP BY delay_reason
ORDER BY occurrence_count DESC;

/*------------------------------------------------------------*
Audit 6A.28
Check terminal values
*------------------------------------------------------------*/

SELECT
    terminal,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY terminal
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.29
Check gate values
*------------------------------------------------------------*/

SELECT
    gate,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY gate
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.30
Check invalid terminal format
*------------------------------------------------------------*/

SELECT
    flight_id,
    terminal
FROM Flights
WHERE terminal NOT REGEXP '^T[0-9]+$';

/*------------------------------------------------------------*
Audit 6A.31
Check invalid gate format
*------------------------------------------------------------*/

SELECT
    flight_id,
    gate
FROM Flights
WHERE gate NOT REGEXP '^[A-Z][0-9]+$';

/*------------------------------------------------------------*
Audit 6A.32
Check international_flight values
*------------------------------------------------------------*/

SELECT
    international_flight,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY international_flight;

/*------------------------------------------------------------*
Audit 6A.33
Check boarding_completed values
*------------------------------------------------------------*/

SELECT
    boarding_completed,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY boarding_completed;

/*------------------------------------------------------------*
Audit 6A.34
Check holiday_flag values
*------------------------------------------------------------*/

SELECT
    holiday_flag,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY holiday_flag;

/*------------------------------------------------------------*
Audit 6A.35
Check invalid values in binary flag columns
*------------------------------------------------------------*/

SELECT
    COUNT(*) AS invalid_flag_rows
FROM Flights
WHERE international_flight NOT IN (0,1)
   OR boarding_completed NOT IN (0,1)
   OR holiday_flag NOT IN (0,1);

/*------------------------------------------------------------*
Audit 6A.36
Check flight_distance_km range
*------------------------------------------------------------*/

SELECT
    MIN(flight_distance_km) AS min_distance,
    MAX(flight_distance_km) AS max_distance,
    AVG(flight_distance_km) AS avg_distance
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.37
Check invalid flight distance values
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    flight_distance_km
FROM Flights
WHERE flight_distance_km <= 0;

/*------------------------------------------------------------*
Audit 6A.38
Check fuel_consumption_liters range
*------------------------------------------------------------*/

SELECT
    MIN(fuel_consumption_liters) AS min_fuel,
    MAX(fuel_consumption_liters) AS max_fuel,
    AVG(fuel_consumption_liters) AS avg_fuel
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.39
Check invalid fuel consumption values
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    fuel_consumption_liters
FROM Flights
WHERE fuel_consumption_liters <= 0;

/*------------------------------------------------------------*
Audit 6A.40
Check boarding_start_time occurring after actual departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    boarding_start_time,
    actual_departure
FROM Flights
WHERE boarding_start_time > actual_departure;

/*------------------------------------------------------------*
Audit 6A.41
Check boarding_start_time occurring after scheduled departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    boarding_start_time,
    scheduled_departure
FROM Flights
WHERE boarding_start_time > scheduled_departure;

/*------------------------------------------------------------*
Audit 6A.42
Check operational_score range
*------------------------------------------------------------*/

SELECT
    MIN(operational_score) AS min_score,
    MAX(operational_score) AS max_score,
    AVG(operational_score) AS avg_score
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.43
Check occupancy_percentage range
*------------------------------------------------------------*/

SELECT
    MIN(occupancy_percentage) AS min_occupancy,
    MAX(occupancy_percentage) AS max_occupancy,
    AVG(occupancy_percentage) AS avg_occupancy
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.44
Check occupancy_percentage outside 0-100 range
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    occupancy_percentage
FROM Flights
WHERE occupancy_percentage < 0
   OR occupancy_percentage > 100;

/*------------------------------------------------------------*
Audit 6A.45
Compare recorded occupancy with calculated occupancy
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    passengers_onboard,
    aircraft_capacity,
    occupancy_percentage,
    ROUND(
        passengers_onboard / aircraft_capacity * 100,
        2
    ) AS calculated_occupancy
FROM Flights
WHERE ABS(
    occupancy_percentage -
    (passengers_onboard / aircraft_capacity * 100)
) > 0.1;

/*------------------------------------------------------------*
Audit 6A.46*
Check load_factor range
*------------------------------------------------------------*/

SELECT
    MIN(load_factor) AS min_load_factor,
    MAX(load_factor) AS max_load_factor,
    AVG(load_factor) AS avg_load_factor
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.47
Check load_factor outside 0-1 range
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    load_factor
FROM Flights
WHERE load_factor < 0
   OR load_factor > 1;

/*------------------------------------------------------------*
Audit 6A.48
Check departure_shift values
*------------------------------------------------------------*/

SELECT
    departure_shift,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY departure_shift
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.49
Check unexpected departure_shift values
*------------------------------------------------------------*/

SELECT DISTINCT
    departure_shift
FROM Flights
WHERE departure_shift NOT IN (
    'Morning',
    'Afternoon',
    'Evening',
    'Night'
);

/*------------------------------------------------------------*
Audit 6A.50
Check day_of_week values
*------------------------------------------------------------*/

SELECT
    day_of_week,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY day_of_week
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.51
Compare day_of_week with scheduled_departure
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    scheduled_departure,
    day_of_week,
    DATE_FORMAT(scheduled_departure, '%a') AS calculated_day
FROM Flights
WHERE day_of_week <>
      DATE_FORMAT(scheduled_departure, '%a');

/*------------------------------------------------------------*
Audit 6A.52
Check season values
*------------------------------------------------------------*/

SELECT
    season,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY season
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.53
Compare season with scheduled_departure month
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    scheduled_departure,
    season
FROM Flights
WHERE
    (MONTH(scheduled_departure) IN (12,1,2)
        AND season <> 'Winter')
 OR (MONTH(scheduled_departure) IN (3,4,5)
        AND season <> 'Spring')
 OR (MONTH(scheduled_departure) IN (6,7,8)
        AND season <> 'Summer')
 OR (MONTH(scheduled_departure) IN (9,10,11)
        AND season <> 'Autumn');

/*------------------------------------------------------------*
Audit 6A.54
Check route_type values
*------------------------------------------------------------*/

SELECT
    route_type,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY route_type
ORDER BY flight_count DESC;

/*------------------------------------------------------------*
Audit 6A.55
Check relationship between international_flight and route_type
*------------------------------------------------------------*/

SELECT
    international_flight,
    route_type,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY
    international_flight,
    route_type
ORDER BY
    international_flight,
    route_type;

/*------------------------------------------------------------*
Audit 6A.56
Check aircraft capacity distribution by aircraft model
*------------------------------------------------------------*/

SELECT
    aircraft_model,
    MIN(aircraft_capacity) AS min_capacity,
    MAX(aircraft_capacity) AS max_capacity,
    AVG(aircraft_capacity) AS avg_capacity,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY aircraft_model
ORDER BY aircraft_model;

/*------------------------------------------------------------*
Audit 6A.57
Check fuel consumption relative to flight distance
*------------------------------------------------------------*/

SELECT
    flight_id,
    flight_number,
    flight_distance_km,
    fuel_consumption_liters,
    ROUND(
        fuel_consumption_liters / flight_distance_km,
        3
    ) AS fuel_per_km
FROM Flights
WHERE flight_distance_km > 0
  AND fuel_consumption_liters > 0
ORDER BY fuel_per_km DESC;

/*------------------------------------------------------------*
Audit 6A.58
Check duplicate flight instances
*------------------------------------------------------------*/

SELECT
    flight_number,
    scheduled_departure,
    departure_airport,
    arrival_airport,
    COUNT(*) AS occurrence_count
FROM Flights
GROUP BY
    flight_number,
    scheduled_departure,
    departure_airport,
    arrival_airport
HAVING COUNT(*) > 1;

/*------------------------------------------------------------*
Audit 6A.59
Check scheduled flight date range
*------------------------------------------------------------*/

SELECT
    MIN(scheduled_departure) AS earliest_flight,
    MAX(scheduled_departure) AS latest_flight
FROM Flights;

/*------------------------------------------------------------*
Audit 6A.60
Overall data quality summary for Flights
*------------------------------------------------------------*/

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT flight_id) AS unique_flight_ids,

    SUM(flight_id IS NULL) AS null_flight_ids,

    SUM(flight_number IS NULL) AS null_flight_numbers,

    SUM(aircraft_capacity <= 0)
        AS invalid_capacity,

    SUM(passengers_onboard < 0)
        AS negative_passengers,

    SUM(passengers_onboard > aircraft_capacity)
        AS passengers_over_capacity,

    SUM(departure_delay_minutes < 0)
        AS negative_delays,

    SUM(flight_distance_km <= 0)
        AS invalid_distance,

    SUM(fuel_consumption_liters <= 0)
        AS invalid_fuel,

    SUM(occupancy_percentage < 0
        OR occupancy_percentage > 100)
        AS invalid_occupancy,

    SUM(load_factor < 0
        OR load_factor > 1)
        AS invalid_load_factor,

    SUM(scheduled_arrival <= scheduled_departure)
        AS invalid_scheduled_timeline,

    SUM(actual_arrival <= actual_departure)
        AS invalid_actual_timeline

FROM Flights;

/*------------------------------------------------------------*

*Audit 6A.61*

*Check terminal distribution by departure airport*

*------------------------------------------------------------*/

SELECT
    departure_airport,
    terminal,
    COUNT(*) AS flight_count
FROM Flights
GROUP BY
    departure_airport,
    terminal
ORDER BY
    departure_airport,
    flight_count DESC;

SELECT
    flight_id,
    flight_number,
    boarding_start_time,
    scheduled_departure,
    boarding_completed
FROM Flights
WHERE
    (boarding_completed = 1
     AND boarding_start_time > scheduled_departure)
 OR
    (boarding_completed = 0
     AND boarding_start_time < scheduled_departure);
     
ALTER TABLE Flights
DROP COLUMN boarding_completed;
/*------------------------------------------------------------
Findings
--------------------------------------------------------------

1. No missing values were found in any critical column.

2. Flight IDs are unique.

3. No duplicate flight instances were found
   (Flight Number + Scheduled Departure).

4. Airport codes follow the standard three-letter format.

5. Flight timings are valid.
   Scheduled arrival is never earlier than scheduled departure.

6. No negative departure delays were found.

7. Airline names and aircraft registrations are already
   standardized.

8. Boolean columns contain only valid values (0 and 1).

9. Flight distance and fuel consumption values are valid.

10. Data Quality Observation:
    53 flights have passengers onboard greater than the
    aircraft seating capacity.

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Passengers onboard cannot exceed aircraft capacity.
------------------------------------------------------------*/

UPDATE Flights
SET passengers_onboard = aircraft_capacity
WHERE passengers_onboard > aircraft_capacity;

/*------------------------------------------------------------
Cleaning Rule 2
Recalculate occupancy percentage.
------------------------------------------------------------*/

UPDATE Flights
SET occupancy_percentage =
ROUND(
(passengers_onboard * 100.0) /
aircraft_capacity,
2
);

/*------------------------------------------------------------
Cleaning Rule 3
Recalculate load factor.
------------------------------------------------------------*/

UPDATE Flights
SET load_factor =
ROUND(
passengers_onboard /
aircraft_capacity,
4
);

/*------------------------------------------------------------
Cleaning Rule 4
Operational score cannot exceed 100.
Cap all values greater than 100.
------------------------------------------------------------*/

UPDATE Flights
SET operational_score = 100
WHERE operational_score > 100;

/*------------------------------------------------------------*
*Fix Departure Shift
*
*Business Rules:
*00:00–05:59  -> Night
*06:00–11:59  -> Morning
*12:00–16:59  -> Afternoon
*17:00–23:59  -> Evening
*------------------------------------------------------------*/

UPDATE Flights
SET departure_shift =
    CASE
        WHEN HOUR(scheduled_departure) BETWEEN 0 AND 5
            THEN 'Night'

        WHEN HOUR(scheduled_departure) BETWEEN 6 AND 11
            THEN 'Morning'

        WHEN HOUR(scheduled_departure) BETWEEN 12 AND 16
            THEN 'Afternoon'

        WHEN HOUR(scheduled_departure) BETWEEN 17 AND 23
            THEN 'Evening'
    END;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(passengers_onboard > aircraft_capacity) AS Capacity_Violations,
    SUM(occupancy_percentage > 100) AS Occupancy_Violations,
    SUM(load_factor > 1) AS Load_Factor_Violations,
    SUM(operational_score > 100) AS Operational_Score_Violations
FROM Flights;
