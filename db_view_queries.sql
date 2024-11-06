-- views =======================================================================================================

-- MonthlyOrders ------------------------------
CREATE VIEW vw_MonthlyOrders AS
SELECT COUNT(*) AS order_count, DATE_FORMAT(order_date, '%M %Y') AS month_year, SUM(total) AS total_amount
FROM orders 
GROUP BY DATE_FORMAT(order_date, '%M %Y')
ORDER BY MIN(order_date) DESC LIMIT 12;

-- MonthlyPurchases --------------------------
CREATE VIEW vw_MonthlyPurchases AS
SELECT COUNT(*) AS purchase_count, DATE_FORMAT(date, '%M %Y') AS month_year, SUM(total_amount) AS total_amount
FROM purchases 
GROUP BY DATE_FORMAT(date, '%M %Y')
ORDER BY MIN(date) DESC LIMIT 12;

-- AllOrdersOrderBbyDate ------------------------
CREATE VIEW vw_AllOrdersOrderByDate AS
SELECT 
	orders.id,
	invoice_no, 
    customers.name AS customer, 
    DATE_FORMAT(order_date,"%d-%m-%Y") AS date, 
    payment_type AS payment, 
    total, 
    CASE 
		WHEN order_status = 0 THEN "Pending"
		WHEN order_status = 1 THEN "Complete"
		WHEN order_status = 2 THEN "Cancel"
        ELSE "Unknown"
	END AS status
FROM orders INNER JOIN customers ON orders.customer_id = customers.id 
ORDER BY STR_TO_DATE(date, '%d-%m-%Y %H:%i:%s') DESC;