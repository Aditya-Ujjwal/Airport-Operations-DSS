/*------------------------------------------------------------
Audit 7.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(maintenance_log_id IS NULL) AS log_id_nulls,
    SUM(work_order_id IS NULL) AS work_order_nulls,
    SUM(aircraft_registration IS NULL) AS aircraft_nulls,
    SUM(flight_number IS NULL) AS flight_number_nulls,
    SUM(maintenance_type IS NULL) AS maintenance_type_nulls,
    SUM(technician_id IS NULL) AS technician_nulls,
    SUM(maintenance_start IS NULL) AS maintenance_start_nulls,
    SUM(maintenance_end IS NULL) AS maintenance_end_nulls,
    SUM(priority_level IS NULL) AS priority_nulls,
    SUM(estimated_duration_hours IS NULL) AS duration_nulls,
    SUM(issue_description IS NULL) AS issue_nulls,
    SUM(replaced_component IS NULL) AS component_nulls,
    SUM(severity_level IS NULL) AS severity_nulls,
    SUM(supervisor_id IS NULL) AS supervisor_nulls,
    SUM(maintenance_completed IS NULL) AS completed_nulls,
    SUM(inspection_passed IS NULL) AS inspection_nulls
FROM Maintenance_Logs;

/*------------------------------------------------------------
Audit 7.2
Check Duplicate Maintenance Log IDs
------------------------------------------------------------*/

SELECT
    maintenance_log_id,
    COUNT(*) AS occurrence_count
FROM Maintenance_Logs
GROUP BY maintenance_log_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 7.3
Check Duplicate Work Orders
------------------------------------------------------------*/

SELECT
    work_order_id,
    COUNT(*) AS occurrence_count
FROM Maintenance_Logs
GROUP BY work_order_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

/*------------------------------------------------------------
Audit 7.4
Validate Maintenance Types
------------------------------------------------------------*/

SELECT
    maintenance_type,
    COUNT(*) AS record_count
FROM Maintenance_Logs
GROUP BY maintenance_type
ORDER BY record_count DESC;

/*------------------------------------------------------------
Audit 7.5
Validate Priority Level
------------------------------------------------------------*/

SELECT
    MIN(priority_level) AS Min_Priority,
    MAX(priority_level) AS Max_Priority
FROM Maintenance_Logs;

SELECT DISTINCT
    priority_level
FROM Maintenance_Logs
ORDER BY priority_level;

/*------------------------------------------------------------
Audit 7.6
Validate Severity Level
------------------------------------------------------------*/

SELECT
    MIN(severity_level) AS Min_Severity,
    MAX(severity_level) AS Max_Severity
FROM Maintenance_Logs;

SELECT DISTINCT
    severity_level
FROM Maintenance_Logs
ORDER BY severity_level;

/*------------------------------------------------------------
Audit 7.7
Validate Estimated Maintenance Duration
------------------------------------------------------------*/

SELECT
    MIN(estimated_duration_hours) AS Min_Duration,
    MAX(estimated_duration_hours) AS Max_Duration,
    AVG(estimated_duration_hours) AS Avg_Duration
FROM Maintenance_Logs;

SELECT
    maintenance_log_id,
    estimated_duration_hours
FROM Maintenance_Logs
WHERE estimated_duration_hours <= 0
   OR estimated_duration_hours > 24;
   
/*------------------------------------------------------------
Audit 7.8
Validate Boolean Fields
------------------------------------------------------------*/

SELECT DISTINCT
    maintenance_completed,
    inspection_passed
FROM Maintenance_Logs
ORDER BY
    maintenance_completed,
    inspection_passed;
    
SELECT
    maintenance_completed,
    inspection_passed,
    COUNT(*) AS record_count
FROM Maintenance_Logs
GROUP BY
    maintenance_completed,
    inspection_passed
ORDER BY
    maintenance_completed,
    inspection_passed;
    
/*------------------------------------------------------------
Audit 7.9
Check Inspection Passed Before Maintenance Completion
------------------------------------------------------------*/

SELECT
    maintenance_log_id,
    maintenance_completed,
    inspection_passed
FROM Maintenance_Logs
WHERE maintenance_completed = 0
  AND inspection_passed = 1;
  
/*------------------------------------------------------------
Audit 7.10
Validate Maintenance Timeline
------------------------------------------------------------*/

SELECT
    maintenance_log_id,
    maintenance_start,
    maintenance_end
FROM Maintenance_Logs
WHERE maintenance_end <= maintenance_start;

/*------------------------------------------------------------
Audit 7.11
Compare Estimated Duration With Actual Duration
------------------------------------------------------------*/

SELECT
    maintenance_log_id,
    estimated_duration_hours,
    ROUND(
        TIMESTAMPDIFF(
            MINUTE,
            maintenance_start,
            maintenance_end
        ) / 60,
        2
    ) AS Actual_Duration_Hours
FROM Maintenance_Logs
WHERE ABS(
    estimated_duration_hours -
    (
        TIMESTAMPDIFF(
            MINUTE,
            maintenance_start,
            maintenance_end
        ) / 60
    )
) > 0.01;

/*------------------------------------------------------------
Audit 7.12
Actual Maintenance Duration Statistics
------------------------------------------------------------*/

SELECT
    MIN(
        TIMESTAMPDIFF(
            MINUTE,
            maintenance_start,
            maintenance_end
        )
    ) AS Min_Duration_Minutes,

    MAX(
        TIMESTAMPDIFF(
            MINUTE,
            maintenance_start,
            maintenance_end
        )
    ) AS Max_Duration_Minutes,

    AVG(
        TIMESTAMPDIFF(
            MINUTE,
            maintenance_start,
            maintenance_end
        )
    ) AS Avg_Duration_Minutes

FROM Maintenance_Logs;

/*------------------------------------------------------------
Audit 7.13
Validate Aircraft Registration Format
------------------------------------------------------------*/

SELECT
    aircraft_registration
FROM Maintenance_Logs
WHERE aircraft_registration NOT REGEXP '^VT-[A-Z0-9]+$';

/*------------------------------------------------------------
Audit 7.14
Validate Flight Number Format
------------------------------------------------------------*/

SELECT
    flight_number
FROM Maintenance_Logs
WHERE flight_number NOT REGEXP '^[A-Z0-9]{2}-[0-9]{3,4}$';

/*------------------------------------------------------------
Audit 7.15
Inspect Technician and Supervisor Assignments
------------------------------------------------------------*/

SELECT
    COUNT(DISTINCT technician_id) AS Unique_Technicians,
    COUNT(DISTINCT supervisor_id) AS Unique_Supervisors
FROM Maintenance_Logs;

SELECT
    maintenance_log_id,
    technician_id,
    supervisor_id
FROM Maintenance_Logs
WHERE technician_id = supervisor_id;

/*------------------------------------------------------------
Audit 7.16
Check Completed Maintenance Records
------------------------------------------------------------*/

SELECT
    maintenance_completed,
    COUNT(*) AS Record_Count
FROM Maintenance_Logs
GROUP BY maintenance_completed;

SELECT
    maintenance_log_id,
    maintenance_completed,
    maintenance_start,
    maintenance_end
FROM Maintenance_Logs
WHERE maintenance_completed = 1
  AND maintenance_end IS NULL;
  
/*------------------------------------------------------------
DATA QUALITY FINDINGS
------------------------------------------------------------

1. No NULL values were identified in the Maintenance_Logs table.

2. maintenance_log_id values are unique and valid.

3. Six work_order_id values occur twice. These are retained
   because work_order_id is not the primary key and multiple
   maintenance records may belong to the same work order.

4. maintenance_type contains only the value 'Inspection',
   resulting in no meaningful maintenance-type variation.

5. priority_level contains only the value 5, resulting in no
   meaningful priority variation.

6. severity_level contains only the value 3, resulting in no
   meaningful severity variation.

7. estimated_duration_hours contains only the value 32,
   making maintenance duration unrealistic and unsuitable
   for analytical comparison.

8. maintenance_start and maintenance_end contain major
   chronological inconsistencies, including maintenance_end
   occurring before maintenance_start.

9. Calculated maintenance durations contain negative and
   extremely large values, confirming that the original
   maintenance timestamps are unreliable.

10. maintenance_completed contains only the value 0, meaning
    that all maintenance records appear incomplete.

11. inspection_passed also contains only the value 0,
    preventing meaningful inspection-performance analysis.

12. The maintenance timestamps are therefore reconstructed
    using the associated flight's scheduled departure as the
    trusted operational reference.

13. Maintenance categories, priority levels, severity levels,
    durations and completion statuses are reconstructed using
    controlled randomized business rules.

14. Priority and severity are generated with a logical
    relationship so that higher-severity maintenance is more
    likely to receive higher priority.

15. Inspection status is generated based on maintenance
    completion rather than independently.

16. The corrected data will contain meaningful variation while
    maintaining internal business consistency.

------------------------------------------------------------*/

/*------------------------------------------------------------
CLEANING RULE 1
Map maintenance records to their associated flight.

The combination of flight_number and aircraft_registration
is used to identify the appropriate flight instance.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Maintenance_Flight_Mapping;

CREATE TEMPORARY TABLE Temp_Maintenance_Flight_Mapping AS

SELECT
    m.maintenance_log_id,

    (
        SELECT f.scheduled_departure
        FROM Flights f
        WHERE f.flight_number = m.flight_number
          AND f.aircraft_registration = m.aircraft_registration
          AND f.scheduled_departure IS NOT NULL
        ORDER BY
            ABS(
                TIMESTAMPDIFF(
                    SECOND,
                    m.maintenance_start,
                    f.scheduled_departure
                )
            ),
            f.flight_id
        LIMIT 1
    ) AS flight_departure

FROM Maintenance_Logs m;

/*------------------------------------------------------------
CLEANING RULE 2 - FINAL VERSION
Generate randomized maintenance characteristics.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Maintenance_Parameters;

CREATE TEMPORARY TABLE Temp_Maintenance_Parameters AS

SELECT
    maintenance_log_id,

    /* Random value used for maintenance type */
    RAND() AS type_random,

    /* Random value used for severity */
    RAND() AS severity_random,

    /* Random value used for completion */
    RAND() AS completion_random,

    /* Random value used for maintenance end offset */
    RAND() AS end_random

FROM Maintenance_Logs;

ALTER TABLE Temp_Maintenance_Parameters
ADD COLUMN generated_maintenance_type VARCHAR(50),
ADD COLUMN generated_severity INT,
ADD COLUMN generated_completed TINYINT,
ADD COLUMN completion_offset_minutes INT;

/*------------------------------------------------------------
Generate maintenance type.
------------------------------------------------------------*/

UPDATE Temp_Maintenance_Parameters
SET generated_maintenance_type =
    CASE
        WHEN type_random < 0.30
            THEN 'Inspection'
        WHEN type_random < 0.55
            THEN 'Preventive'
        WHEN type_random < 0.75
            THEN 'Corrective'
        WHEN type_random < 0.90
            THEN 'Repair'
        ELSE 'Component Replacement'
    END;


/*------------------------------------------------------------
Generate severity.
------------------------------------------------------------*/

UPDATE Temp_Maintenance_Parameters
SET generated_severity =
    CASE
        WHEN severity_random < 0.25 THEN 1
        WHEN severity_random < 0.50 THEN 2
        WHEN severity_random < 0.80 THEN 3
        WHEN severity_random < 0.95 THEN 4
        ELSE 5
    END;


/*------------------------------------------------------------
Generate completion status.
------------------------------------------------------------*/

UPDATE Temp_Maintenance_Parameters
SET generated_completed =
    CASE
        WHEN completion_random < 0.88 THEN 1
        ELSE 0
    END;


/*------------------------------------------------------------
Generate maintenance completion offset.

120–1440 minutes =
2–24 hours before flight departure.
------------------------------------------------------------*/

UPDATE Temp_Maintenance_Parameters
SET completion_offset_minutes =
    120 + FLOOR(end_random * 1321);
    
/*------------------------------------------------------------
CLEANING RULE 3
Generate priority based on severity.

Lower priority number = higher urgency.

Severity 5 → Priority 1–2
Severity 4 → Priority 1–3
Severity 3 → Priority 2–4
Severity 2 → Priority 3–5
Severity 1 → Priority 4–5
------------------------------------------------------------*/

ALTER TABLE Temp_Maintenance_Parameters
ADD COLUMN generated_priority INT;

UPDATE Temp_Maintenance_Parameters
SET generated_priority =
    CASE
        WHEN generated_severity = 5
            THEN 1 + FLOOR(RAND() * 2)

        WHEN generated_severity = 4
            THEN 1 + FLOOR(RAND() * 3)

        WHEN generated_severity = 3
            THEN 2 + FLOOR(RAND() * 3)

        WHEN generated_severity = 2
            THEN 3 + FLOOR(RAND() * 3)

        ELSE
            4 + FLOOR(RAND() * 2)
    END;
    
/*------------------------------------------------------------
CLEANING RULE 4
Generate estimated maintenance duration according to
maintenance type.
------------------------------------------------------------*/

ALTER TABLE Temp_Maintenance_Parameters
ADD COLUMN generated_estimated_duration INT;

UPDATE Temp_Maintenance_Parameters
SET generated_estimated_duration =
    CASE

        WHEN generated_maintenance_type = 'Inspection'
            THEN 1 + FLOOR(RAND() * 6)

        WHEN generated_maintenance_type = 'Preventive'
            THEN 2 + FLOOR(RAND() * 7)

        WHEN generated_maintenance_type = 'Corrective'
            THEN 3 + FLOOR(RAND() * 10)

        WHEN generated_maintenance_type = 'Repair'
            THEN 4 + FLOOR(RAND() * 13)

        WHEN generated_maintenance_type = 'Component Replacement'
            THEN 6 + FLOOR(RAND() * 15)

    END;
    
/*------------------------------------------------------------
CLEANING RULE 5
Apply generated maintenance characteristics.
------------------------------------------------------------*/

UPDATE Maintenance_Logs m
JOIN Temp_Maintenance_Parameters p
    ON m.maintenance_log_id = p.maintenance_log_id

SET
    m.maintenance_type =
        p.generated_maintenance_type,

    m.severity_level =
        p.generated_severity,

    m.priority_level =
        p.generated_priority,

    m.estimated_duration_hours =
        p.generated_estimated_duration;

/*------------------------------------------------------------
CLEANING RULE 6
Generate maintenance_end.

Business Rule:
Maintenance ends 2–24 hours before scheduled flight
departure.
------------------------------------------------------------*/

UPDATE Maintenance_Logs m
JOIN Temp_Maintenance_Flight_Mapping f
    ON m.maintenance_log_id = f.maintenance_log_id

JOIN Temp_Maintenance_Parameters p
    ON m.maintenance_log_id = p.maintenance_log_id

SET m.maintenance_end =
    DATE_SUB(
        f.flight_departure,
        INTERVAL p.completion_offset_minutes MINUTE
    )

WHERE f.flight_departure IS NOT NULL;

/*------------------------------------------------------------
CLEANING RULE 7
Generate maintenance_start.

Actual maintenance duration is allowed to vary around the
estimated duration.

Approximate range:
80%–120% of estimated duration.
------------------------------------------------------------*/

ALTER TABLE Temp_Maintenance_Parameters
ADD COLUMN actual_duration_minutes INT;

UPDATE Temp_Maintenance_Parameters
SET actual_duration_minutes =
    ROUND(
        generated_estimated_duration
        * (0.80 + RAND() * 0.41)
        * 60
    );

UPDATE Maintenance_Logs m
JOIN Temp_Maintenance_Parameters p
    ON m.maintenance_log_id = p.maintenance_log_id

SET m.maintenance_start =
    DATE_SUB(
        m.maintenance_end,
        INTERVAL p.actual_duration_minutes MINUTE
    )

WHERE m.maintenance_end IS NOT NULL;

/*------------------------------------------------------------
CLEANING RULE 8
Apply maintenance completion status.
------------------------------------------------------------*/

UPDATE Maintenance_Logs m
JOIN Temp_Maintenance_Parameters p
    ON m.maintenance_log_id = p.maintenance_log_id

SET m.maintenance_completed =
    p.generated_completed;
    
/*------------------------------------------------------------
CLEANING RULE 9
Generate inspection result.

Rules:
- Incomplete maintenance → inspection_passed = 0
- Completed maintenance → approximately 95% pass
------------------------------------------------------------*/

UPDATE Maintenance_Logs
SET inspection_passed =
    CASE

        WHEN maintenance_completed = 0
            THEN 0

        WHEN RAND() < 0.95
            THEN 1

        ELSE 0

    END;

/*------------------------------------------------------------
VALIDATION SUMMARY
------------------------------------------------------------*/

SELECT

    /* Maintenance type variation */
    COUNT(DISTINCT maintenance_type)
        AS Maintenance_Type_Count,

    /* Priority range */
    MIN(priority_level)
        AS Min_Priority,

    MAX(priority_level)
        AS Max_Priority,

    /* Severity range */
    MIN(severity_level)
        AS Min_Severity,

    MAX(severity_level)
        AS Max_Severity,

    /* Estimated duration range */
    MIN(estimated_duration_hours)
        AS Min_Estimated_Duration,

    MAX(estimated_duration_hours)
        AS Max_Estimated_Duration,

    /* Timeline validation */
    SUM(
        maintenance_end <= maintenance_start
    ) AS Invalid_Maintenance_Timeline,

    /* Maintenance must end before flight */
    SUM(
        maintenance_end >=
        (
            SELECT f.scheduled_departure
            FROM Flights f
            WHERE f.flight_number = Maintenance_Logs.flight_number
              AND f.aircraft_registration =
                  Maintenance_Logs.aircraft_registration
            LIMIT 1
        )
    ) AS Invalid_Flight_Timing,

    /* Completion values */
    COUNT(DISTINCT maintenance_completed)
        AS Completion_Status_Count,

    /* Inspection values */
    COUNT(DISTINCT inspection_passed)
        AS Inspection_Status_Count,

    /* Impossible inspection state */
    SUM(
        maintenance_completed = 0
        AND inspection_passed = 1
    ) AS Invalid_Inspection_Status

FROM Maintenance_Logs;