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

-- sp_GetOrderDetailsById ----------------------------------------------

sp_GetOrderDetailsById
DELIMITER #
CREATE PROCEDURE sp_GetOrderDetailsById(IN p_order_id INT)
BEGIN
    -- Select product details from order_details and products tables
    SELECT 
        p.product_image AS Photo,
        p.name AS ProductName,
        p.code AS ProductCode,
        od.quantity AS Quantity,
        od.unitcost AS UnitPrice,
        od.total AS TotalPrice
    FROM 
        order_details od
    JOIN 
        products p ON od.product_id = p.id
    WHERE 
        od.order_id = p_order_id;

    -- Select payment details from orders table
    SELECT 
        pay,
        due,
        vat,
        sub_total
    FROM 
        orders
    WHERE 
        id = p_order_id;
END #
DELIMITER ;
call sp_GetOrderDetailsById(57);


--  sp_UpdateOrderStatus --------------------------------------
DELIMITER #
CREATE PROCEDURE sp_UpdateOrderStatus(
    IN p_order_id INT,
    IN p_status VARCHAR(10)
)
BEGIN
    -- Declare a variable to store the numeric status
    DECLARE status_value INT;

    -- Set the numeric status based on the string input
    IF p_status = 'pending' THEN
        SET status_value = 0;
    ELSEIF p_status = 'complete' THEN
        SET status_value = 1;
    ELSEIF p_status = 'cancel' THEN
        SET status_value = 2;
    ELSE
        -- If the input is invalid, set status_value to NULL (or handle as needed)
        SET status_value = NULL;
    END IF;

    -- Update the order status if status_value is not NULL
    IF status_value IS NOT NULL THEN
        UPDATE orders
        SET order_status = status_value
        WHERE id = p_order_id;
    END IF;
END #
DELIMITER ;
CALL sp_UpdateOrderStatus(56, 'pending');

-- sp_GetProductDetailsById --------------------------------------------------------
DELIMITER #
CREATE PROCEDURE sp_GetProductDetailsById (
    IN p_product_id INT
)
BEGIN
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        p.code AS product_code,
        p.quantity,
        p.buying_price,
        p.selling_price,
        p.quantity_alert,
        p.tax,
        p.tax_type,
        p.notes,
        p.product_image,
        p.created_at,
        p.updated_at,
        c.name AS category_name,
        u.short_code AS unit_short_code
    FROM 
        products p
    JOIN 
        categories c ON p.category_id = c.id
    JOIN 
        units u ON p.unit_id = u.id
    WHERE 
        p.id = p_product_id;
END #
DELIMITER ;
CALL sp_GetProductDetailsById(10);

-- sp_UpdateProduct ----------------------------------------------
DELIMITER #
CREATE PROCEDURE sp_UpdateProduct (
    IN p_product_id INT,
    IN p_product_image VARCHAR(255),
    IN p_name VARCHAR(255),
    IN p_category_id INT,
    IN p_unit_id INT,
    IN p_quantity INT,
    IN p_quantity_alert INT,
    IN p_tax DECIMAL(10, 2),
    IN p_notes TEXT
)
BEGIN
    UPDATE products
    SET 
        product_image = p_product_image,
        name = p_name,
        category_id = p_category_id,
        unit_id = p_unit_id,
        quantity = p_quantity,
        quantity_alert = p_quantity_alert,
        tax = p_tax,
        notes = p_notes
    WHERE 
        id = p_product_id;
END #
DELIMITER ;

CALL sp_UpdateProduct(
    1, -- product id
    NULL,                -- pass the image in BLOB format if needed
    'New Product Name',  -- new product name
    2,                   -- category_id
    3,                   -- unit_id
    100,                 -- quantity
    10,                  -- quantity_alert
    15.00,               -- tax
    'Updated notes'      -- notes
);