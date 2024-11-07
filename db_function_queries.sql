use inventory_management_system_backup;
-- 1 count the products-> fn_ProductCount() ===========================================================

DELIMITER #
CREATE FUNCTION fn_ProductCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE productCount INT;
    SELECT COUNT(id) into productCount FROM products;
    RETURN productCount;
END #
DELIMITER ;

SELECT fn_ProductCount();


-- 2 count the categories-> fn_CategoriesCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_CategoriesCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE categoriesCount INT;
    SELECT COUNT(id) INTO categoriesCount FROM categories;
    RETURN categoriesCount;
END #
DELIMITER ;

SELECT fn_CategoriesCount();

-- 3 count the Orders-> fn_OrdersCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_OrdersCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE ordersCount INT;
    SELECT COUNT(id) INTO ordersCount FROM orders;
    RETURN ordersCount;
END #
DELIMITER ;

SELECT fn_OrdersCount();

-- 3.1 count the Completed Orders-> fn_CompletedOrdersCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_CompletedOrdersCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE completedOrdersCount INT;
    SELECT COUNT(id) INTO completedOrdersCount FROM orders WHERE order_status=1;
    RETURN completedOrdersCount;
END #
DELIMITER ;

SELECT fn_CompletedOrdersCount();

-- 4 count the Purchases-> fn_PurchsesCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_PurchasesCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE purchsesCount INT;
    SELECT COUNT(id) INTO purchsesCount FROM purchases;
    RETURN purchsesCount;
END #
DELIMITER ;

SELECT fn_PurchasesCount();


-- 5 count the Today Purchases-> fn_TodayPurchsesCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_TodayPurchasesCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE todayPurchsesCount INT;
    SELECT COUNT(id) INTO todayPurchsesCount FROM purchases WHERE STR_TO_DATE(date, '%Y-%m-%d') = current_date();
    RETURN todayPurchsesCount;
END #
DELIMITER ;

SELECT fn_TodayPurchasesCount();

-- 6 count the Quotations-> fn_QuotationsCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_QuotationsCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE quotationsCount INT;
    SELECT COUNT(id) INTO quotationsCount FROM quotations;
    RETURN quotationsCount;
END #
DELIMITER ;

SELECT fn_QuotationsCount();


-- 7 count the Today Quotations-> fn_TodayQuotationsCount() =====================================================

DELIMITER #
CREATE FUNCTION fn_TodayQuotationsCount() RETURNS INT DETERMINISTIC
BEGIN
	DECLARE todayQuotationsCount INT;
    SELECT COUNT(id) INTO todayQuotationsCount FROM quotations 
        WHERE STR_TO_DATE(date, '%Y-%m-%d') = current_date();
    RETURN todayQuotationsCount;
END #
DELIMITER ;

SELECT fn_TodayQuotationsCount();


-- 8 InvoiceGenerate ===========================================================================================
DELIMITER #
CREATE FUNCTION fn_InvoiceGenerate() RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
    DECLARE lastInvNo VARCHAR(20);
    DECLARE lastInvNum BIGINT;
    DECLARE newInvNo VARCHAR(20);

    SELECT invoice_no INTO lastInvNo FROM orders 
    ORDER BY STR_TO_DATE(order_date, '%Y-%m-%d %H:%i:%s') DESC LIMIT 1;
    
    SET lastInvNum = CAST(SUBSTRING(lastInvNo, 5) AS UNSIGNED) + 1;
    SET newInvNo = CONCAT('INV-', lastInvNum);
    RETURN newInvNo;
END #
DELIMITER ;

SELECT fn_InvoiceGenerate();

