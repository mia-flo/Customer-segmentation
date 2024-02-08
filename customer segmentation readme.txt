categorise clients based on their demographics, shopping patterns, or other traits using SQL. visualized in Python


-invoiceNo
-stock code
-description
-quantity
-invoice date
-unit price
-customerID
-country



541909 initial entries - 135,080 entries have NULL values for customer ID 
	-397,680 working records (not returns, not NULL for CustomerID, and the country is not unspecified)
	-4339 distinct customers
	-1589 return (loyal customers)
	-38 locations 
		-asumming RSA is Republic of South Africe and EIRE is Ireland - replacing them
		-leave out the records with unspecified location






--have the loyal customers returned items?
		






tables:
-total quantity of units purchased by customer
-total amount spent by customer
-total number of individual orders by customer
-customers grouped by purchase category and number of times they purchased from that category
-number of distinct items purchased by customer and by order
-returning customers (order in consecutive months and how many consecutive months)



visualizations:
-scatterplot of all customers with total units purchased vs total spent w/ number of orders as the size
	-do segmentation on the plot
-scatterplot of regular customers with total units purchased vs total spent w/ number of orders as the size
	-do segmentation on the plot
-scatterplot of return customers with total units purchased vs total spent w/ number of orders as the size
	-do segmentation on the plot





