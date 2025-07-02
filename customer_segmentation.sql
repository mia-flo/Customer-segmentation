--categorise clients based on geography and their shopping history
USE [customer segmentation];

--541909 total entries
SELECT * FROM [Online Retail];


--does the CustomerID column contain any NULL values
	--135,080 entries with NULL values for CustomerID
SELECT *
FROM [Online Retail]
WHERE CustomerID IS NULL;


--some entries where the customer ID is NULL is from errors or damages found by the company
	--entries with NULL customer IDs seem to be inventory


--countries serviced by this company - 37 countries
SELECT 
	COUNT(DISTINCT(Country))
FROM [Online Retail] 
WHERE Country != 'Unspecified';


--updating country abreviations
UPDATE [Online Retail]
	SET 
		Country = REPLACE(Country, 'RSA', 'Republic of South Africa');

UPDATE [Online Retail]
	SET 
		Country = REPLACE(Country, 'EIRE', 'Ireland');

UPDATE [Online Retail]
	SET 
		Country = REPLACE(Country, 'USA', 'United States');



--a table of all orders not grouped
DROP TABLE IF EXISTS orders;
SELECT
	InvoiceNo
	,StockCode
	,Description
	,Quantity
	,InvoiceDate
	,UnitPrice
	,CustomerID
	,Country
INTO orders
FROM [Online Retail]
WHERE CustomerID IS NOT NULL
	AND InvoiceNo NOT LIKE 'C%'
	AND Country != 'Unspecified';


--397,680 entries in the orders table
SELECT * FROM orders;

--returns
DROP TABLE IF EXISTS returns;
SELECT
	InvoiceNo
	,StockCode
	,Description
	,Quantity
	,InvoiceDate
	,UnitPrice
	,CustomerID
	,Country
INTO returns
FROM [Online Retail]
WHERE CustomerID IS NOT NULL
	AND InvoiceNo LIKE 'C%'
	AND Country != 'Unspecified';


SELECT * FROM returns;


--inventory entries
DROP TABLE IF EXISTS inventory;
SELECT
	InvoiceNo
	,StockCode
	,CustomerID
	,Description
	,Quantity
	,InvoiceDate
	,UnitPrice
	,Country
INTO inventory
FROM [Online Retail]
WHERE CustomerID IS NULL
	AND InvoiceNo NOT LIKE 'C%';


SELECT * FROM inventory;




----number of total orders placed to this online retailer by country
CREATE VIEW orders_by_country AS
SELECT
	Country
	,COUNT(DISTINCT(InvoiceNo)) AS 'Number of Orders'
FROM orders
GROUP BY Country;


SELECT * FROM orders_by_country;




----grouping based on geography
DROP TABLE IF EXISTS geographic_distribution;
WITH customer_by_country (Country, count_by_country) AS
	(
	SELECT
		Country
		,COUNT(CustomerID) 
			OVER (PARTITION BY Country) AS count_by_country 
	FROM orders
	GROUP BY Country, CustomerID
	)
SELECT 
	c.Country
	,C.count_by_country AS cust_country
	,SUM(Quantity) AS units
	,ROUND(SUM(Quantity*UnitPrice),2) AS total_spent
INTO geographic_distribution
FROM orders o
JOIN customer_by_country c
	ON c.Country = o.Country
GROUP BY c.Country, c.count_by_country;


SELECT * FROM geographic_distribution;




--do the sums of customers, units purchased, and total spent by country add up correctly
	--orders table vs original Online Retail database:
		--orders table has 36 countries instead of 37 - one less country 
		--orders table has 4,343 distinct CustomerIDs instead of 4,335 - 8 more 
			--suggests overlaps in CustomerIDs over countries
		--total units and total spent are consistent

SELECT
	COUNT(Country) AS num_countries
	,SUM(cust_country) AS total_customers
	,SUM(units) AS total_units
	,SUM(total_spent) AS total_spent
FROM geographic_distribution;


----------Hong Kong is the country that is not in the orders table but is in the database - CustomerID is NULL
SELECT 
	DISTINCT(Country)
FROM [Online Retail]
WHERE Country NOT IN (
	SELECT
		DISTINCT(Country)
	FROM orders
	);

SELECT
	*
FROM [Online Retail]
WHERE Country = 'Hong Kong';



----where are the 8 extra CustomerIDs coming from?
DROP TABLE IF EXISTS #non_unique_IDs;
WITH count_customerID_country (CustomerID, country_count) AS
		(
		SELECT DISTINCT
			CustomerID
			,COUNT(Country)
				OVER (PARTITION BY CustomerID ORDER BY CustomerID DESC)
					AS country_count 
		FROM orders
		GROUP BY CustomerID, Country
		),
	duplicates (CustomerID) AS
		(
		SELECT
			CustomerID
		FROM count_customerID_country
		GROUP BY CustomerID, country_count
		HAVING country_count > 1
		)
SELECT DISTINCT
	CustomerID
	,Country
INTO #non_unique_IDs
FROM orders
WHERE CustomerID IN (SELECT CustomerID FROM duplicates);

SELECT * FROM #non_unique_IDs ORDER BY Country;



-----making CustomerID truly unique by adding the country abbreviation to the end of the ID


ALTER TABLE returns
	ADD Country_abbrv NVARCHAR(5); 

ALTER TABLE orders
	ADD Country_abbrv NVARCHAR(5); 


--CASE to update the country abbreviations
--UPDATE returns
UPDATE orders
	SET Country_abbrv = CASE
		WHEN Country = 'Australia' THEN 'AUS'
		WHEN Country = 'Austria' THEN 'AUT'
		WHEN Country = 'Bahrain' THEN 'BAHR'
		WHEN Country = 'Belgium' THEN 'BELG'
		WHEN Country = 'Brazil' THEN 'BRZL'
		WHEN Country = 'Canada' THEN 'CAN'
		WHEN Country = 'Channel Islands' THEN 'CHI'
		WHEN Country = 'Cyprus' THEN 'CYPR'
		WHEN Country = 'Czech Repblic' THEN 'CZEC'
		WHEN Country = 'Denmark' THEN 'DEN'
		WHEN Country = 'European Community' THEN 'EURO'
		WHEN Country = 'Finland' THEN 'FIN'
		WHEN Country = 'France' THEN 'FRAN'
		WHEN Country = 'Germany' THEN 'GER'
		WHEN Country = 'Greece' THEN 'GRC'
		WHEN Country = 'Honk Kong' THEN 'HOKO'
		WHEN Country = 'Iceland' THEN 'ICLD'
		WHEN Country = 'Ireland' THEN 'IRE'
		WHEN Country = 'Israel' THEN 'ISRL'
		WHEN Country = 'Italy' THEN 'ITLY'
		WHEN Country = 'Japan' THEN 'JPN'
		WHEN Country = 'Lebanon' THEN 'LEBN'
		WHEN Country = 'Lithuania' THEN 'LITH'
		WHEN Country = 'Malta' THEN 'MLTA'
		WHEN Country = 'Netherlands' THEN 'NETH'
		WHEN Country = 'Norway' THEN 'NORW'
		WHEN Country = 'Poland' THEN 'POL'
		WHEN Country = 'Portugal' THEN 'PORT'
		WHEN Country = 'Republic of South Africa' THEN 'RSA'
		WHEN Country = 'Saudi Arabia' THEN 'SARB'
		WHEN Country = 'Singapore' THEN 'SING'
		WHEN Country = 'Spain' THEN 'SPN'
		WHEN Country = 'Sweden' THEN 'SWDN'
		WHEN Country = 'Switzerland' THEN 'SWTZ'
		WHEN Country = 'United Arab Emirates' THEN 'UAE'
		WHEN Country = 'United Kingdom' THEN 'UK'
		WHEN Country = 'United States' THEN 'USA'
	ELSE NULL
	END


UPDATE returns
	SET CustomerID = CONCAT(CustomerID, '-', Country_abbrv)

UPDATE orders 
	SET CustomerID = CONCAT(CustomerID, '-', Country_abbrv)


SELECT * FROM orders;





--------GROUPING CUSTOMERS BASED ON ORDER FREQUENCY AND NUMBER OF ORDERS

------------------------------------------------------------------
----customers who have ordered in consecutive months and how many times they have made an order in consecutive months 3 or more times
--878
DROP TABLE IF EXISTS #regular;
WITH time_gap (CustomerID, bw_orders) AS
		(
		SELECT 
			CustomerID
			,DATEDIFF(month, InvoiceDate, LEAD(InvoiceDate) 
				OVER (PARTITION BY CustomerID ORDER BY CustomerID)) AS bw_orders
		FROM orders
		GROUP BY CustomerID, InvoiceDate
		),
	consec (CustomerID, consec_months) AS
		(
		SELECT
			CustomerID
			,COUNT(bw_orders) AS consec_months
		FROM time_gap
		WHERE bw_orders = 1
		GROUP BY CustomerID
		)
SELECT
	c.CustomerID
	,consec_months
	,SUM(Quantity) AS total_units
	,ROUND(SUM(UnitPrice*Quantity), 2) AS total_spent
	,COUNT(DISTINCT(InvoiceNo)) AS num_orders
	,Country
INTO #regular 
FROM consec c
JOIN orders o 
	ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.consec_months, Country
HAVING COUNT(DISTINCT(InvoiceNo)) >= 3
	AND consec_months >= 2;


SELECT * FROM #regular;



-----------------------------------------------------------------


----return customers (have made more than 2 orders but in non-consecutive months throughout the year)
--1,131
DROP TABLE IF EXISTS #return;
WITH count_orders (CustomerID, num_orders, Country) AS
		(
		SELECT DISTINCT
			CustomerID
			,COUNT(DISTINCT(InvoiceNo)) AS num_orders
			,Country
		FROM orders
		GROUP BY CustomerID, Country
		)
SELECT DISTINCT
	c.CustomerID
	,SUM(o.Quantity) AS total_units
	,ROUND(SUM(o.Quantity*o.UnitPrice), 2) AS total_spent
	,num_orders
	,c.Country
INTO #return
FROM count_orders c
JOIN orders o
	ON c.CustomerID = o.CustomerID
WHERE num_orders > 2
	AND c.CustomerID NOT IN (SELECT CustomerID FROM #regular)
GROUP BY c.CustomerID, num_orders, c.Country;


SELECT * FROM #return ORDER BY CustomerID DESC;





----one-time customers (= 1 order)
	--1,500 new customers
DROP TABLE IF EXISTS #one_time;
WITH one_time (CustomerID, num_orders, Country) AS
		(
		SELECT DISTINCT
			CustomerID
			,COUNT(DISTINCT(InvoiceNo))
				AS num_orders
			,Country
		FROM orders
		GROUP BY CustomerID, Country
		)
SELECT DISTINCT
	t.CustomerID
	,SUM(Quantity) AS total_units
	,ROUND(SUM(Quantity*UnitPrice), 2) AS total_spent
	,num_orders
	,t.Country
INTO #one_time
FROM one_time t
JOIN orders o
	ON t.CustomerID = O.CustomerID
WHERE num_orders = 1
GROUP BY t.CustomerID, num_orders, t.Country;

SELECT * FROM #one_time;




----new customers have ordered only twice
--834 new customers
DROP TABLE IF EXISTS #new;
WITH two_time (CustomerID, num_orders, Country) AS
		(
		SELECT DISTINCT
			CustomerID
			,COUNT(DISTINCT(InvoiceNo))
				AS num_orders
			,Country
		FROM orders
		GROUP BY CustomerID, Country
		)
SELECT DISTINCT
	t.CustomerID
	,SUM(Quantity) AS total_units
	,ROUND(SUM(Quantity*UnitPrice), 2) AS total_spent
	,num_orders
	,t.Country
INTO #new
FROM two_time t
JOIN orders o
	ON t.CustomerID = o.CustomerID
WHERE num_orders = 2
	AND t.CustomerID NOT IN (SELECT CustomerID FROM #return)
GROUP BY t.CustomerID, num_orders, t.Country;

SELECT * FROM #new;





----creating a customer table for regular, return, new, and one-time 
DROP TABLE IF EXISTS Customers;
CREATE TABLE Customers (
	CustomerID NVARCHAR(50) NOT NULL PRIMARY KEY,
	CustomerStatus NVARCHAR(50),
	Country NVARCHAR(50) NOT NULL,
	Units INT NOT NULL,
	Spent FLOAT NOT NULL,
	Order_Count INT NOT NULL
);

INSERT INTO Customers (CustomerID, Country, Units, Spent, Order_Count)
SELECT
	CustomerID
	,Country
	,total_units
	,total_spent
	,num_orders
FROM #regular;


INSERT INTO Customers (CustomerID, Country, Units, Spent, Order_Count)
SELECT
	CustomerID
	,Country
	,total_units
	,total_spent
	,num_orders
FROM #return;


INSERT INTO Customers (CustomerID, Country, Units, Spent, Order_Count)
SELECT
	CustomerID
	,Country
	,total_units
	,total_spent
	,num_orders
FROM #one_time;


INSERT INTO Customers (CustomerID, Country, Units, Spent, Order_Count)
SELECT
	CustomerID
	,Country
	,total_units
	,total_spent
	,num_orders
FROM #new;


----
UPDATE Customers
	SET CustomerStatus = CASE
		WHEN CustomerID IN (SELECT CustomerID FROM #regular) THEN 'Regular'
		WHEN CustomerID IN (SELECT CustomerID FROM #return) THEN 'Return'
		WHEN CustomerID IN (SELECT CustomerID FROM #new) THEN 'New'
		WHEN CustomerID IN (SELECT CustomerID FROM #one_time) THEN 'One time'
	END


SELECT * FROM Customers;


--unique grouped orders
DROP TABLE IF EXISTS #unique_orders;
WITH order_info (InvoiceNo, total_spent) AS
		(
		SELECT	
			InvoiceNo,
			SUM(Quantity*UnitPrice)
				OVER (PARTITION BY InvoiceNo)
					AS total_spent
		FROM orders
		GROUP BY InvoiceNo, Quantity, UnitPrice
		)
SELECT DISTINCT
	o.CustomerID,
	c.CustomerStatus,
	i.InvoiceNo,
	i.total_spent
INTO #unique_orders
FROM order_info i
JOIN orders o 
	ON i.InvoiceNo = o.InvoiceNo
JOIN Customers c
	ON c.CustomerID = o.CustomerID;

SELECT * FROM #unique_orders ORDER BY InvoiceNo;

----total sales
DROP TABLE IF EXISTS total;
SELECT 
	COUNT(DISTINCT(CustomerID)) AS num_customers
	,SUM(Quantity) AS total_units
	,ROUND(SUM(Quantity*UnitPrice), 2) AS total_spent
	,COUNT(DISTINCT(InvoiceNo)) AS num_orders
INTO total
FROM orders;

SELECT * FROM total;





--------VIEWS



--geographic distribution of customers and sales percentages
CREATE VIEW geographic_distribution AS 
WITH by_country (Country, customer_count, units, spent, orders) AS
		(
		SELECT DISTINCT
			Country
			,COUNT(CustomerID)
				OVER (PARTITION BY Country)
					AS customer_count
			,SUM(Units) 
				OVER (PARTITION BY Country)
					AS units
			,SUM(Spent) 
				OVER (PARTITION BY Country)
					AS spent
			,SUM(Order_Count) 
				OVER (PARTITION BY Country)
					AS orders
		FROM Customers
		GROUP BY Country, CustomerID, Units, Spent, Order_Count
		)
SELECT
	Country
	,customer_count
	,ROUND(100 * CAST(customer_count AS FLOAT) / (SELECT COUNT(CustomerID) FROM Customers), 2)
		AS customer_percent
	,ROUND(100 * CAST(units AS FLOAT) / CAST((SELECT total_units FROM total) AS FLOAT), 2)
		AS Units
	,ROUND(100 * (spent / (SELECT total_spent FROM total)), 2)
		AS Spent
	,ROUND(100 * CAST(orders AS FLOAT) / CAST((SELECT num_orders FROM total) AS FLOAT), 2)
		AS order_count
FROM by_country
GROUP BY Country, customer_count, units, spent, orders;

SELECT * FROM geographic_distribution;




--calculate the percent contritbution of each customer type
CREATE VIEW customer_contribution_view AS
SELECT
	ROUND(100 * CAST((SELECT SUM(Units) FROM Customers WHERE CustomerStatus = 'Regular') AS FLOAT) / CAST(total_units AS FLOAT), 2)
		AS 'Regular - Units'
	,ROUND(100 * CAST((SELECT SUM(Units) FROM Customers WHERE CustomerStatus = 'Return') AS FLOAT) / CAST(total_units AS FLOAT), 2)
		AS 'Return - Units'
	,ROUND(100 * CAST((SELECT SUM(Units) FROM Customers WHERE CustomerStatus = 'New') AS FLOAT) / CAST(total_units AS FLOAT), 2)
		AS 'New - Units'
	,ROUND(100 * CAST((SELECT SUM(Units) FROM Customers WHERE CustomerStatus = 'One time') AS FLOAT) / CAST(total_units AS FLOAT), 2)
		AS 'One-time - Units'
	,ROUND(100 * (SELECT SUM(Spent) FROM Customers WHERE CustomerStatus = 'Regular') / total_spent, 2)
		AS 'Regular - Gross'
	,ROUND(100 * (SELECT SUM(Spent) FROM Customers WHERE CustomerStatus = 'Return') / total_spent, 2)
		AS 'Return - Gross'
	,ROUND(100 * (SELECT SUM(Spent) FROM Customers WHERE CustomerStatus = 'New') / total_spent, 2)
		AS 'New - Gross'
	,ROUND(100 * (SELECT SUM(Spent) FROM Customers WHERE CustomerStatus = 'One time') / total_spent, 2)
		AS 'One-time - Gross'
	,ROUND(100 * CAST((SELECT SUM(Order_Count) FROM Customers WHERE CustomerStatus = 'Regular') AS FLOAT) / CAST(num_orders AS FLOAT), 2)
		AS 'Regular - Orders'
	,ROUND(100 * (SELECT SUM(Order_Count) FROM Customers WHERE CustomerStatus = 'Return') / CAST(num_orders AS FLOAT), 2)
		AS 'Return - Orders'
	,ROUND(100 * (SELECT SUM(Order_Count) FROM Customers WHERE CustomerStatus = 'New') / CAST(num_orders AS FLOAT), 2)
		AS 'New - Orders'
	,ROUND(100 * (SELECT SUM(Order_Count) FROM Customers WHERE CustomerStatus = 'One time') / CAST(num_orders AS FLOAT), 2)
		AS 'One-time - Orders'
FROM total;

SELECT * FROM customer_contribution_view;






