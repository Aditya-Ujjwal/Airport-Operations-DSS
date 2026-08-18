/*------------------------------------------------------------
Audit 8.1
Check Missing Values
------------------------------------------------------------*/

SELECT
    SUM(retail_transaction_id IS NULL) AS retail_transaction_id_nulls,
    SUM(transaction_id IS NULL) AS transaction_id_nulls,
    SUM(store_id IS NULL) AS store_id_nulls,
    SUM(store_type IS NULL) AS store_type_nulls,
    SUM(business_category IS NULL) AS business_category_nulls,
    SUM(passport_number IS NULL) AS passport_number_nulls,
    SUM(flight_number IS NULL) AS flight_number_nulls,
    SUM(transaction_time IS NULL) AS transaction_time_nulls,
    SUM(product_category IS NULL) AS product_category_nulls,
    SUM(quantity IS NULL) AS quantity_nulls,
    SUM(unit_price IS NULL) AS unit_price_nulls,
    SUM(total_amount IS NULL) AS total_amount_nulls,
    SUM(payment_method IS NULL) AS payment_method_nulls,
    SUM(currency IS NULL) AS currency_nulls,
    SUM(terminal IS NULL) AS terminal_nulls,
    SUM(store_location IS NULL) AS store_location_nulls,
    SUM(tax_free_purchase IS NULL) AS tax_free_purchase_nulls
FROM Retail_Transactions;

/*------------------------------------------------------------
Audit 8.2
Check Duplicate Retail Transaction IDs
------------------------------------------------------------*/

SELECT
    retail_transaction_id,
    COUNT(*) AS occurrence_count
FROM Retail_Transactions
GROUP BY retail_transaction_id
HAVING COUNT(*) > 1;

/*------------------------------------------------------------
Audit 8.3
Check Duplicate Transaction IDs
------------------------------------------------------------*/

SELECT
    transaction_id,
    COUNT(*) AS occurrence_count
FROM Retail_Transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

/*------------------------------------------------------------
Audit 8.4
Inspect Transaction IDs
------------------------------------------------------------*/

SELECT
    transaction_id
FROM Retail_Transactions
LIMIT 20;

SELECT
    transaction_id
FROM Retail_Transactions
WHERE TRIM(transaction_id) = '';

/*------------------------------------------------------------
Audit 8.5
Validate Store Types
------------------------------------------------------------*/

SELECT
    store_type,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY store_type
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.6
Validate Business Categories
------------------------------------------------------------*/

SELECT
    business_category,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY business_category
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.7
Validate Product Categories
------------------------------------------------------------*/

SELECT
    product_category,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY product_category
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.8
Validate Payment Methods
------------------------------------------------------------*/

SELECT
    payment_method,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY payment_method
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.9
Validate Currency
------------------------------------------------------------*/

SELECT
    currency,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY currency
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.10
Validate Tax-Free Purchase Flag
------------------------------------------------------------*/

SELECT
    tax_free_purchase,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY tax_free_purchase
ORDER BY tax_free_purchase;

SELECT
    tax_free_purchase
FROM Retail_Transactions
WHERE tax_free_purchase NOT IN (0,1);

/*------------------------------------------------------------
Audit 8.11
Validate Quantity
------------------------------------------------------------*/

SELECT
    MIN(quantity) AS Min_Quantity,
    MAX(quantity) AS Max_Quantity,
    AVG(quantity) AS Avg_Quantity
FROM Retail_Transactions;

SELECT
    retail_transaction_id,
    quantity
FROM Retail_Transactions
WHERE quantity <= 0;

/*------------------------------------------------------------
Audit 8.12
Validate Unit Price
------------------------------------------------------------*/

SELECT
    MIN(unit_price) AS Min_Unit_Price,
    MAX(unit_price) AS Max_Unit_Price,
    AVG(unit_price) AS Avg_Unit_Price
FROM Retail_Transactions;

SELECT
    retail_transaction_id,
    unit_price
FROM Retail_Transactions
WHERE unit_price <= 0;

/*------------------------------------------------------------
Audit 8.13
Validate Total Amount
------------------------------------------------------------*/

SELECT
    retail_transaction_id,
    quantity,
    unit_price,
    total_amount,

    ROUND(
        quantity * unit_price,
        2
    ) AS Calculated_Total

FROM Retail_Transactions

WHERE ABS(
    total_amount -
    ROUND(quantity * unit_price, 2)
) > 0.01;

/*------------------------------------------------------------
Audit 8.14
Validate Total Amount Range
------------------------------------------------------------*/

SELECT
    MIN(total_amount) AS Min_Total,
    MAX(total_amount) AS Max_Total,
    AVG(total_amount) AS Avg_Total
FROM Retail_Transactions;

SELECT
    retail_transaction_id,
    total_amount
FROM Retail_Transactions
WHERE total_amount <= 0;

/*------------------------------------------------------------
Audit 8.15
Transaction Time Range
------------------------------------------------------------*/

SELECT
    MIN(transaction_time) AS Earliest_Transaction,
    MAX(transaction_time) AS Latest_Transaction
FROM Retail_Transactions;

SELECT
    retail_transaction_id,
    transaction_id,
    passport_number,
    flight_number,
    transaction_time
FROM Retail_Transactions
LIMIT 20;

/*------------------------------------------------------------
Audit 8.16
Check Retail Transactions Against Passengers
------------------------------------------------------------*/

SELECT
    r.retail_transaction_id,
    r.passport_number
FROM Retail_Transactions r
LEFT JOIN Passengers p
    ON r.passport_number = p.passport_number
WHERE p.passport_number IS NULL;

/*------------------------------------------------------------
Audit 8.17
Check Retail Transactions Against Flights
------------------------------------------------------------*/

SELECT
    r.retail_transaction_id,
    r.flight_number
FROM Retail_Transactions r
LEFT JOIN Flights f
    ON r.flight_number = f.flight_number
WHERE f.flight_number IS NULL;

/*------------------------------------------------------------
Audit 8.18
Compare Transaction Time With Flight Departure
------------------------------------------------------------*/

SELECT
    r.retail_transaction_id,
    r.flight_number,
    r.passport_number,
    r.transaction_time,
    f.scheduled_departure,

    TIMESTAMPDIFF(
        MINUTE,
        r.transaction_time,
        f.scheduled_departure
    ) AS Minutes_Before_Departure

FROM Retail_Transactions r

JOIN Flights f
    ON r.flight_number = f.flight_number

LIMIT 20;

/*------------------------------------------------------------
Audit 8.19
Validate Terminals
------------------------------------------------------------*/

SELECT
    terminal,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY terminal
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.20
Validate Store Locations
------------------------------------------------------------*/

SELECT
    store_location,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY store_location
ORDER BY transaction_count DESC;

/*------------------------------------------------------------
Audit 8.21
Check Store Location vs Terminal
------------------------------------------------------------*/

SELECT
    store_location,
    COUNT(DISTINCT terminal) AS terminal_count
FROM Retail_Transactions
GROUP BY store_location
HAVING COUNT(DISTINCT terminal) > 1
ORDER BY terminal_count DESC;

/*------------------------------------------------------------
Audit 8.22
Transactions Per Passenger
------------------------------------------------------------*/

SELECT
    passport_number,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY passport_number
ORDER BY transaction_count DESC
LIMIT 20;

/*------------------------------------------------------------
Audit 8.23
Transactions Per Flight
------------------------------------------------------------*/

SELECT
    flight_number,
    COUNT(*) AS transaction_count
FROM Retail_Transactions
GROUP BY flight_number
ORDER BY transaction_count DESC
LIMIT 20;

/*------------------------------------------------------------
Audit 8.24
Retail Transaction Monetary Statistics
------------------------------------------------------------*/

SELECT
    COUNT(*) AS Total_Transactions,
    MIN(total_amount) AS Min_Transaction_Value,
    MAX(total_amount) AS Max_Transaction_Value,
    ROUND(AVG(total_amount), 2) AS Avg_Transaction_Value,
    ROUND(SUM(total_amount), 2) AS Total_Revenue
FROM Retail_Transactions;

SELECT
    flight_number,
    MIN(checkin_time) AS earliest_checkin,
    MAX(checkin_time) AS latest_checkin,
    COUNT(*) AS passenger_count
FROM Passengers
WHERE flight_number IN (
    '6E-3158',
    'AF-5872',
    'QR-1207',
    'SG-2202'
)
GROUP BY flight_number;