USE Airport_Operations_DSS;

/*------------------------------------------------------------
Audit 6D.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(gate_event_id IS NULL) AS gate_event_id_nulls,
    SUM(flight_number IS NULL) AS flight_number_nulls,
    SUM(gate_number IS NULL) AS gate_number_nulls,
    SUM(terminal IS NULL) AS terminal_nulls,
    SUM(event_type IS NULL) AS event_type_nulls,
    SUM(scheduled_event_time IS NULL) AS scheduled_event_time_nulls,
    SUM(actual_event_time IS NULL) AS actual_event_time_nulls,
    SUM(gate_open_time IS NULL) AS gate_open_time_nulls,
    SUM(gate_close_time IS NULL) AS gate_close_time_nulls
FROM Gate_Events;

/*------------------------------------------------------------
Audit 6D.2
Check Duplicate Gate Event IDs
------------------------------------------------------------*/

SELECT
    gate_event_id,
    COUNT(*) AS occurrence_count
FROM Gate_Events
GROUP BY gate_event_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6D.3
Validate Event Types
------------------------------------------------------------*/

SELECT DISTINCT event_type
FROM Gate_Events
ORDER BY event_type;

/*------------------------------------------------------------
Audit 6D.4
Validate Event Categories
------------------------------------------------------------*/

SELECT DISTINCT event_category
FROM Gate_Events
ORDER BY event_category;

/*------------------------------------------------------------
Audit 6D.5
Validate Delayed Flag
------------------------------------------------------------*/

SELECT DISTINCT delayed_flag
FROM Gate_Events;

/*------------------------------------------------------------
Audit 6D.6
Compare Actual and Scheduled Event Times
------------------------------------------------------------*/

SELECT
    gate_event_id,
    flight_number,
    scheduled_event_time,
    actual_event_time,
    TIMESTAMPDIFF(
        MINUTE,
        scheduled_event_time,
        actual_event_time
    ) AS Event_Delay_Minutes
FROM Gate_Events;

/*------------------------------------------------------------
Audit 6D.7
Identify Events Occurring Before Scheduled Time
------------------------------------------------------------*/

SELECT
    gate_event_id,
    flight_number,
    scheduled_event_time,
    actual_event_time
FROM Gate_Events
WHERE actual_event_time < scheduled_event_time;

/*------------------------------------------------------------
Audit 6D.8
Validate Gate Open and Close Times
------------------------------------------------------------*/

SELECT
    gate_event_id,
    gate_open_time,
    gate_close_time
FROM Gate_Events
WHERE gate_close_time <= gate_open_time;

/*------------------------------------------------------------
Audit 6D.9
Validate Actual Event Within Gate Operating Window
------------------------------------------------------------*/

SELECT
    gate_event_id,
    actual_event_time,
    gate_open_time,
    gate_close_time
FROM Gate_Events
WHERE actual_event_time < gate_open_time
   OR actual_event_time > gate_close_time;
   
/*------------------------------------------------------------
Audit 6D.10
Validate Passengers Processed
------------------------------------------------------------*/

SELECT *
FROM Gate_Events
WHERE passengers_processed < 0;

/*------------------------------------------------------------
Audit 6D.11
Identify Events With Zero Passengers Processed
------------------------------------------------------------*/

SELECT
    event_type,
    COUNT(*) AS event_count
FROM Gate_Events
WHERE passengers_processed = 0
GROUP BY event_type
ORDER BY event_count DESC;

/*------------------------------------------------------------
Audit 6D.12
Inspect Gate and Terminal Combinations
------------------------------------------------------------*/

SELECT
    terminal,
    gate_number,
    COUNT(*) AS event_count
FROM Gate_Events
GROUP BY terminal, gate_number
ORDER BY terminal, gate_number;

/*------------------------------------------------------------
Audit 6D.13
Check Missing Staff Assignments
------------------------------------------------------------*/

SELECT
    COUNT(*) AS Missing_Staff
FROM Gate_Events
WHERE staff_id IS NULL;

/*------------------------------------------------------------
Data Quality Findings
------------------------------------------------------------

1. No significant issues were identified in gate event
   identifiers, passenger counts or categorical fields.

2. Major inconsistencies were identified in the gate event
   timestamp fields.

3. Scheduled event times were not consistently aligned with
   the associated flight schedule.

4. Actual event times were found to occur substantially before
   or after their corresponding scheduled event times.

5. Gate open and gate close timestamps were also inconsistent,
   including records where gate close occurred before gate open.

6. The timestamp inconsistencies indicate that gate operational
   timestamps were generated independently rather than
   following the associated flight schedule.

7. The gate event timeline is reconstructed using the associated
   flight's scheduled departure as the trusted reference point.

8. Randomized but controlled intervals are used to introduce
   realistic variation between gate events while maintaining
   valid operational boundaries.

9. Scheduled event times are generated at different intervals
   before flight departure.

10. Actual event times are generated independently around the
    scheduled event time to represent early, on-time and
    delayed gate events.

11. The delay flag is recalculated from the relationship between
    actual and scheduled event times:
    
        Actual > Scheduled  → delay_flag = 1
        Actual <= Scheduled → delay_flag = 0

12. Gate close times are generated after the actual event while
    remaining before the scheduled flight departure.

13. The corrected operational sequence follows:

        Gate Open
            ↓
        Scheduled Event
            ↓
        Actual Event
            ↓
        Gate Close
            ↓
        Flight Departure

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Map each gate event to its appropriate flight instance and
generate randomized operational intervals.

Business Rules:
- Gate Open       = 90–120 minutes before departure
- Scheduled Event = 60–90 minutes before departure
- Actual Event    = 10 minutes early to 20 minutes late
- Gate Close      = 10–20 minutes after actual event
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_GateEvent_Flight_Mapping;

CREATE TEMPORARY TABLE Temp_GateEvent_Flight_Mapping AS

SELECT
    g.gate_event_id,

    (
        SELECT f.scheduled_departure
        FROM Flights f
        WHERE f.flight_number = g.flight_number
          AND f.scheduled_departure IS NOT NULL
        ORDER BY
            ABS(
                TIMESTAMPDIFF(
                    SECOND,
                    g.scheduled_event_time,
                    f.scheduled_departure
                )
            ),
            f.flight_id
        LIMIT 1
    ) AS flight_departure,

    /* Gate opens 90–120 minutes before departure */
    (90 + FLOOR(RAND() * 31))
        AS gate_open_offset_minutes,

    /* Scheduled event 60–90 minutes before departure */
    (60 + FLOOR(RAND() * 31))
        AS scheduled_event_offset_minutes,

    /* Actual event:
       -10 to +20 minutes relative to scheduled event */
    (-10 + FLOOR(RAND() * 31))
        AS actual_event_variation_minutes,

    /* Gate closes 10–20 minutes after actual event */
    (10 + FLOOR(RAND() * 11))
        AS gate_close_offset_minutes

FROM Gate_Events g;

/*------------------------------------------------------------
Cleaning Rule 2
Reconstruct gate event timestamps using randomized
operational intervals.

Actual event time is allowed to occur before, at, or after
the scheduled event time.
------------------------------------------------------------*/

UPDATE Gate_Events g
JOIN Temp_GateEvent_Flight_Mapping m
    ON g.gate_event_id = m.gate_event_id

SET
    g.gate_open_time =
        TIMESTAMPADD(
            MINUTE,
            -m.gate_open_offset_minutes,
            m.flight_departure
        ),

    g.scheduled_event_time =
        TIMESTAMPADD(
            MINUTE,
            -m.scheduled_event_offset_minutes,
            m.flight_departure
        ),

    g.actual_event_time =
        TIMESTAMPADD(
            MINUTE,
            -m.scheduled_event_offset_minutes
            + m.actual_event_variation_minutes,
            m.flight_departure
        ),

    g.gate_close_time =
        TIMESTAMPADD(
            MINUTE,
            -m.scheduled_event_offset_minutes
            + m.actual_event_variation_minutes
            + m.gate_close_offset_minutes,
            m.flight_departure
        )

WHERE m.flight_departure IS NOT NULL;

/*------------------------------------------------------------
Cleaning Rule 3
Recalculate delay flag based on actual versus scheduled
event time.
------------------------------------------------------------*/

UPDATE Gate_Events
SET delay_flag =
    CASE
        WHEN actual_event_time > scheduled_event_time
        THEN 1
        ELSE 0
    END;
    
/*------------------------------------------------------------
Cleanup temporary mapping table.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_GateEvent_Flight_Mapping;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(gate_open_time >= scheduled_event_time)
        AS Invalid_Gate_Open,

    SUM(
        gate_close_time <= actual_event_time
    ) AS Invalid_Gate_Close,

    SUM(
        actual_event_time >=
        (
            SELECT MAX(f.scheduled_departure)
            FROM Flights f
            WHERE f.flight_number = Gate_Events.flight_number
        )
    ) AS Invalid_Departure_Timing,

    SUM(
        delay_flag <>
        CASE
            WHEN actual_event_time > scheduled_event_time
            THEN 1
            ELSE 0
        END
    ) AS Delay_Flag_Mismatches

FROM Gate_Events;