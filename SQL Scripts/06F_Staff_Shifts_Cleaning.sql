USE Airport_Operations_DSS;

/*------------------------------------------------------------
Audit 6F.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(staff_id IS NULL) AS staff_id_nulls,
    SUM(staff_name IS NULL) AS staff_name_nulls,
    SUM(department IS NULL) AS department_nulls,
    SUM(job_role IS NULL) AS job_role_nulls,
    SUM(joining_date IS NULL) AS joining_date_nulls,
    SUM(shift_start IS NULL) AS shift_start_nulls,
    SUM(shift_end IS NULL) AS shift_end_nulls,
    SUM(terminal IS NULL) AS terminal_nulls,
    SUM(gate_number IS NULL) AS gate_number_nulls,
    SUM(supervisor_id IS NULL) AS supervisor_id_nulls,
    SUM(shift_hours IS NULL) AS shift_hours_nulls,
    SUM(overtime_flag IS NULL) AS overtime_flag_nulls,
    SUM(last_training_date IS NULL) AS training_date_nulls,
    SUM(preferred_language IS NULL) AS language_nulls
FROM Staff_Shifts;

/*------------------------------------------------------------
Audit 6F.2
Check Duplicate Staff IDs
------------------------------------------------------------*/

SELECT
    staff_id,
    COUNT(*) AS occurrence_count
FROM Staff_Shifts
GROUP BY staff_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6F.3
Validate Departments
------------------------------------------------------------*/

SELECT
    department,
    COUNT(*) AS staff_count
FROM Staff_Shifts
GROUP BY department
ORDER BY staff_count DESC;

/*------------------------------------------------------------
Audit 6F.4
Validate Job Roles
------------------------------------------------------------*/

SELECT
    job_role,
    COUNT(*) AS staff_count
FROM Staff_Shifts
GROUP BY job_role
ORDER BY staff_count DESC;

/*------------------------------------------------------------
Audit 6F.5
Validate Preferred Languages
------------------------------------------------------------*/

SELECT
    preferred_language,
    COUNT(*) AS staff_count
FROM Staff_Shifts
GROUP BY preferred_language
ORDER BY staff_count DESC;

/*------------------------------------------------------------
Audit 6F.6
Validate Overtime Flag
------------------------------------------------------------*/

SELECT DISTINCT
    overtime_flag
FROM Staff_Shifts
ORDER BY overtime_flag;

/*------------------------------------------------------------
Audit 6F.7
Check Shift Hours Range
------------------------------------------------------------*/

SELECT
    MIN(shift_hours) AS Min_Shift_Hours,
    MAX(shift_hours) AS Max_Shift_Hours
FROM Staff_Shifts;

/*------------------------------------------------------------
Audit 6F.7B
Identify Invalid Shift Hours
------------------------------------------------------------*/

SELECT
    staff_id,
    shift_hours
FROM Staff_Shifts
WHERE shift_hours <= 0
   OR shift_hours > 24;
   
   
/*------------------------------------------------------------
Audit 6F.8
Validate Shift Start and End Times
------------------------------------------------------------*/

SELECT
    staff_id,
    shift_start,
    shift_end
FROM Staff_Shifts
WHERE shift_end <= shift_start;

/*------------------------------------------------------------
Audit 6F.9
Compare Recorded Shift Hours With Timestamp Difference
------------------------------------------------------------*/

SELECT
    staff_id,
    shift_start,
    shift_end,
    shift_hours,
    ROUND(
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        ) / 60,
        2
    ) AS Calculated_Shift_Hours
FROM Staff_Shifts
WHERE ABS(
    shift_hours -
    (
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        ) / 60
    )
) > 0.01;

/*------------------------------------------------------------
Audit 6F.10
Validate Shift Against Joining Date
------------------------------------------------------------*/

SELECT
    staff_id,
    joining_date,
    shift_start
FROM Staff_Shifts
WHERE DATE(shift_start) < joining_date;

/*------------------------------------------------------------
Audit 6F.11
Validate Training Date
------------------------------------------------------------*/

SELECT
    staff_id,
    joining_date,
    last_training_date
FROM Staff_Shifts
WHERE last_training_date < joining_date;

/*------------------------------------------------------------
Audit 6F.12
Compare Overtime Flag With Shift Hours
------------------------------------------------------------*/

SELECT
    overtime_flag,
    MIN(shift_hours) AS Min_Hours,
    MAX(shift_hours) AS Max_Hours,
    AVG(shift_hours) AS Avg_Hours,
    COUNT(*) AS Staff_Count
FROM Staff_Shifts
GROUP BY overtime_flag;

/*------------------------------------------------------------
Audit 6F.12B
Identify Long Shifts Without Overtime
------------------------------------------------------------*/

SELECT
    staff_id,
    shift_hours,
    overtime_flag
FROM Staff_Shifts
WHERE shift_hours > 8
  AND overtime_flag = 0;
  
/*------------------------------------------------------------
Audit 6F.13
Inspect Terminal and Gate Combinations
------------------------------------------------------------*/

SELECT
    terminal,
    gate_number,
    COUNT(*) AS staff_count
FROM Staff_Shifts
GROUP BY terminal, gate_number
ORDER BY terminal, gate_number;

/*------------------------------------------------------------
Audit 6F.14
Check Self-Supervision
------------------------------------------------------------*/

SELECT
    staff_id,
    supervisor_id
FROM Staff_Shifts
WHERE staff_id = supervisor_id;

/*------------------------------------------------------------
Audit 6F.14B
Check Missing Supervisors
------------------------------------------------------------*/

SELECT COUNT(*) AS Missing_Supervisor
FROM Staff_Shifts
WHERE supervisor_id IS NULL;

/*------------------------------------------------------------
Audit 6F.15
Shift Duration Statistics
------------------------------------------------------------*/
SELECT MAX(scheduled_departure)
FROM Flights;
SELECT
    MIN(
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        )
    ) AS Min_Duration_Minutes,

    MAX(
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        )
    ) AS Max_Duration_Minutes,

    AVG(
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        )
    ) AS Avg_Duration_Minutes
FROM Staff_Shifts;

/*------------------------------------------------------------
Audit 6F.16
Inspect Shift Timeline
------------------------------------------------------------*/

SELECT
    staff_id,
    joining_date,
    shift_start,
    shift_end,
    shift_hours
FROM Staff_Shifts
LIMIT 20;

/*------------------------------------------------------------
Data Quality Findings
------------------------------------------------------------

1. Staff identifiers and core employee information were found
   to be structurally valid.

2. Major inconsistencies were identified in the shift timestamp
   fields.

3. Multiple records contain shift_end timestamps occurring
   before shift_start timestamps.

4. The calculated shift durations range from negative values
   to extremely large values, demonstrating that the original
   shift timestamps are unreliable.

5. The recorded shift_hours value does not consistently match
   the difference between shift_start and shift_end.

6. Several staff members have shift_start dates occurring
   before their joining_date.

7. Multiple last_training_date values occur before the
   corresponding joining_date, which is logically invalid.

8. The timestamp fields appear to have been generated
   independently rather than according to a coherent
   employee-work schedule.

9. The original shift timestamps are therefore not used as
   reference values during cleaning.

10. joining_date is retained as the trusted employee timeline
    starting point.

11. The maximum scheduled departure date in the Flights table
    (2024-12-30) is used as the upper boundary of the
    operational dataset.

12. New shift dates, start times and durations are generated
    using randomized but controlled business rules.

13. shift_hours is reconstructed from the generated shift
    duration.

14. overtime_flag is recalculated from the generated shift
    duration.

15. last_training_date is reconstructed between joining_date
    and the generated shift date.

16. The corrected employee timeline follows:

        Joining Date
             ↓
        Training Date
             ↓
        Shift Start
             ↓
        Shift End

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Generate randomized staff shift parameters.

Business Rules:
- Shift date: joining_date → 2024-12-30
- Shift start: 06:00 → 22:45
- Shift duration: 6 → 10 hours
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Staff_Shift_Timing;

CREATE TEMPORARY TABLE Temp_Staff_Shift_Timing AS

SELECT
    s.staff_id,
    s.joining_date,

    /* Random shift date between joining date
       and maximum operational date */
    DATE_ADD(
        s.joining_date,
        INTERVAL FLOOR(
            RAND() *
            (
                DATEDIFF(
                    '2024-12-30',
                    s.joining_date
                ) + 1
            )
        ) DAY
    ) AS shift_date,

    /* Random starting hour: 06–22 */
    (6 + FLOOR(RAND() * 17)) AS start_hour,

    /* Start minute: 00, 15, 30 or 45 */
    (FLOOR(RAND() * 4) * 15) AS start_minute,

    /* Random shift duration: 6–10 hours */
    (6 + FLOOR(RAND() * 5)) AS shift_hours

FROM Staff_Shifts s
WHERE s.joining_date <= '2024-12-30';

/*------------------------------------------------------------
Cleaning Rule 2
Generate a valid last training date.

Business Rule:
last_training_date must fall between joining_date and
the generated shift date.
------------------------------------------------------------*/

ALTER TABLE Temp_Staff_Shift_Timing
ADD COLUMN training_date DATE;

UPDATE Temp_Staff_Shift_Timing
SET training_date =
    DATE_ADD(
        joining_date,
        INTERVAL FLOOR(
            RAND() *
            (
                DATEDIFF(
                    shift_date,
                    joining_date
                ) + 1
            )
        ) DAY
    );
    
/*------------------------------------------------------------
Cleaning Rule 3
Reconstruct shift_start.
------------------------------------------------------------*/

UPDATE Staff_Shifts s
JOIN Temp_Staff_Shift_Timing t
    ON s.staff_id = t.staff_id

SET s.shift_start =
    DATE_ADD(
        DATE_ADD(
            t.shift_date,
            INTERVAL t.start_hour HOUR
        ),
        INTERVAL t.start_minute MINUTE
    );
    
/*------------------------------------------------------------
Cleaning Rule 4
Reconstruct shift_end from shift_start and shift duration.
------------------------------------------------------------*/

UPDATE Staff_Shifts s
JOIN Temp_Staff_Shift_Timing t
    ON s.staff_id = t.staff_id

SET s.shift_end =
    DATE_ADD(
        s.shift_start,
        INTERVAL t.shift_hours HOUR
    );

/*------------------------------------------------------------
Cleaning Rule 5
Calculate shift_hours from shift_start and shift_end.
------------------------------------------------------------*/

UPDATE Staff_Shifts
SET shift_hours =
    ROUND(
        TIMESTAMPDIFF(
            MINUTE,
            shift_start,
            shift_end
        ) / 60,
        2
    )
WHERE shift_start IS NOT NULL
  AND shift_end IS NOT NULL;
  
/*------------------------------------------------------------
Cleaning Rule 6
Recalculate overtime flag.

Business Rule:
> 8 hours = overtime
<= 8 hours = normal shift
------------------------------------------------------------*/

UPDATE Staff_Shifts
SET overtime_flag =
    CASE
        WHEN shift_hours > 8 THEN 1
        ELSE 0
    END;

/*------------------------------------------------------------
Cleaning Rule 7
Update last_training_date using the generated valid date.
------------------------------------------------------------*/

UPDATE Staff_Shifts s
JOIN Temp_Staff_Shift_Timing t
    ON s.staff_id = t.staff_id

SET s.last_training_date = t.training_date;

/*------------------------------------------------------------
Cleanup temporary timing table.
------------------------------------------------------------*/

DROP TEMPORARY TABLE IF EXISTS Temp_Staff_Shift_Timing;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(
        DATE(shift_start) < joining_date
    ) AS Invalid_Shift_Date,

    SUM(
        shift_end <= shift_start
    ) AS Invalid_Shift_Timeline,

    SUM(
        shift_hours NOT BETWEEN 6 AND 10
    ) AS Invalid_Shift_Hours,

    SUM(
        ABS(
            shift_hours -
            (
                TIMESTAMPDIFF(
                    MINUTE,
                    shift_start,
                    shift_end
                ) / 60
            )
        ) > 0.01
    ) AS Shift_Hour_Mismatches,

    SUM(
        last_training_date < joining_date
    ) AS Invalid_Training_Date,

    SUM(
        overtime_flag <>
        CASE
            WHEN shift_hours > 8 THEN 1
            ELSE 0
        END
    ) AS Overtime_Flag_Mismatches

FROM Staff_Shifts;