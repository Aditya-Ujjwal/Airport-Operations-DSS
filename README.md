Airport Operations Decision Support System (DSS)





Project Description

The Airport Operations Decision Support System (DSS) is an end-to-end data analytics and business intelligence project designed to convert airport operational data into actionable management insights.

The project combines data profiling, data cleaning, ETL, relational database design, SQL business analysis, analytical views, DAX measures, and an interactive Power BI dashboard.

The system is designed to help management understand:

Flight volume and passenger demand

Departure delays and passenger impact

Airline operational performance

Baggage workload

Security screening pressure

Aircraft utilization and maintenance workload

Maintenance severity and inspection risk

Passenger assistance requirements

Passenger experience

Staff deployment and overtime pressure

Holiday, seasonal, and international travel patterns

The final deliverable is a multi-page Power BI dashboard built on top of the cleaned MySQL database.

Dataset Description

The project uses a structured airport operations dataset covering October 2024 to December 2024.

The main operational tables are:

Table

Description

Flights

Flight schedules, routes, aircraft, passenger counts, delays, occupancy, operational score, season, holiday and international-flight indicators

Passengers

Passenger demographics, travel class, assistance requirements, timestamps and passenger experience score

Baggage

Baggage weight, priority, status, security and handling information

Gate_Events

Gate events, scheduled/actual timestamps, processed passengers and gate delay flags

Security_Screening

Screening timestamps, duration, security results, scanner/queue capacity and screening flags

Staff_Shifts

Departments, job roles, shift hours, terminal assignment and overtime indicators

Maintenance_Logs

Maintenance type, duration, severity, completion and inspection information

Dataset files

The repository contains the operational source files used by the project:


What We Did in This Project

The project was deliberately built as a complete analytics pipeline instead of directly connecting raw files to Power BI.

1. Database creation

A dedicated MySQL database, Airport_Operations_DSS, was created to hold the cleaned relational data.

2. Data profiling

The source data was profiled to understand structures, missing values, duplicates, invalid values, data types, and potential quality issues.

3. Data cleaning

Each operational dataset was validated and cleaned. This included missing-value checks, duplicate checks, categorical standardization, numeric validation, Boolean validation and timestamp checks.

Special attention was given to gate-event and security-screening timestamps, which contained inconsistencies. These timelines were reconstructed using explicit business rules so they could be used for operational analysis.

4. ETL

The cleaned data was loaded into normalized MySQL tables through an ETL process.

5. Relationships

Relationships were not established due to lack of unique identifiers in the dataset. So we created indexes for faster data retrieval.

6. Business analysis

The analysis was organized into three levels:

Level 1 — Basic Operational Analysis

Focused on core airport KPIs, airline volume, delays and passenger workload.

Level 2 — Operational Deep Dive

Focused on baggage, aircraft utilization, maintenance, security screening and shift workload.

Level 3 — Decision Support Analysis

Focused on passenger impact, airline benchmark performance, management priorities, maintenance risk, passenger assistance and workforce planning.

7. Power BI dashboard

The final SQL results and base tables were connected to Power BI, where the information was transformed into interactive visuals, KPI cards, slicers, navigation and decision-support views.

SQL Script Execution Sequence

The SQL scripts are intentionally numbered because the project is designed to run as a sequence. Later scripts depend on objects, tables, cleaned data or views created by earlier scripts.

Reference



01 — 01_Create_Database

Creates the Airport_Operations_DSS database and establishes the starting environment.

Run first.

02 — 02_Create_Clean_Tables

Creates the cleaned relational tables used by the project.

Key tables include:

Flights

Passengers

Baggage

Gate_Events

Security_Screening

Staff_Shifts

Maintenance_Logs

Retail_Transactions

03 — 03_Data_Profiling

Profiles the source data before transformations are applied.

The purpose is to identify:

Missing values

Duplicate records

Invalid values

Outliers

Data type issues

Referential inconsistencies

Timestamp anomalies

04 — 04_ETL_Load

Loads the cleaned/staged data into the final MySQL tables.

Typical transformations include trimming text, standardizing categories, converting data types, normalizing Boolean fields and loading cleaned records.

05 — 05_Create_Relationships

Creates the database relationships after ETL validation.

These relationships allow analysis across flight, passenger, baggage, security, gate, staff and maintenance data.

06A–06J — Data Cleaning and Database Preparation

The 06 scripts are table-specific validation and cleaning scripts.

06A — 06A_Flights_Cleaning

Validates flight identifiers, dates, delays, operational metrics, occupancy, status, holiday flags and international-flight fields.

06B — 06B_Passengers_Cleaning

Validates passenger IDs, age, travel/cabin class, timestamps, assistance flags, passenger score and age groups.

06C — 06C_Baggage_Cleaning

Validates baggage identifiers, weight, priority, status, security flags, fragile flags and mishandling information.

06D — 06D_Gate_Events_Cleaning

Validates gate-event timestamps and reconstructs the operational sequence around the associated flight departure. Gate delay flags are recalculated from actual versus scheduled event time.

06E — 06E_Security_Screening_Cleaning

Validates screening timestamps and reconstructs the workflow:

Arrival → Screening Start → Screening End

Screening duration is recalculated using the corrected timestamps.

06F — 06F_Staff_Shifts_Cleaning

Validates staff IDs, departments, job roles, shift hours, terminal assignment, overtime and related workforce fields.

06G — 06G_Maintenance_Logs_Cleaning

Validates maintenance duration, severity, priority, completion status, inspection status and aircraft/flight relationships.

06H — 06H_StoredProcedures_&_Views

Creates reusable stored procedures and analytical views used by later analysis and Power BI.

07A — 07A_Business_Analysis_Level1

The first business-analysis layer establishes the fundamental airport KPIs and answers questions such as:

How many flights were handled?

How many passengers were handled?

What is the delay rate?

What is the average departure delay?

Which airlines operate the most flights?

Which airlines experience more delays?

When is passenger workload highest?

This layer establishes the baseline airport performance picture.

07B — 07B_Business_Analysis_Level2

The second layer goes deeper into operational resource pressure.

It covers:

Baggage workload

Aircraft utilization

Maintenance workload

Maintenance duration

Shift workload

Security workload

Passenger/service operational pressure

This layer moves from what is happening toward where the operational pressure is occurring.

07C — 07C_Business_Analysis_Level3

The third layer focuses on decision support and management action.

It includes analysis such as:

Passenger impact by delay reason

Airline benchmark performance

Management priority classification

Maintenance severity and inspection risk

Passenger assistance demand

Passenger experience

Workforce/staffing analysis

This layer addresses:

What should management pay attention to?

Overall SQL Workflow

01 Create Database
        ↓
02 Create Clean Tables
        ↓
03 Data Profiling
        ↓
04 ETL Load
        ↓
05 Create Relationships
        ↓
06A–06H Cleaning / Views
        ↓
07A Business Analysis – Level 1
        ↓
07B Business Analysis – Level 2
        ↓
07C Business Analysis – Level 3
        ↓
Power BI Dashboard

Power BI Dashboard

The final Power BI report converts the SQL analysis into an interactive Airport Operations Decision Support Dashboard.

The report uses a dark navy, teal and yellow visual theme and is structured around three management perspectives.

Page 1 — Executive Overview

Purpose

Provides a high-level snapshot of airport performance.

Main questions

How is the airport performing overall?

Which airlines have higher delays?

How much passenger volume does each airline handle?

When is passenger workload highest?

Which delay reasons affect the largest number of passengers?

Major visuals

Total Flights

Total Passengers

Delay Rate

Average Delay

Average Occupancy

Average Operational Score

Airline Delay Performance

Airline Passenger Volume

Passenger Workload by Departure Hour

Passenger Impact by Delay Reason

Passengers Affected by Delay

Dashboard image

![Page 1 – Executive Overview](Dashboard_Images/Executive_Overview.png)

Page 2 — Operational Performance

Purpose

Focuses on operational pressure, airline performance and resource workload.

Main questions

Which airlines are below the airport-wide operational benchmark?

Which airlines create the largest baggage workload?

Which aircraft models combine utilization with maintenance workload?

When is airport/security workload highest?

Which maintenance severity levels create the greatest workload or risk?

Major visuals

Operational KPI strip

Airline Management Priority matrix

Baggage Workload by Airline

Aircraft Utilization vs Maintenance Workload

Shift Workload vs Screening Pressure

Maintenance Severity vs Inspection Risk

Management Action Snapshot

Dashboard image

![Page 2 – Operational Performance](Dashboard_Images/Operational_Performance.png)

Page 3 — Passenger & Service Planning

Purpose

Focuses on passenger characteristics, passenger-service needs, passenger experience and workforce planning.

Main questions

Which age groups have higher special-assistance requirements?

Does service burden differ across travel classes?

How does passenger experience vary across passenger segments?

Is there a difference in experience between passengers requiring assistance and others?

How is the airport workforce distributed across departments and job roles?

Which departments have greater overtime pressure?

Major visuals

Passenger-service KPI strip

Special Assistance Demand by Age Group

Passenger Service Burden by Travel Class

Passenger Experience Profile

Passenger Experience by Assistance Need

Staff Workforce Structure

Department Overtime Pressure

Dashboard image

![Page 3 – Passenger & Service Planning](Dashboard_Images/Passengers_service_and_Travel_Routes.png)

Dashboard Interaction

The report is designed as an interactive Power BI application rather than a collection of static charts.

Global filters

The dashboard uses shared filters for dimensions such as:

Date

Airline

Season

International/Domestic

Holiday/Non-Holiday

Navigation

A page navigator provides quick movement between the three dashboard pages.

Filter reset

A reset-filter action can return the report to its default state.

Cross-filtering

Charts and KPIs are configured to interact where the underlying data relationships support a meaningful filter path.

Key Project Insights

The analysis produced a range of operational and passenger-service insights, including:

The airport handled high passenger and flight volume with strong average occupancy.

A significant share of flights experienced departure delays.

Airline performance varies across delay, occupancy and operational-performance measures.

Some airlines fall below airport-wide benchmarks and require closer management attention.

Aircraft utilization and maintenance workload are not evenly distributed across aircraft models.

Baggage workload varies substantially between airlines.

Security screening pressure changes across operating shifts.

Maintenance severity levels differ in workload and inspection performance.

Passenger assistance requirements are concentrated more heavily in certain age groups.

Passenger experience differs across passenger segments.

Staff deployment and overtime provide a workforce-planning perspective alongside passenger demand.

Travel context such as holiday status and international/domestic classification can be evaluated against demand and operational performance.

The dashboard is intended to support investigation and decision-making rather than replace operational policy or human judgment.

Tools & Technologies

Database

MySQL

Data Processing

SQL

ETL

Data profiling

Data cleaning

Business Intelligence

Microsoft Power BI

DAX

Power BI data modeling

Interactive slicers

Page navigation

Analytical Domains

Airport operations

Passenger analytics

Flight performance

Baggage operations

Security screening

Gate operations

Maintenance analytics

Workforce planning

Decision support

Recommended Repository Structure

Airport-Operations-DSS/
│
├── README.md
│
├── SQL/
│   ├── 01_Create_Database.sql
│   ├── 02_Create_Clean_Tables.sql
│   ├── 03_Data_Profiling.sql
│   ├── 04_ETL_Load.sql
│   ├── 05_Create_Relationships.sql
│   ├── 06A_Flights_Cleaning.sql
│   ├── 06B_Passengers_Cleaning.sql
│   ├── 06C_Baggage_Cleaning.sql
│   ├── 06D_Gate_Events_Cleaning.sql
│   ├── 06E_Security_Screening_Cleaning.sql
│   ├── 06F_Staff_Shifts_Cleaning.sql
│   ├── 06G_Maintenance_Logs_Cleaning.sql
│   ├── 06H_StoredProcedures_Views.sql
│   ├── 07A_Business_Analysis_Level1.sql
│   ├── 07B_Business_Analysis_Level2.sql
│   └── 07C_Business_Analysis_Level3.sql
│
├── Data/
│   ├── baggage.xlsx
│   ├── flights.xlsx
│   ├── gate_events.xlsx
│   ├── maintenance_logs.xlsx
│   ├── passengers.xlsx
│   ├── security_screening.xlsx
│   └── staff_shifts.xlsx
│
├── PowerBI/
     └── Airport_Operations_DSS.pbix


How to Run the Project

Run the SQL scripts in numerical order.

Do not start directly with the business-analysis scripts because they depend on the database, cleaned tables, ETL, relationships and analytical views created earlier in the pipeline.

After the SQL workflow is complete:

Open the Power BI .pbix file.

Refresh the Power BI data model.

Confirm that SQL views and base tables are loaded.

Verify relationships and filter behavior.

Check dashboard slicers and page navigation.

Publish the Power BI report if required.

Project Outcome

This project demonstrates a complete Data Analytics + SQL + Business Intelligence workflow:

Raw Data
   ↓
Data Profiling
   ↓
Data Cleaning
   ↓
ETL
   ↓
Relational Database
   ↓
Business Analysis
   ↓
Analytical Views
   ↓
Power BI Data Model
   ↓
Interactive Dashboard
   ↓
Management Insights

The result is an end-to-end Airport Operations Decision Support System that turns raw operational records into interactive, management-oriented analytics.

