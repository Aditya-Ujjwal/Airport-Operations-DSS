/*====================================================================*

			AIRPORT OPERATIONS DECISION SUPPORT SYSTEM
				LEVEL 2 — ADVANCED ANALYSIS

======================================================================

Purpose:
Advanced business analysis using multi-table relationships,
comparative metrics, CTEs, subqueries and analytical SQL.

Focus:
Identify relationships between operational factors and provide
deeper decision-support insights for airport management.

Analysis Range:
Questions 7A.06 – 7A.15

====================================================================*/

USE Airport_Operations_DSS;

/*------------------------------------------------------------*

*Analysis 7B.06*

*Business Question:

*Which flight routes generate the greatest passenger demand
*and delay burden?

*Business Purpose:

*Identify routes with significant passenger traffic and
*operational delay exposure to support route-level monitoring
*and resource planning.

*KPIs:

*1. Total Flights
*2. Total Passengers
*3. Average Passengers per Flight
*4. Delayed Flights
*5. Delay Rate
*6. Average Departure Delay

*------------------------------------------------------------*/

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
    ROUND(AVG(departure_delay_minutes),2) AS avg_departure_delay_minutes
FROM Flights
GROUP BY
    departure_airport,
    arrival_airport
HAVING COUNT(*) >= 5
ORDER BY total_passengers DESC;

/*------------------------------------------------------------*

*Business Insight:

*Among the displayed routes, DEL–JFK handles the highest
*passenger volume with 18,582 passengers across 84 flights.
*DEL–DOH has the highest delay rate at 37.68%, while DEL–LHR
*also shows a relatively high delay rate of 35.14%.

*DSS Relevance:

*High-volume routes with elevated delay rates should receive
*greater operational monitoring because disruptions can affect
*a larger number of passengers.

*Power BI:

*Use a route-level bar chart for passenger volume with delay
*rate available as a tooltip or secondary metric.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7B.07*

*Business Question:

*Which flights combine high passenger occupancy with poor
*operational performance?

*Business Purpose:

*Identify high-demand flights where operational performance
*may require management attention.

*Business Rules:

*High Occupancy = Above Airport Average Occupancy
*Poor Operational Performance = Below Airport Average
*Operational Score

*KPIs:

*1. Flight Number
*2. Airline
*3. Occupancy
*4. Operational Score
*5. Departure Delay
*6. Passengers Onboard

*------------------------------------------------------------*/

SELECT
    f.flight_number,
    f.airline_name,
    f.passengers_onboard,
    ROUND(
        f.occupancy_percentage,
        2
    ) AS occupancy_percentage,
    ROUND(
        f.operational_score,
        2
    ) AS operational_score,
    f.departure_delay_minutes,
    ROUND(
        (
            SELECT AVG(occupancy_percentage)
            FROM Flights
        ),
        2
    ) AS airport_avg_occupancy,
    ROUND(
        (
            SELECT AVG(operational_score)
            FROM Flights
        ),
        2
    ) AS airport_avg_operational_score
FROM Flights f
WHERE f.occupancy_percentage >
      (SELECT AVG(occupancy_percentage) FROM Flights)
  AND f.operational_score <
      (SELECT AVG(operational_score) FROM Flights)
ORDER BY
    f.occupancy_percentage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Only four flights combine above-average occupancy with
*below-average operational performance. SQ-1356 is the most
*notable case, carrying 293 passengers with 86.43% occupancy,
*an operational score of 86.53 and a 30-minute departure delay.

*DSS Relevance:

*These flights represent a small but potentially important
*group for operational monitoring, particularly high-demand
*flights experiencing delays.

*Power BI:

*Use a scatter plot with occupancy on the X-axis and
*operational score on the Y-axis, highlighting flights in
*the high-occupancy/low-performance area.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7B.08*

*Business Question:

*Which airlines generate the greatest baggage-handling workload?

*Business Purpose:

*Identify airlines that contribute the greatest baggage volume
*and baggage weight to airport ground-handling operations.

*KPIs:

*1. Flights with Baggage
*2. Total Baggage
*3. Baggage per Flight
*4. Total Baggage Weight
*5. Average Baggage Weight

*------------------------------------------------------------*/

SELECT

    f.airline_name,

    COUNT(DISTINCT f.flight_id) AS flights_with_baggage,

    COUNT(b.baggage_tag) AS total_baggage,

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

GROUP BY
    f.airline_name

ORDER BY
    total_baggage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Lufthansa generates the highest baggage workload with 290 bags
*and 5,483.85 kg of total baggage weight across 89 flights.
Air France and Singapore Airlines follow with 270 and 255 bags
respectively. Baggage volume per flight remains relatively
consistent across airlines, ranging from 2.77 to 3.26 bags.

*DSS Relevance:

*Airlines with higher total baggage volumes should receive
*greater consideration when planning baggage-handling capacity
*and ground-operation resources.

*Power BI:

*Use a ranked bar chart for total baggage by airline, with
*total baggage weight as a secondary metric.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7B.09*

*Business Question:

*Which aircraft models combine significant flight utilization
*with maintenance activity among their recorded
*maintenance-linked flights?

*Business Purpose:

*Compare aircraft operational activity with the maintenance
*workload recorded against their flight numbers.

*KPIs:

*1. Total Flights
*2. Total Passengers
*3. Average Occupancy
*4. Maintenance-Linked Flights
*5. Maintenance Jobs
*6. Total Maintenance Hours
*7. Average Maintenance Duration

*------------------------------------------------------------*/

WITH Valid_Flight_Model AS
(
    SELECT
        flight_number,
        MAX(aircraft_model) AS aircraft_model

    FROM Flights

    GROUP BY flight_number

    HAVING COUNT(DISTINCT aircraft_model) = 1
),

Flight_Operations AS
(
    SELECT

        f.aircraft_model,

        COUNT(DISTINCT f.flight_id) AS total_flights,

        SUM(f.passengers_onboard) AS total_passengers,

        AVG(f.occupancy_percentage)
            AS avg_occupancy_percentage

    FROM Flights f

    GROUP BY f.aircraft_model
),

Maintenance_Workload AS
(
    SELECT

        vfm.aircraft_model,

        COUNT(DISTINCT m.flight_number)
            AS maintenance_linked_flights,

        COUNT(m.maintenance_log_id)
            AS maintenance_jobs,

        SUM(m.estimated_duration_hours)
            AS total_maintenance_hours,

        AVG(m.estimated_duration_hours)
            AS avg_maintenance_duration_hours

    FROM Maintenance_Logs m

    INNER JOIN Valid_Flight_Model vfm

        ON m.flight_number = vfm.flight_number

    GROUP BY
        vfm.aircraft_model
)

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
        ROUND(mw.total_maintenance_hours, 2),
        0
    ) AS total_maintenance_hours,

    COALESCE(
        ROUND(mw.avg_maintenance_duration_hours, 2),
        0
    ) AS avg_maintenance_duration_hours

FROM Flight_Operations fo

LEFT JOIN Maintenance_Workload mw

    ON fo.aircraft_model = mw.aircraft_model

ORDER BY
    fo.total_flights DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*B787 has the highest operational utilization with 286 flights
*and 62,813 passengers. A320 records the highest maintenance
*workload with 106 maintenance jobs and 685 maintenance hours,
*while B737 has the highest average occupancy at 87.53%.

*DSS Relevance:

*B787 should receive attention for operational utilization,
*while A320 requires greater maintenance-planning attention
*because of its highest recorded maintenance workload.

*Power BI:

*Use a scatter chart comparing total flights with total
*maintenance hours by aircraft model, with aircraft model
*as the category.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7B.10*

*Business Question:

*Which departure shifts generate the greatest combined airport
*workload across flights, passengers, baggage and security?

*Business Purpose:

*Identify time periods requiring greater operational resources
*by combining flight, passenger, baggage and security activity.

*KPIs:

*1. Total Flights
*2. Total Passengers
*3. Total Baggage
*4. Total Security Screenings
*5. Average Screening Duration

*------------------------------------------------------------*/

WITH Flight_Workload AS
(
    SELECT

        departure_shift,

        COUNT(*) AS total_flights,

        SUM(passengers_onboard) AS total_passengers

    FROM Flights

    GROUP BY departure_shift
),

Baggage_Workload AS
(
    SELECT

        f.departure_shift,

        COUNT(b.baggage_tag) AS total_baggage

    FROM Flights f

    INNER JOIN Baggage b
        ON f.flight_number = b.flight_number

    GROUP BY f.departure_shift
),

Security_Workload AS
(
    SELECT

        f.departure_shift,

        COUNT(s.screening_id) AS total_screenings,

        ROUND(
            AVG(s.screening_duration_minutes),
            2
        ) AS avg_screening_duration_minutes

    FROM Flights f

    INNER JOIN Passengers p
        ON f.flight_number = p.flight_number

    INNER JOIN Security_Screening s
        ON p.passport_number = s.passport_number

    GROUP BY f.departure_shift
)

SELECT

    fw.departure_shift,

    fw.total_flights,

    fw.total_passengers,

    COALESCE(bw.total_baggage, 0) AS total_baggage,

    COALESCE(sw.total_screenings, 0) AS recorded_screenings,

    COALESCE(
        sw.avg_screening_duration_minutes,
        0
    ) AS avg_screening_duration_minutes

FROM Flight_Workload fw

LEFT JOIN Baggage_Workload bw
    ON fw.departure_shift = bw.departure_shift

LEFT JOIN Security_Workload sw
    ON fw.departure_shift = sw.departure_shift

ORDER BY
    fw.total_passengers DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Evening represents the highest overall operational workload,
with 291 flights, 63,059 passengers and 847 baggage records.
Morning follows with 268 flights, 57,724 passengers and
758 baggage records. Afternoon has the lowest flight and
passenger volume, while its average screening duration is
the highest at 28.36 minutes.

*DSS Relevance:

*Evening should receive greater operational resource attention
because it handles the highest flight, passenger and baggage
volume. Afternoon may require screening-process attention due
to its higher average screening duration.

Based on screening records available for 45.3% of flights.

*Power BI:

*Use a clustered column chart for flights, passengers and
baggage by departure shift, with average screening duration
shown as a secondary KPI.

*------------------------------------------------------------*/