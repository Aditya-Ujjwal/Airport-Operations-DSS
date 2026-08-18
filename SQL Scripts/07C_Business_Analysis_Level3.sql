/*====================================================================*

			AIRPORT OPERATIONS DECISION SUPPORT SYSTEM
				LEVEL 3 — ADVANCED ANALYSIS

======================================================================

Purpose:
Advanced business analysis using multi-table relationships,
comparative metrics, CTEs, subqueries and analytical SQL.

Focus:
Identify relationships between operational factors and provide
deeper decision-support insights for airport management.

Analysis Range:
Questions 7A.11 – 7A.20

====================================================================*/

USE Airport_Operations_DSS;

/*------------------------------------------------------------*

*Analysis 7C.11*

*Business Question:

*Which delay reasons create the greatest passenger impact
*at the airport?

*Business Purpose:

*Identify the operational causes of delays that affect the
*largest number of passengers, rather than simply counting
*the number of delayed flights.

*KPIs:

*1. Delayed Flights
*2. Passengers Affected
*3. Average Delay
*4. Total Delay Minutes
*5. Passenger Impact Percentage

*------------------------------------------------------------*/

WITH Delay_Analysis AS
(
    SELECT

        delay_reason,

        COUNT(*) AS delayed_flights,

        SUM(passengers_onboard)
            AS passengers_affected,

        AVG(departure_delay_minutes)
            AS avg_delay_minutes,

        SUM(departure_delay_minutes)
            AS total_delay_minutes

    FROM Flights

    WHERE departure_delay_minutes > 0

      AND delay_reason IS NOT NULL

    GROUP BY
        delay_reason
)

SELECT

    delay_reason,

    delayed_flights,

    passengers_affected,

    ROUND(
        avg_delay_minutes,
        2
    ) AS avg_delay_minutes,

    total_delay_minutes,

    ROUND(
        100.0 * passengers_affected /
        SUM(passengers_affected) OVER (),
        2
    ) AS passenger_impact_percentage

FROM Delay_Analysis

ORDER BY
    passengers_affected DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*ATC delays have the largest passenger impact, affecting
15,672 passengers and accounting for 23.33% of all delayed
passengers. TECH delays follow at 21.73%, while WX has the
lowest passenger impact at 17.64%.

*DSS Relevance:

*ATC and TECH-related delays should receive priority for
operational improvement because together they affect
approximately 45% of delayed passengers.

*Power BI:

*Use a ranked bar chart showing passenger impact percentage
by delay reason, with passenger count as a tooltip.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.12*

*Business Question:

*Which airlines perform below the airport-wide operational
*benchmark across multiple KPIs?

*Business Purpose:

*Identify airlines that consistently perform below airport
*benchmarks and may require targeted operational attention.

*KPIs:

*1. Delay Rate
*2. Average Departure Delay
*3. Operational Score
*4. Occupancy
*5. Number of Below-Benchmark KPIs

*------------------------------------------------------------*/

WITH Airline_Performance AS
(
    SELECT
        airline_name,
        COUNT(*) AS total_flights,
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
        ) AS delay_rate,
        AVG(departure_delay_minutes)
            AS avg_departure_delay,
        AVG(operational_score)
            AS avg_operational_score,
        AVG(occupancy_percentage)
            AS avg_occupancy
    FROM Flights
    GROUP BY airline_name
),
Airport_Benchmarks AS
(
    SELECT
        AVG(
            departure_delay_minutes
        ) AS airport_avg_delay,
        AVG(
            operational_score
        ) AS airport_avg_operational_score,
        AVG(
            occupancy_percentage
        ) AS airport_avg_occupancy,
        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS airport_delay_rate
    FROM Flights
)
SELECT
    a.airline_name,
    a.total_flights,
    ROUND(a.delay_rate, 2)
        AS delay_rate,
    ROUND(
        a.avg_departure_delay,
        2
    ) AS avg_departure_delay,
    ROUND(
        a.avg_operational_score,
        2
    ) AS avg_operational_score,
    ROUND(
        a.avg_occupancy,
        2
    ) AS avg_occupancy,
    ROUND(
        b.airport_delay_rate,
        2
    ) AS airport_avg_delay_rate,
    ROUND(
        b.airport_avg_delay,
        2
    ) AS airport_avg_departure_delay,
    ROUND(
        b.airport_avg_operational_score,
        2
    ) AS airport_avg_operational_score,
    ROUND(
        b.airport_avg_occupancy,
        2
    ) AS airport_avg_occupancy,
    (
        CASE
            WHEN a.delay_rate >
                 b.airport_delay_rate
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN a.avg_departure_delay >
                 b.airport_avg_delay
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN a.avg_operational_score <
                 b.airport_avg_operational_score
            THEN 1
            ELSE 0
        END
        +
        CASE
            WHEN a.avg_occupancy <
                 b.airport_avg_occupancy
            THEN 1
            ELSE 0
        END
    ) AS below_benchmark_kpis
FROM Airline_Performance a
CROSS JOIN Airport_Benchmarks b
ORDER BY
    below_benchmark_kpis DESC,
    delay_rate DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Singapore Airlines and Emirates are the only airlines below
the airport benchmark across all four KPIs. Air India falls
below benchmark in three areas, while SpiceJet, Lufthansa,
IndiGo, Air France, KLM and Air India Express fall below
benchmark in two areas.

*DSS Relevance:

*Singapore Airlines and Emirates should receive the highest
priority for operational review, followed by Air India, based
on the number of KPIs performing below the airport benchmark.

*Power BI:

*Use a ranked bar chart showing below-benchmark KPI count by
airline, with conditional formatting to highlight higher
priority airlines.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.13*

*Business Question:

*Which airlines have the greatest passenger exposure to
*operationally underperforming flights?

*Business Purpose:

*Identify airlines where a significant number of passengers
*are travelling on flights with below-average operational
*performance.

*Business Rules:

*Underperforming Flight =
*Operational Score below the airport-wide average.

*KPIs:

*1. Total Flights
*2. Underperforming Flights
*3. Passengers on Underperforming Flights
*4. Percentage of Passengers Affected
*5. Average Operational Score

*------------------------------------------------------------*/

WITH Airport_Benchmark AS
(
    SELECT
        AVG(operational_score) AS avg_operational_score
    FROM Flights
),
Airline_Total AS
(
    SELECT
        airline_name,
        COUNT(*) AS total_flights,
        SUM(passengers_onboard) AS total_passengers
    FROM Flights
    GROUP BY airline_name
),
Airline_Underperforming AS
(
    SELECT
        f.airline_name,
        COUNT(*) AS underperforming_flights,
        SUM(f.passengers_onboard)
            AS passengers_on_underperforming_flights,
        AVG(f.operational_score)
            AS avg_underperforming_score
    FROM Flights f
    CROSS JOIN Airport_Benchmark b
    WHERE f.operational_score <
          b.avg_operational_score
    GROUP BY f.airline_name
)
SELECT
    a.airline_name,
    a.total_flights,
    a.total_passengers,
    COALESCE(
        u.underperforming_flights,
        0
    ) AS underperforming_flights,
    COALESCE(
        u.passengers_on_underperforming_flights,
        0
    ) AS passengers_on_underperforming_flights,
    ROUND(
        100.0 *
        COALESCE(
            u.passengers_on_underperforming_flights,
            0
        ) / NULLIF(a.total_passengers, 0),
        2
    ) AS passenger_exposure_percentage,
    ROUND(
        COALESCE(
            u.avg_underperforming_score,
            0
        ),
        2
    ) AS avg_underperforming_score
FROM Airline_Total a
LEFT JOIN Airline_Underperforming u
    ON a.airline_name = u.airline_name
ORDER BY
    passenger_exposure_percentage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Singapore Airlines has the highest passenger exposure to
underperforming flights, with 57.49% of its passengers
travelling on flights below the airport operational benchmark.
Air India Express follows at 54.92%, while Vistara has the
lowest exposure at 33.27%.

*DSS Relevance:

*Singapore Airlines and Air India Express should receive
greater operational attention because a larger proportion of
their passengers are exposed to below-benchmark flights.

*Power BI:

*Use a ranked bar chart showing passenger exposure percentage
by airline, with passengers affected shown as a tooltip.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.14*

*Business Question:

*Which departure hours experience the greatest operational
*pressure based on flight volume, passenger demand and
*occupancy?

*Business Purpose:

*Identify peak operating hours that may require greater
*airport staffing, gate availability and ground-operation
*resources.

*KPIs:

*1. Flight Count
*2. Total Passengers
*3. Average Passengers per Flight
*4. Average Occupancy
*5. Passenger Traffic Share
*6. Passenger Volume Rank

*------------------------------------------------------------*/

WITH Hourly_Workload AS
(
    SELECT
        HOUR(scheduled_departure) AS departure_hour,
        COUNT(*) AS total_flights,
        SUM(passengers_onboard) AS total_passengers,
        AVG(passengers_onboard)
            AS avg_passengers_per_flight,
        AVG(occupancy_percentage)
            AS avg_occupancy_percentage
    FROM Flights
    GROUP BY
        HOUR(scheduled_departure)
)
SELECT
    departure_hour,
    total_flights,
    total_passengers,
    ROUND(
        avg_passengers_per_flight,
        2
    ) AS avg_passengers_per_flight,
    ROUND(
        avg_occupancy_percentage,
        2
    ) AS avg_occupancy_percentage,
    ROUND(
        100.0 * total_passengers /
        SUM(total_passengers) OVER (),
        2
    ) AS passenger_traffic_share_percentage,

    RANK() OVER (
        ORDER BY total_passengers DESC
    ) AS passenger_volume_rank
FROM Hourly_Workload
ORDER BY
    departure_hour;


/*------------------------------------------------------------*

*Business Insight:

*17:00 is the highest passenger-volume period with 11,273
*passengers across 50 flights, accounting for 5.19% of total
*passenger traffic. 21:00 ranks second with 10,636 passengers
*and 47 flights, while 13:00 has the lowest passenger volume
*among the observed hours at 7,476 passengers.

*DSS Relevance:

*The 17:00 and 21:00 periods should receive greater resource
*attention because they combine high flight volume with high
*passenger demand.

*Power BI:

*Use a 24-hour workload column chart with passenger volume and
*flight count, with peak hours highlighted.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.15*

*Business Question:

*Which airlines should management prioritize for operational
*improvement based on delay performance, passenger exposure
*and operational score?

*Business Purpose:

*Create a transparent operational-priority classification by
*combining airline delay performance, passenger exposure to
*underperforming flights and overall operational performance.

*Scoring Rules:

*+1  Delay Rate > Airport Average Delay Rate
*+1  Passenger Exposure > Average Airline Exposure
*+1  Operational Score < Airport Average Operational Score

*Priority:

*3 Points     -> High Priority
*2 Points     -> Medium Priority
*0–1 Points   -> Low Priority

*------------------------------------------------------------*/

WITH Airport_Benchmarks AS
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

        AVG(operational_score) AS airport_operational_score

    FROM Flights
),

Airline_Performance AS
(
    SELECT

        airline_name,

        COUNT(*) AS total_flights,

        SUM(passengers_onboard) AS total_passengers,

        100.0 *
        SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS delay_rate,

        AVG(operational_score) AS avg_operational_score

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

Average_Exposure AS
(
    SELECT
        AVG(passenger_exposure_percentage)
        AS avg_airline_exposure

    FROM Airline_Exposure
),

Scored_Airlines AS
(
    SELECT

        a.airline_name,

        a.total_flights,

        a.total_passengers,

        a.delay_rate,

        e.passenger_exposure_percentage,

        a.avg_operational_score,

        (
            CASE
                WHEN a.delay_rate > b.airport_delay_rate
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN e.passenger_exposure_percentage >
                     x.avg_airline_exposure
                THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN a.avg_operational_score <
                     b.airport_operational_score
                THEN 1
                ELSE 0
            END
        ) AS priority_score

    FROM Airline_Performance a

    CROSS JOIN Airport_Benchmarks b

    CROSS JOIN Average_Exposure x

    INNER JOIN Airline_Exposure e
        ON a.airline_name = e.airline_name
)

SELECT

    airline_name,

    total_flights,

    total_passengers,

    ROUND(
        delay_rate,
        2
    ) AS delay_rate,

    ROUND(
        passenger_exposure_percentage,
        2
    ) AS passenger_exposure_percentage,

    ROUND(
        avg_operational_score,
        2
    ) AS avg_operational_score,

    priority_score,

    CASE
        WHEN priority_score = 3
            THEN 'High Priority'

        WHEN priority_score = 2
            THEN 'Medium Priority'

        ELSE 'Low Priority'

    END AS management_priority

FROM Scored_Airlines

ORDER BY
    priority_score DESC,
    passenger_exposure_percentage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Singapore Airlines and Emirates receive the highest management
priority, each scoring 3 on the operational-priority framework.
Singapore Airlines has the highest delay rate (36.17%) and
passenger exposure (57.49%), while Emirates also exceeds the
airport benchmarks across all three priority factors.

*DSS Relevance:

*Singapore Airlines and Emirates should be prioritized for
operational review, followed by Air India Express, British
Airways and Air France, which receive a medium-priority score.

*Power BI:

*Use a management-priority matrix or ranked bar chart showing
airline, priority score and priority category.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.16*

*Business Question:

*Which passenger groups generate the greatest passenger-service
*requirements?

*Business Purpose:

*Identify passenger groups with higher demand for special
*assistance to support passenger-service staffing and planning.

*KPIs:

*1. Total Passengers
*2. Special Assistance Passengers
*3. Special Assistance Rate

*------------------------------------------------------------*/
select * from staff_shifts;
SELECT
    travel_class,
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
    ) AS special_assistance_rate_percentage
FROM Passengers
GROUP BY
    travel_class
ORDER BY
    special_assistance_rate_percentage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Economy passengers have the higher special-assistance rate at
21.34%, compared with 19.97% for Business passengers. Economy
also has slightly more passengers requiring assistance overall
(262 vs 254).

*DSS Relevance:

*Passenger-service planning should account for the higher
assistance requirement rate among Economy passengers when
allocating support resources.

*Power BI:

*Use a clustered column chart comparing total passengers and
special-assistance passengers by travel class, with assistance
rate as a tooltip.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.17*

*Business Question:

*Which maintenance severity levels create the greatest
*workload and inspection risk?

*Business Purpose:

*Identify maintenance severity levels that require greater
*maintenance capacity and closer quality-control attention.

*KPIs:

*1. Maintenance Jobs
*2. Total Maintenance Hours
*3. Average Maintenance Duration
*4. Completion Rate
*5. Inspection Pass Rate

*------------------------------------------------------------*/

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

GROUP BY severity_level

ORDER BY
    severity_level;
    
/*------------------------------------------------------------*

*Business Insight:

*Severity Level 3 generates the highest maintenance workload
*with 137 jobs and 871 maintenance hours. Severity Level 5
*has the lowest volume but the lowest completion rate (80.00%)
*and inspection pass rate (73.33%).

*DSS Relevance:

*Severity Level 3 should receive the greatest maintenance
*capacity, while Level 5 requires closer quality-control
*attention because of its lower completion and inspection
*pass rates.

*Power BI:

*Use a combo chart showing maintenance hours by severity
*with inspection pass rate as a secondary metric.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.18*

*Business Question:

*Which maintenance types consume the most maintenance resources
*and require greater operational attention?

*Business Purpose:

*Identify maintenance activities that generate the greatest
*workload and evaluate their completion and inspection outcomes.

*KPIs:

*1. Maintenance Jobs
*2. Total Maintenance Hours
*3. Average Maintenance Duration
*4. Completion Rate
*5. Inspection Pass Rate

*------------------------------------------------------------*/

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

GROUP BY
    maintenance_type

ORDER BY
    total_maintenance_hours DESC;

/*------------------------------------------------------------*

*Business Insight:

*Inspection has the highest maintenance volume with 139 jobs,
*while Corrective maintenance consumes the most total time at
*609 hours. Component Replacement has the longest average
*duration at 13.13 hours per job, indicating more time-intensive
*individual tasks.

*DSS Relevance:

*Inspection requires attention for workload management, while
*Corrective and Component Replacement activities require greater
*maintenance capacity because of their time demands.

*Power BI:

*Use a combo chart showing total maintenance hours by
*maintenance type with maintenance jobs as a secondary metric.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7C.20*

*Business Question:

*Which passenger age groups have the greatest demand for
*special assistance?

*Business Purpose:

*Identify passenger age groups with higher special-assistance
*requirements to support accessibility and passenger-service
*planning.

*KPIs:

*1. Total Passengers
*2. Special Assistance Passengers
*3. Special Assistance Rate
*4. Average Passenger Score

*------------------------------------------------------------*/

SELECT
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
    age_group
ORDER BY
    special_assistance_rate_percentage DESC;
    
/*------------------------------------------------------------*

*Business Insight:

*Senior passengers have the highest special-assistance rate at
22.37%, followed by Children at 22.09%. Adults and Youth have
lower assistance rates of 19.55% and 18.90% respectively.

*DSS Relevance:

*Passenger-service planning should give particular attention to
Senior and Child passengers because they have the highest
concentration of special-assistance requirements.

*Power BI:

*Use a ranked bar chart for special-assistance rate by age group,
with total assistance passengers shown as a secondary metric.

*------------------------------------------------------------*/