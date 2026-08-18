USE Airport_Operations_DSS;

/*------------------------------------------------------------
Audit 6B.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(first_name IS NULL) AS first_name_nulls,
    SUM(last_name IS NULL) AS last_name_nulls,
    SUM(passport_number IS NULL) AS passport_nulls,
    SUM(flight_number IS NULL) AS flight_nulls,
    SUM(email IS NULL) AS email_nulls,
    SUM(phone_number IS NULL) AS phone_nulls,
    SUM(age IS NULL) AS age_nulls
FROM Passengers;

/*------------------------------------------------------------
Audit 6B.2
Check Duplicate Passenger IDs
------------------------------------------------------------*/

SELECT
    passenger_id,
    COUNT(*) AS occurrence_count
FROM Passengers
GROUP BY passenger_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6B.3
Check Passport Reuse
------------------------------------------------------------*/

SELECT
    passport_number,
    COUNT(*) AS Trips
FROM Passengers
GROUP BY passport_number
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 6B.4
Check Invalid Passenger Age
------------------------------------------------------------*/

SELECT *
FROM Passengers
WHERE age < 0
   OR age > 120;
   
   /*------------------------------------------------------------
Audit 6B.5
Validate Gender Values
------------------------------------------------------------*/

SELECT DISTINCT gender
FROM Passengers;

/*------------------------------------------------------------
Audit 6B.6
Validate Travel Class
------------------------------------------------------------*/

SELECT DISTINCT travel_class
FROM Passengers;

/*------------------------------------------------------------
Audit 6B.7
Validate Cabin Class
------------------------------------------------------------*/

SELECT DISTINCT cabin_class
FROM Passengers;

/*------------------------------------------------------------
Audit 6B.8
Validate Passenger Timeline
------------------------------------------------------------*/

SELECT *
FROM Passengers
WHERE boarding_time < checkin_time;

/*------------------------------------------------------------
Audit 6B.9
Check Invalid Baggage Count
------------------------------------------------------------*/

SELECT *
FROM Passengers
WHERE baggage_count < 0;

/*------------------------------------------------------------
Audit 6B.10
Validate Passenger Score
------------------------------------------------------------*/

SELECT
MIN(passenger_score),
MAX(passenger_score)
FROM Passengers;

/*------------------------------------------------------------
Audit 6B.11
Validate Boolean Values
------------------------------------------------------------*/

SELECT DISTINCT special_assistance
FROM Passengers;

/*------------------------------------------------------------
Findings
--------------------------------------------------------------

1. Passenger IDs are unique.
   No duplicate passenger records were found.

2. Passport numbers are reused across multiple records.
   This represents repeat travel by the same passenger and is
   considered valid.

3. Eleven passenger records contain NULL values for age.
   Since Date of Birth is available, missing ages are
   calculated using the latest scheduled departure date
   available in the Flights table as the reference date.

4. Passenger score contains negative values.
   Based on the defined business rule, valid passenger scores
   must fall between 0 and 5. Negative scores are corrected to
   the minimum valid score (0).

5. Passenger timelines are valid.
   Boarding time is never earlier than check-in time.

6. Gender, travel class, cabin class, and boolean fields are
   already standardized and require no cleaning.

------------------------------------------------------------*/

/*------------------------------------------------------------
Cleaning Rule 1
Calculate missing passenger ages using the latest scheduled
departure date available in the Flights table.
------------------------------------------------------------*/

UPDATE Passengers
SET age = TIMESTAMPDIFF(
            YEAR,
            date_of_birth,
            (SELECT MAX(DATE(scheduled_departure))
             FROM Flights)
          )
WHERE age IS NULL
  AND date_of_birth IS NOT NULL;

/*------------------------------------------------------------
Cleaning Rule 2
Passenger score cannot be negative.
Replace negative scores with 0.
------------------------------------------------------------*/

UPDATE Passengers
SET passenger_score = 0
WHERE passenger_score < 0;

/*------------------------------------------------------------
Validation Summary
------------------------------------------------------------*/

SELECT
    SUM(age IS NULL) AS Remaining_Null_Ages,
    SUM(passenger_score < 0) AS Negative_Passenger_Scores
FROM Passengers;