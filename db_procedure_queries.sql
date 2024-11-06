-- sp_CreateOrder
DELIMITER #
CREATE PROCEDURE sp_CreateOrder(IN customerId INT, OUT OrderId INT)
BEGIN
    DECLARE InvoiceNo VARCHAR(30);
    SET InvoiceNo = fn_InvoiceGenerate();

    INSERT INTO orders(customer_id, order_date, order_status, invoice_no)
    VALUES (customerId, CURRENT_TIMESTAMP(), 0, InvoiceNo);

    -- Get the newly created OrderId and return InvoiceNo as well
    SELECT id INTO OrderId FROM orders ORDER BY id DESC LIMIT 1;
END #
DELIMITER ;

-- sp_AddOrderDetails
DELIMITER #
CREATE PROCEDURE sp_AddOrderDetails(IN OrderID INT, IN ProductID INT, IN Quantity INT)
BEGIN
    DECLARE UnitPrice DECIMAL(15,2);
    DECLARE Total DECIMAL(15,2);
    DECLARE AvailableProductAmount INT;

    SELECT quantity INTO AvailableProductAmount FROM products WHERE id = ProductID;

    -- Check if the product exists
    IF (SELECT COUNT(*) FROM products WHERE id = ProductID) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    ELSEIF AvailableProductAmount IS NULL OR Quantity > AvailableProductAmount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient Product Quntity';
    ELSE
        -- Retrieve Unit Price for the product
        SELECT selling_price INTO UnitPrice FROM products WHERE id = ProductID;

        -- Calculate Total for the line item
        SET Total = Quantity * UnitPrice;

        -- Insert into order_details table
        INSERT INTO order_details(order_id, product_id, quantity, unitcost, total)
        VALUES (OrderID, ProductID, Quantity, UnitPrice, Total);

        Update products Set quantity = (AvailableProductAmount-Quantity) WHERE id = ProductID;
    END IF;
END #
DELIMITER ;

