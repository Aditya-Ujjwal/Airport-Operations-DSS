/*====================================================================*

                AIRPORT OPERATIONS DECISION SUPPORT SYSTEM
                    BUSINESS ANALYSIS & INSIGHTS

======================================================================

Project:
Airport Operations DSS

File    : 07_Business_Analysis.sql

Author  : Aditya Ujjwal

Purpose:
This file contains business-oriented SQL analysis performed on the
cleaned Airport Operations database.

The objective is to transform operational data into meaningful
KPIs, analytical findings, and decision-support insights for
airport management.

----------------------------------------------------------------------
ANALYSIS APPROACH
----------------------------------------------------------------------

The analysis is divided into three levels:

LEVEL 1 — MEDIUM
Basic business KPIs, aggregations, comparisons and operational
performance analysis.

LEVEL 2 — ADVANCED
Multi-table analysis, comparative metrics, CTEs, subqueries,
window functions and deeper operational relationships.

LEVEL 3 — DSS / EXPERT
Integrated analysis designed to identify operational risks,
resource requirements, bottlenecks and management priorities.

----------------------------------------------------------------------
BUSINESS ANALYSIS STRUCTURE
----------------------------------------------------------------------

Each analysis follows:

1. Business Question
2. SQL Query
3. Query Output
4. Business Analysis / Insight
5. Decision Support Relevance

----------------------------------------------------------------------
IMPORTANT
----------------------------------------------------------------------

Only business-relevant questions are included.

The analysis does not attempt to generate SQL queries merely to
demonstrate SQL features. Each query must provide information
useful for monitoring, evaluating or improving airport operations.

====================================================================*/

USE Airport_Operations_DSS;

/*------------------------------------------------------------*

*Analysis 7A.01*

*Business Question:*

*What is the overall operational performance of the airport?*

*Business Purpose:*

*Provide management with a high-level operational snapshot
*covering flight activity, passenger volume, delays, capacity
*utilization and overall operational performance.*

*KPIs:*

*1. Total Flights
*2. Total Passengers
*3. Average Passengers per Flight
*4. Average Departure Delay
*5. Delayed Flights
*6. Delay Rate
*7. Average Occupancy
*8. Average Operational Score

*------------------------------------------------------------*/

SELECT
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(
        AVG(passengers_onboard),2) AS avg_passengers_per_flight,
    ROUND(AVG(departure_delay_minutes),2) AS avg_departure_delay_minutes,
    SUM(
        CASE
            WHEN departure_delay_minutes > 0
            THEN 1
            ELSE 0
        END) AS delayed_flights,
    ROUND(100.0 *SUM(
            CASE
                WHEN departure_delay_minutes > 0
                THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2) AS delay_rate_percentage,
    ROUND(AVG(occupancy_percentage),2) AS avg_occupancy_percentage,
    ROUND(AVG(operational_score),2) AS avg_operational_score
FROM Flights;

/*------------------------------------------------------------*

*Business Insight:

*The airport handled 1,000 flights carrying 217,260 passengers,
*with an average occupancy of 86.41% and an average operational
*score of 86.61. However, 307 flights experienced delays,
*resulting in a 30.70% delay rate and an average departure delay
*of 15.66 minutes.

*DSS Relevance:

*The airport demonstrates strong capacity utilization and
*overall operational performance, but the 30.70% delay rate
*represents a significant area for operational improvement.
*Reducing delays while maintaining the current occupancy level
*should be a key management priority.

*Power BI:

*Display the core KPIs using KPI cards on the Executive
*Overview dashboard.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7A.02*

*Business Question:*

*Which airlines handle the highest number of flights at the airport?*

*Business Purpose:*

*Identify airlines with the greatest operational presence at the
*airport and quantify their contribution to total flight activity.*

*KPIs:*

*1. Total Flights by Airline
*2. Percentage of Total Airport Flights

*------------------------------------------------------------*/

SELECT
    airline_name,
    COUNT(*) AS total_flights,
    ROUND(100.0 * COUNT(*) /
		(SELECT COUNT(*) FROM Flights),
        2) AS percentage_of_total_flights
FROM Flights
GROUP BY airline_name
ORDER BY total_flights DESC;

/*------------------------------------------------------------*

*Business Insight:

*Lufthansa has the highest flight volume with 95 flights,
*representing 9.50% of total airport operations. Air France
*and Singapore Airlines follow closely with 94 flights each,
*while Vistara has the lowest flight volume at 65 flights.

*DSS Relevance:

*Airlines with higher flight volumes represent a greater
*share of airport operational workload and should receive
*greater attention when evaluating delays, passenger demand,
*gate usage and other operational metrics.

*Power BI:

*Use a ranked bar chart showing airline flight volume and
*percentage contribution.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7A.03*

*Business Question:

*Which airlines experience the highest departure delays?

*Business Purpose:

*Evaluate airline-level departure performance and identify
*airlines with higher delay frequency or delay duration.

*KPIs:

*1. Total Flights
*2. Delayed Flights
*3. Delay Rate
*4. Average Departure Delay

*------------------------------------------------------------*/

SELECT
    airline_name,
    COUNT(*) AS total_flights,
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
GROUP BY airline_name
ORDER BY avg_departure_delay_minutes DESC;

/*------------------------------------------------------------*

*Business Insight:

*SpiceJet records the highest average departure delay at
*20.56 minutes, while Singapore Airlines has the highest
*delay rate at 36.17%, with 34 of its 94 flights delayed.
*IndiGo also shows relatively high delay performance with a
*33.72% delay rate and an average delay of 18.14 minutes.
*Vistara has the lowest average delay at 9.69 minutes, while
*KLM has the second-lowest average delay at 10.81 minutes.

*British Airways is also notable, with a 34.85% delay rate,
*despite operating only 66 flights in the dataset.

*DSS Relevance:

*The results indicate that airline delay performance varies
*considerably across operators. Management should evaluate
*airlines using both delay frequency and delay duration rather
*than relying on a single metric. Airlines with both high
*flight volume and poor delay performance should receive
*greater operational attention.

*Power BI:

*Use a ranked bar chart for average delay by airline, with
*delay rate available as a secondary metric or tooltip.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7A.04*

*Business Question:

*Which airlines handle the greatest passenger volume, and how
*efficiently are they utilizing available aircraft capacity?

*Business Purpose:

*Measure airline passenger contribution while evaluating
*aircraft capacity utilization.

*KPIs:

*1. Total Passengers
*2. Total Flights
*3. Average Passengers per Flight
*4. Average Occupancy

*------------------------------------------------------------*/

SELECT
    airline_name,
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(AVG(passengers_onboard),2) AS avg_passengers_per_flight,
    ROUND(AVG(occupancy_percentage),2) AS avg_occupancy_percentage
FROM Flights
GROUP BY airline_name
ORDER BY total_passengers DESC;

/*------------------------------------------------------------*

*Business Insight:

*Singapore Airlines handles the highest passenger volume with
*20,979 passengers across 94 flights, followed closely by
*Air France with 20,808 passengers and Emirates with 20,704.
*Lufthansa operates the highest number of flights at 95 and
*handles 20,157 passengers.

*SpiceJet records the highest average occupancy at 87.38%,
*followed by Vistara at 87.36% and Qatar Airways at 87.16%,
*indicating strong capacity utilization despite differences
*in overall passenger volume.

*DSS Relevance:

*Passenger workload is concentrated among the airlines with
*the highest flight volumes, while occupancy levels remain
*relatively high across all airlines. Management should
*consider both passenger volume and capacity utilization when
*planning gates, baggage handling, security resources and
*other passenger-facing operations.

*Power BI:

*Use a clustered bar chart for passenger volume by airline
*and display average occupancy as a secondary metric or
*tooltip.

*------------------------------------------------------------*/

/*------------------------------------------------------------*

*Analysis 7A.05*

*Business Question:

*Which departure shifts handle the highest operational workload?

*Business Purpose:

*Compare operational workload across departure shifts using
*flight activity, passenger volume and aircraft utilization.

*KPIs:

*1. Total Flights
*2. Total Passengers
*3. Average Passengers per Flight
*4. Average Occupancy

*------------------------------------------------------------*/

SELECT
    departure_shift,
    COUNT(*) AS total_flights,
    SUM(passengers_onboard) AS total_passengers,
    ROUND(AVG(passengers_onboard),2) AS avg_passengers_per_flight,
    ROUND(AVG(occupancy_percentage),2) AS avg_occupancy_percentage
FROM Flights
GROUP BY departure_shift
ORDER BY total_passengers DESC;

/*------------------------------------------------------------*

*Business Insight:

*Evening has the highest operational workload with 291 flights
*and 63,059 passengers, while Afternoon has the lowest with
*207 flights and 45,604 passengers. Occupancy remains consistent
*across all shifts at approximately 86%.

*DSS Relevance:

*Evening should receive greater operational resource attention
*because it handles the highest flight and passenger volume.

*Power BI:

*Use a column chart comparing flight and passenger volume
*across the four departure shifts.

*------------------------------------------------------------*/