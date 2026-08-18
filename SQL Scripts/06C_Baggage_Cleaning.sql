USE Airport_Operations_DSS;

/*------------------------------------------------------------
Audit 6C.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(baggage_reference IS NULL) AS baggage_reference_nulls,
    SUM(flight_number IS NULL) AS flight_number_nulls,
    SUM(passport_number IS NULL) AS passport_number_nulls,
    SUM(baggage_weight_kg IS NULL) AS baggage_weight_nulls,
    SUM(checkin_time IS NULL) AS checkin_time_nulls,
    SUM(loading_time IS NULL) AS loading_time_nulls,
    SUM(baggage_status IS NULL) AS baggage_status_nulls
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.2
Check Duplicate Baggage Tags
------------------------------------------------------------*/

SELECT
    baggage_tag,
    COUNT(*) AS occurrence_count
FROM Baggage
GROUP BY baggage_tag
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6C.3
Check Duplicate Baggage References
------------------------------------------------------------*/

SELECT 
    baggage_reference, COUNT(*) AS occurrence_count
FROM
    Baggage
GROUP BY baggage_reference
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6C.4
Validate Baggage Weight
------------------------------------------------------------*/

SELECT *
FROM Baggage
WHERE baggage_weight_kg <= 0;

/*------------------------------------------------------------
Audit 6C.5
Validate Timeline
------------------------------------------------------------*/

SELECT *
FROM Baggage
WHERE loading_time < checkin_time;

/*------------------------------------------------------------
Audit 6C.6
Validate Priority Level
------------------------------------------------------------*/

SELECT
MIN(baggage_priority),
MAX(baggage_priority)
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.7
Validate Baggage Status
------------------------------------------------------------*/

SELECT DISTINCT baggage_status
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.8
Validate Fragile Flag
------------------------------------------------------------*/

SELECT DISTINCT fragile_flag
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.9
Validate Security Flag
------------------------------------------------------------*/

SELECT DISTINCT security_flag
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.10
Validate Mishandled Flag
------------------------------------------------------------*/

SELECT DISTINCT mishandled_flag
FROM Baggage;

/*------------------------------------------------------------
Audit 6C.11
Validate Last Scan Time
------------------------------------------------------------*/

SELECT *
FROM Baggage
WHERE last_scan_time < loading_time;

/*------------------------------------------------------------
Audit 6C.12
Validate Check-in Time Against Flight Departure
------------------------------------------------------------*/

SELECT
    b.baggage_tag,
    b.flight_number,
    b.checkin_time,
    f.scheduled_departure,
    TIMESTAMPDIFF(
        MINUTE,
        b.checkin_time,
        f.scheduled_departure
    ) AS Minutes_Before_Departure
FROM Baggage b
JOIN Flights f
    ON b.flight_number = f.flight_number;
    
SELECT
    b.baggage_tag,
    b.flight_number,
    b.checkin_time,
    f.scheduled_departure
FROM Baggage b
JOIN Flights f
    ON b.flight_number = f.flight_number
WHERE b.checkin_time >= f.scheduled_departure;

SELECT
    b.baggage_tag,
    b.flight_number,
    b.checkin_time,
    f.scheduled_departure,
    TIMESTAMPDIFF(
        HOUR,
        b.checkin_time,
        f.scheduled_departure
    ) AS Hours_Before_Departure
FROM Baggage b
JOIN Flights f
    ON b.flight_number = f.flight_number
WHERE TIMESTAMPDIFF(
          HOUR,
          b.checkin_time,
          f.scheduled_departure
      ) NOT BETWEEN 0 AND 6;
      
/*============================================================
3.Baggage
============================================================*/

/*------------------------------------------------------------
Data Quality Findings
------------------------------------------------------------

1. No significant issues were identified in baggage
   identifiers, baggage weight, priority, status or boolean
   flag columns.

2. Major inconsistencies were identified in the baggage
   timestamp fields.

3. Multiple records contained loading times earlier than
   check-in times.

4. Multiple records contained last scan times earlier than
   loading times.

5. Baggage check-in times were also inconsistent with the
   associated flight schedule, including records where
   check-in occurred after the scheduled flight departure.

6. The timestamp inconsistencies indicate that baggage
   operational timestamps were generated independently rather
   than following the baggage handling workflow.

7. The timestamps are therefore reconstructed using the
   associated flight's scheduled departure as the trusted
   reference point.

8. For duplicate flight numbers, the flight instance whose
   scheduled departure is closest to the original baggage
   check-in time is selected.

9. Randomized but controlled time intervals are used to create
   realistic variation between baggage records while remaining
   within defined operational business rules.

10. The corrected baggage workflow follows:

        Flight Departure
              ↑
        Check-in
              ↑
        Loading
              ↑
        Last Scan

    with all timestamps occurring before the scheduled flight
    departure.

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Map each baggage record to its appropriate flight instance.

For duplicate flight numbers, the flight whose scheduled
departure is closest to the original baggage check-in time
is selected.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Baggage_Flight_Mapping;

CREATE TEMPORARY TABLE Temp_Baggage_Flight_Mapping AS

SELECT
    b.baggage_tag,

    (
        SELECT f.scheduled_departure
        FROM Flights f
        WHERE f.flight_number = b.flight_number
          AND f.scheduled_departure IS NOT NULL
        ORDER BY
            ABS(
                TIMESTAMPDIFF(
                    SECOND,
                    b.checkin_time,
                    f.scheduled_departure
                )
            ),
            f.flight_id
        LIMIT 1
    ) AS scheduled_departure,

    (120 + FLOOR(RAND() * 121)) AS checkin_offset_minutes,

    (15 + FLOOR(RAND() * 31)) AS loading_offset_minutes,

    (10 + FLOOR(RAND() * 21)) AS scan_offset_minutes

FROM Baggage b;

/*------------------------------------------------------------
Apply randomized baggage timestamps.
------------------------------------------------------------*/

UPDATE Baggage b
JOIN Temp_Baggage_Flight_Mapping m
    ON b.baggage_tag = m.baggage_tag

SET
    b.checkin_time =
        DATE_SUB(
            m.scheduled_departure,
            INTERVAL m.checkin_offset_minutes MINUTE
        ),

    b.loading_time =
        DATE_ADD(
            DATE_SUB(
                m.scheduled_departure,
                INTERVAL m.checkin_offset_minutes MINUTE
            ),
            INTERVAL m.loading_offset_minutes MINUTE
        ),

    b.last_scan_time =
        DATE_ADD(
            DATE_ADD(
                DATE_SUB(
                    m.scheduled_departure,
                    INTERVAL m.checkin_offset_minutes MINUTE
                ),
                INTERVAL m.loading_offset_minutes MINUTE
            ),
            INTERVAL m.scan_offset_minutes MINUTE
        )

WHERE m.scheduled_departure IS NOT NULL;

/*------------------------------------------------------------
Cleanup temporary mapping table.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Baggage_Flight_Mapping;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(loading_time <= checkin_time)
        AS Invalid_Checkin_Loading,

    SUM(last_scan_time <= loading_time)
        AS Invalid_Loading_Scan,

    SUM(
        TIMESTAMPDIFF(
            MINUTE,
            checkin_time,
            loading_time
        ) NOT BETWEEN 15 AND 45
    ) AS Invalid_Loading_Interval,

    SUM(
        TIMESTAMPDIFF(
            MINUTE,
            loading_time,
            last_scan_time
        ) NOT BETWEEN 10 AND 30
    ) AS Invalid_Scan_Interval
FROM Baggage;