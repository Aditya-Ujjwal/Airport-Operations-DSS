USE Airport_Operations_DSS;

/*============================================================
Security Screening Table
============================================================*/

/*------------------------------------------------------------
Audit 6E.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(screening_id IS NULL) AS screening_id_nulls,
    SUM(passport_number IS NULL) AS passport_nulls,
    SUM(screening_reference IS NULL) AS screening_reference_nulls,
    SUM(security_level IS NULL) AS security_level_nulls,
    SUM(arrival_time IS NULL) AS arrival_time_nulls,
    SUM(screening_start_time IS NULL) AS screening_start_nulls,
    SUM(screening_end_time IS NULL) AS screening_end_nulls,
    SUM(screening_result IS NULL) AS screening_result_nulls,
    SUM(security_officer_id IS NULL) AS officer_nulls,
    SUM(scanner_type IS NULL) AS scanner_type_nulls
FROM Security_Screening;

/*------------------------------------------------------------
Audit 6E.2
Check Duplicate Screening IDs
------------------------------------------------------------*/

SELECT
    screening_id,
    COUNT(*) AS occurrence_count
FROM Security_Screening
GROUP BY screening_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6E.3
Validate Security Levels
------------------------------------------------------------*/

SELECT DISTINCT security_level
FROM Security_Screening
ORDER BY security_level;

/*------------------------------------------------------------
Audit 6E.4
Validate Screening Results
------------------------------------------------------------*/

SELECT DISTINCT screening_result
FROM Security_Screening
ORDER BY screening_result;

/*------------------------------------------------------------
Audit 6E.5
Validate Security Shift Values
------------------------------------------------------------*/

SELECT DISTINCT security_shift
FROM Security_Screening
ORDER BY security_shift;

/*------------------------------------------------------------
Audit 6E.6
Validate Security Boolean Flags
------------------------------------------------------------*/

SELECT
    'alarm_triggered' AS column_name,
    COUNT(DISTINCT alarm_triggered) AS distinct_values
FROM Security_Screening

UNION ALL

SELECT
    'prohibited_item_found',
    COUNT(DISTINCT prohibited_item_found)
FROM Security_Screening

UNION ALL

SELECT
    'secondary_screening_required',
    COUNT(DISTINCT secondary_screening_required)
FROM Security_Screening;

SELECT DISTINCT
    alarm_triggered,
    prohibited_item_found,
    secondary_screening_required
FROM Security_Screening;

/*------------------------------------------------------------
Audit 6E.7
Validate Screening Duration
------------------------------------------------------------*/

SELECT
    MIN(screening_duration_minutes) AS Min_Duration,
    MAX(screening_duration_minutes) AS Max_Duration
FROM Security_Screening;

SELECT *
FROM Security_Screening
WHERE screening_duration_minutes < 0;

/*------------------------------------------------------------
Audit 6E.8
Validate Passengers Processed
------------------------------------------------------------*/

SELECT *
FROM Security_Screening
WHERE passengers_processed < 0;

/*------------------------------------------------------------
Audit 6E.9
Validate Queue Capacity
------------------------------------------------------------*/

SELECT *
FROM Security_Screening
WHERE queue_capacity < 0;

/*------------------------------------------------------------
Audit 6E.10
Validate Scanner Capacity
------------------------------------------------------------*/

SELECT *
FROM Security_Screening
WHERE scanner_capacity < 0;

/*------------------------------------------------------------
Audit 6E.11
Check Passenger Processing Against Queue Capacity
------------------------------------------------------------*/

SELECT
    screening_id,
    passengers_processed,
    queue_capacity
FROM Security_Screening
WHERE passengers_processed > queue_capacity;

/*------------------------------------------------------------
Audit 6E.12
Validate VIP Passenger Flag
------------------------------------------------------------*/

SELECT DISTINCT vip_passenger
FROM Security_Screening;

/*------------------------------------------------------------
Audit 6E.13
Validate Screening Timeline
------------------------------------------------------------*/

SELECT
    screening_id,
    arrival_time,
    screening_start_time,
    screening_end_time
FROM Security_Screening
WHERE screening_start_time < arrival_time
   OR screening_end_time < screening_start_time;
   
/*------------------------------------------------------------
Audit 6E.14
Compare Recorded and Calculated Screening Duration
------------------------------------------------------------*/

SELECT
    screening_id,
    screening_duration_minutes,
    TIMESTAMPDIFF(
        MINUTE,
        screening_start_time,
        screening_end_time
    ) AS Calculated_Duration
FROM Security_Screening
WHERE screening_duration_minutes <>
      TIMESTAMPDIFF(
          MINUTE,
          screening_start_time,
          screening_end_time
      );

/*------------------------------------------------------------
Audit 6E.15
Calculate Waiting Time Before Screening
------------------------------------------------------------*/

SELECT
    MIN(
        TIMESTAMPDIFF(
            MINUTE,
            arrival_time,
            screening_start_time
        )
    ) AS Min_Wait_Minutes,

    MAX(
        TIMESTAMPDIFF(
            MINUTE,
            arrival_time,
            screening_start_time
        )
    ) AS Max_Wait_Minutes
FROM Security_Screening;

/*------------------------------------------------------------
Data Quality Findings
------------------------------------------------------------

1. No significant issues were identified in screening
   identifiers, categorical fields, passenger counts or
   capacity-related values.

2. Major inconsistencies were identified in the screening
   timestamp fields.

3. Screening start times were found to occur before or
   unrealistically far after passenger arrival times.

4. Screening end times were found to occur before screening
   start times for multiple records.

5. Recorded screening duration did not consistently match the
   difference between screening start and end times.

6. The timestamp inconsistencies indicate that screening
   operational timestamps were generated independently rather
   than following the passenger screening workflow.

7. The screening timeline is reconstructed using arrival time
   as the trusted reference point.

8. Randomized but controlled time intervals are used to create
   realistic variation between screening records while
   remaining within defined operational business rules.

9. Screening start time is generated 5–30 minutes after
   passenger arrival.

10. Screening end time is generated 10–45 minutes after
    screening start time.

11. Screening duration is recalculated from the corrected
    screening start and end timestamps.

12. Boolean fields are not artificially modified because their
    existing values cannot be reliably inferred or generated
    from another trusted field.

13. The corrected screening workflow follows:

        Arrival
           ↓
        Screening Start
           ↓
        Screening End

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Generate randomized screening intervals.

Business Rules:
- Arrival → Screening Start = 5–30 minutes
- Screening Start → Screening End = 10–45 minutes
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Security_Screening_Timing;

CREATE TEMPORARY TABLE Temp_Security_Screening_Timing AS

SELECT
    screening_id,

    /* Waiting time before screening: 5–30 minutes */
    (5 + FLOOR(RAND() * 26))
        AS arrival_to_screening_minutes,

    /* Screening duration: 10–45 minutes */
    (10 + FLOOR(RAND() * 36))
        AS screening_duration_minutes

FROM Security_Screening;

/*------------------------------------------------------------
Cleaning Rule 2
Reconstruct screening timestamps from passenger arrival time.
------------------------------------------------------------*/

UPDATE Security_Screening s
JOIN Temp_Security_Screening_Timing t
    ON s.screening_id = t.screening_id

SET
    s.screening_start_time =
        DATE_ADD(
            s.arrival_time,
            INTERVAL t.arrival_to_screening_minutes MINUTE
        ),

    s.screening_end_time =
        DATE_ADD(
            DATE_ADD(
                s.arrival_time,
                INTERVAL t.arrival_to_screening_minutes MINUTE
            ),
            INTERVAL t.screening_duration_minutes MINUTE
        )

WHERE s.arrival_time IS NOT NULL;

/*------------------------------------------------------------
Cleaning Rule 3
Recalculate screening duration from the corrected timestamps.
------------------------------------------------------------*/

UPDATE Security_Screening
SET screening_duration_minutes =
    TIMESTAMPDIFF(
        MINUTE,
        screening_start_time,
        screening_end_time
    )
WHERE screening_start_time IS NOT NULL
  AND screening_end_time IS NOT NULL;
  
/*------------------------------------------------------------
Cleanup temporary timing table.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Security_Screening_Timing;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(
        screening_start_time < arrival_time
    ) AS Invalid_Screening_Start,

    SUM(
        screening_end_time <= screening_start_time
    ) AS Invalid_Screening_End,

    SUM(
        TIMESTAMPDIFF(
            MINUTE,
            screening_start_time,
            screening_end_time
        ) NOT BETWEEN 10 AND 45
    ) AS Invalid_Screening_Duration,

    SUM(
        screening_duration_minutes <>
        TIMESTAMPDIFF(
            MINUTE,
            screening_start_time,
            screening_end_time
        )
    ) AS Duration_Mismatches

FROM Security_Screening;