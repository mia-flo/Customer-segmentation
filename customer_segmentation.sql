--categorise clients based on their demographics, shopping patterns, or other traits

--541909 total entries
SELECT * FROM [Online Retail];


--does the CustomerID column contain any NULL values
	--135,080 entries with NULL values for CustomerID
SELECT *
FROM [Online Retail]
WHERE CustomerID IS NULL;


--countries serviced by this company
SELECT DISTINCT(Country) FROM [Online Retail];


--- 38 locations but how to handle:
	----is Eire Ireland?
	----RSA Republic of South Africa?
	----how to handle unspecified country


----some InvoiceIDs start witht the letter C and others are numeric characters only
	--IDs that contain the letter C have a negative values for quantity - likely returns
	--temp table of returns
DROP TABLE IF EXISTS #returns;
SELECT
	InvoiceNo
	,StockCode
	,[Description]
	,Quantity
	,InvoiceDate
	,UnitPrice
	,CustomerID
	,Country
INTO #returns
FROM [Online Retail]
WHERE CustomerID IS NOT NULL
	AND InvoiceNo LIKE 'C%'
	AND Country != 'Unspecified';


	--8,905 entries in the return table
	--1589 unique customers have returned something
SELECT COUNT(DISTINCT(CustomerID)) FROM #returns;


	--replacing RSA with Republic of South Africa and EIRE with Ireland in the #return table
UPDATE #returns
SET 
	Country = REPLACE(Country, 'RSA', 'Republic of South Africa');

UPDATE #returns
SET 
	Country = REPLACE(Country, 'EIRE', 'Ireland');




--make a temp table that excludes NULL values in the customerID field, returns, and records where the country is unspecified
DROP TABLE IF EXISTS #orders;
SELECT
	InvoiceNo
	,StockCode
	,Description
	,Quantity
	,InvoiceDate
	,UnitPrice
	,CustomerID
	,Country
INTO #orders
FROM [Online Retail]
WHERE CustomerID IS NOT NULL
	AND InvoiceNo NOT LIKE 'C%'
	AND Country != 'Unspecified';


	--397,680 entries in the orders table
SELECT * FROM #orders;


	--replacing RSA with Republic of South Africa and EIRE with Ireland in the #order table
UPDATE #orders
SET 
	Country = REPLACE(Country, 'RSA', 'Republic of South Africa');

UPDATE #orders
SET 
	Country = REPLACE(Country, 'EIRE', 'Ireland');


--4335 unique customers
SELECT
	COUNT(DISTINCT(CustomerID))
FROM #orders;






---------queries for visualizations

--totals by customer
SELECT 
	CustomerID
	,SUM(Quantity) AS 'Total Units Purchased'
	,SUM(UnitPrice*Quantity) AS 'Total Spent'
	,COUNT(DISTINCT(InvoiceNo)) AS 'Number of Purchases'
FROM #orders
GROUP BY CustomerID
ORDER BY 2 DESC;



--grouping customers by their purchase categories and times they purchased each item
SELECT
	CustomerID
	,[Description]
	,COUNT([Description]) AS 'Units Purchased'
FROM #orders
GROUP BY CustomerID, [Description]
ORDER BY 'Units Purchased' DESC;


--number of distinct items purchased by customer and by order
SELECT
	CustomerID
	,InvoiceNo
	,COUNT(InvoiceNo) AS 'Units Purchased'
FROM #orders
GROUP BY InvoiceNo, CustomerID
HAVING COUNT(InvoiceNo) > 1
ORDER BY CustomerID DESC;


--temp table of returning customers - customers who have ordered in consecutive months and how many times they have made an order in consecutive months
DROP TABLE IF EXISTS #regular_customers;
WITH time_gap (CustomerID, bw_orders) AS
		(
		SELECT 
			CustomerID
			,DATEDIFF(month, InvoiceDate, LEAD(InvoiceDate) 
				OVER (PARTITION BY CustomerID ORDER BY CustomerID)) AS bw_orders
		FROM #orders
		GROUP BY CustomerID, InvoiceDate
		),
	consec (CustomerID, months) AS
		(

		SELECT
			CustomerID
			,COUNT(bw_orders)+1 AS months
		FROM time_gap
		WHERE bw_orders = 1
		GROUP BY CustomerID
		)
SELECT
	c.CustomerID
	,months AS 'Consec_Months'
	,SUM(Quantity) AS 'Total _Units_Purchased'
	,SUM(UnitPrice*Quantity) AS 'Total_Spent'
	,COUNT(DISTINCT(InvoiceNo)) AS 'Number_of_Purchases'
	,Country
INTO #regular_customers 
FROM consec c
JOIN #orders o 
	ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.months, Country
ORDER BY 'Consec_Months' DESC;


--1591 regular customers
SELECT * FROM #regular_customers;


--return customers (have ordered in non-consecutive months)
DROP TABLE IF EXISTS #return_customers;
WITH orders (CustomerID, bw_orders) AS
		(
		SELECT 
			CustomerID
			,DATEDIFF(month, InvoiceDate, LEAD(InvoiceDate) 
				OVER (PARTITION BY CustomerID ORDER BY CustomerID)) AS bw_orders
		FROM #orders
		GROUP BY CustomerID, InvoiceDate
		),
	total (CustomerID, total_orders) AS
		(
		SELECT 
			CustomerID
			,COUNT(bw_orders) AS total_orders
		FROM orders
		GROUP BY CustomerID
		)
SELECT 
	t.CustomerID
	,total_orders AS 'Total_Orders'
	,SUM(Quantity) AS 'Total_Units_Purchased'
	,SUM(UnitPrice*Quantity) AS 'Total_Spent'
	,COUNT(DISTINCT(InvoiceNo)) AS 'Number_of_Orders'
	,Country
INTO #return_customers
FROM total t
JOIN #orders o
	ON t.CustomerID = o.CustomerID
WHERE total_orders IS NOT NULL AND total_orders != 0
GROUP BY t.CustomerID, total_orders, Country;


--2839 return customers
SELECT * FROM #return_customers;



--regular customers who have made returns - 910
	--2,725 total returns by regular customers
SELECT 
	r.CustomerID
	,r.InvoiceNo
FROM #regular_customers c
INNER JOIN #returns r 
	ON r.CustomerID = c.CustomerID
GROUP BY r.customerID, r.InvoiceNo
ORDER BY 1 ASC;


--return customers who have made returns - 1,344
	--3,381 total returns by return customers
SELECT 
	r.CustomerID
	,r.InvoiceNo
FROM #return_customers c
INNER JOIN #returns r 
	ON r.CustomerID = c.CustomerID
GROUP BY r.customerID, r.InvoiceNo
ORDER BY 1 ASC;



----joining return customers with the rest of the data
	--281,185 rows
SELECT 
	o.*
FROM #orders o
INNER JOIN #return_customers r 
	ON r.CustomerID = o.CustomerID
GROUP BY r.CustomerID, o.InvoiceNo, o.InvoiceDate, o.StockCode, o.Description, o.Quantity, o.UnitPrice, o.CustomerID, o.Country
ORDER BY CustomerID DESC;


--13,518 distinct orders from the 1587 regular customers (consecutive monthly ordesr)
SELECT 
	r.CustomerID
	,InvoiceNo
	,InvoiceDate
	,r.Country
FROM #orders o
INNER JOIN #return_customers r 
	ON r.CustomerID = o.CustomerID
GROUP BY r.CustomerID, InvoiceNo, InvoiceDate, r.Country
ORDER BY CustomerID DESC;






------top 100 customers

	--top 100 customers by quantity purchased
SELECT TOP 100
	CustomerID
	,SUM(Quantity) AS 'Total_Units_Purchased'
FROM #orders
GROUP BY CustomerID
ORDER BY 'Total_Units_Purchased' DESC;


	--top 100 customers by $ spent
SELECT TOP 100
	CustomerID
	,SUM(UnitPrice*Quantity) AS 'Total_Spent'
FROM #orders
GROUP BY CustomerID
ORDER BY 'Total_Spent' DESC;


	--top 100 customers by # of orders placed
SELECT TOP 100
	CustomerID
	,COUNT(DISTINCT(InvoiceNo)) AS 'Number_of_Purchases'
FROM #orders
GROUP BY CustomerID
ORDER BY 'Number_of_Purchases' DESC;




----spending habits of the top 100 regular customers by 
SELECT TOP 100 
	*
	,Total_Spent/Number_of_Purchases AS 'Avg_Spent'
FROM #regular_customers;