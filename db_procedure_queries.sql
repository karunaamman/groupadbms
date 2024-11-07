-- sp_InsertOrder -----
DELIMITER #
CREATE PROCEDURE sp_InsertOrder(
    IN p_customer_id INT,
    OUT p_order_id INT
)
BEGIN
    DECLARE new_invoice_no VARCHAR(20);
    -- Generate the invoice number using the fn_InvoiceGenerate function
    SET new_invoice_no = fn_InvoiceGenerate();

    -- Insert a new order with customer_id, generated invoice number, and current timestamp for order_date
    INSERT INTO orders (customer_id, invoice_no, order_date)
    VALUES (p_customer_id, new_invoice_no, CURRENT_TIMESTAMP());

    -- Get the last inserted order_id and set it as the OUT parameter
    SET p_order_id = LAST_INSERT_ID();
END #
DELIMITER ;

call sp_InsertOrder(80,@orderid);
SELECT @orderid;


-- sp_InsertOrderDetails -------------------------------------------------------
DELIMITER #
CREATE PROCEDURE sp_InsertOrderDetails(
    IN p_order_id INT,
    IN p_product_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE available_quantity INT;
    DECLARE unitPrice DECIMAL(10, 2);
    DECLARE totalPrice DECIMAL(10, 2);

    -- Check the available quantity and selling price of the product in the products table
    SELECT quantity, selling_price INTO available_quantity, unitPrice
    FROM products
    WHERE id = p_product_id;

    -- Verify if the available quantity is sufficient
    IF available_quantity >= p_quantity THEN
        -- Calculate total cost
        SET totalPrice = unitPrice * p_quantity;

        -- Insert the order details into the order_details table
        INSERT INTO order_details (order_id, product_id, quantity, unitcost, total)
        VALUES (p_order_id, p_product_id, p_quantity, unitPrice, totalPrice);

        -- Update the product quantity in the products table
        UPDATE products
        SET quantity = quantity - p_quantity
        WHERE id = p_product_id;
    ELSE
        -- Raise an error if there's insufficient stock
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient quantity in stock for the requested product';
    END IF;
END #
DELIMITER ;
call sp_InsertOrderDetails(@orderid,9,2);

-- sp_GetOrderDetailsById ----------------------------------------------
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



-- sp_DeleteProductById ----------
DELIMITER $$
CREATE PROCEDURE sp_DeleteProductById(IN product_id INT)
BEGIN
	DECLARE EXIT HANDLER FOR 1175 
			BEGIN 
				SELECT "Couldn't Restore the Product" as errorMessage;
            END;
    DELETE FROM products
    WHERE id = product_id;
END $$
DELIMITER ;
CALL sp_DeleteProductById(2);

-- sp_RestoreProduct ----
DELIMITER $$
CREATE PROCEDURE sp_RestoreProduct(IN product_id INT)
BEGIN
	DECLARE EXIT HANDLER FOR 1175 
			BEGIN 
				SELECT "Couldn't Restore the Product" as errorMessage;
            END;
    -- Restore the product from the deleted_products table to the products table
    INSERT INTO products (id, name, slug, code, quantity, buying_price, selling_price, quantity_alert, tax, tax_type, notes, product_image, category_id, unit_id, created_at, updated_at)
    SELECT id, name, slug, code, quantity, buying_price, selling_price, quantity_alert, tax, tax_type, notes, product_image, category_id, unit_id, created_at, updated_at
    FROM deleted_products WHERE id = product_id;

    -- Optionally, remove the restored product from the deleted_products table
    DELETE FROM deleted_products
    WHERE id = product_id;
END $$
DELIMITER ;
CALL sp_RestoreProduct(2);

-- sp_GetSupplierDetailsById ---------------------------------------------
DELIMITER #
CREATE PROCEDURE sp_GetSupplierDetailsById (
    IN in_supplier_id INT
)
BEGIN
    SELECT 
        id,
        name,
        email,
        phone,
        address,
        shopname,
        type,
        photo,
        account_number,
        bank_name
    FROM 
        suppliers
    WHERE 
        id = in_supplier_id;
END #
DELIMITER ;


-- sp_UpdateSupplier --------------------------------------------
DELIMITER //
CREATE PROCEDURE sp_UpdateSupplier(
    IN in_id INT,
    IN in_name VARCHAR(255),
    IN in_email VARCHAR(255),
    IN in_phone VARCHAR(20),
    IN in_address TEXT,
    IN in_shopname VARCHAR(255),
    IN in_type VARCHAR(50),
    IN in_photo BLOB,
    IN in_account_holder VARCHAR(255),
    IN in_account_number VARCHAR(50),
    IN in_bank_name VARCHAR(255)
)
BEGIN
    UPDATE suppliers
    SET 
        name = in_name,
        email = in_email,
        phone = in_phone,
        address = in_address,
        shopname = in_shopname,
        type = in_type,
        photo = in_photo,
        account_holder = in_account_holder,
        account_number = in_account_number,
        bank_name = in_bank_name,
        updated_at = CURRENT_TIMESTAMP()
    WHERE 
        id = in_id;
END //
DELIMITER ;

-- sp_DeleteSupplier --------------------------------------
DELIMITER //
CREATE PROCEDURE sp_DeleteSupplier(
    IN in_supplier_id INT
)
BEGIN
    DELETE FROM suppliers
    WHERE id = in_supplier_id;
END //
DELIMITER ;

-- sp_InsertSupplier ---------------------------------------
DELIMITER //
CREATE PROCEDURE sp_InsertSupplier(
    IN in_name VARCHAR(100),
    IN in_email VARCHAR(100),
    IN in_phone VARCHAR(15),
    IN in_address VARCHAR(255),
    IN in_shopname VARCHAR(100),
    IN in_type VARCHAR(50),
    IN in_photo BLOB,
    IN in_account_holder VARCHAR(100),
    IN in_account_number VARCHAR(50),
    IN in_bank_name VARCHAR(100)
)
BEGIN
    INSERT INTO suppliers (name,email,phone,address,shopname,type,photo,account_holder,account_number,bank_name,created_at,updated_at)
    VALUES (
        in_name,
        in_email,
        in_phone,
        in_address,
        in_shopname,
        in_type,
        in_photo,
        in_account_holder,
        in_account_number,
        in_bank_name,
        CURRENT_TIMESTAMP(),
        CURRENT_TIMESTAMP()
    );
END //
DELIMITER ;

---  sp_UpdateUser -------------------------
DELIMITER $$
CREATE PROCEDURE sp_UpdateUser(
    IN p_id INT,
    IN p_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_username VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_image VARCHAR(255)
)
BEGIN
    UPDATE users
    SET name = p_name,
        email = p_email,
        username = p_username,
        password = p_password,
        image = p_image
    WHERE id = p_id;
END $$
DELIMITER ;

-----  sp_InsertUser -----------------------------------
DELIMITER //
CREATE PROCEDURE sp_InsertUser(
    IN p_name VARCHAR(255),
    IN p_email VARCHAR(255),
    IN p_username VARCHAR(255),
    IN p_password VARCHAR(255),
    IN p_image BLOB
)
BEGIN
    INSERT INTO users (name, email, username, password, image)
    VALUES (p_name, p_email, p_username, p_password, p_image);
END //
DELIMITER ;


----  sp_DeleteUser ------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_DeleteUser(
    IN p_id INT
)
BEGIN
    DELETE FROM users
    WHERE id = p_id;
END $$
DELIMITER ;


-- sp_GetUserDetails --------------------
DELIMITER $$
CREATE PROCEDURE sp_GetUserDetails(
    IN p_id INT
)
BEGIN
    SELECT name, email, username, password, image
    FROM users
    WHERE id = p_id;
END $$
DELIMITER ;