
-- -----------------------------------------------------views--------------------------------------------
-- Recent Purchases 

CREATE VIEW recent_purchases AS
SELECT * 
FROM purchases
ORDER BY created_at DESC;

-- Approved Purchases

CREATE VIEW approved_purchases AS
SELECT purchases.*, suppliers.name AS supplier_name
FROM purchases
JOIN suppliers ON purchases.supplier_id = suppliers.id
WHERE purchases.status = 1;

-- Pending Purchases

CREATE VIEW pending_purchases AS
SELECT purchases.*, suppliers.name AS supplier_name
FROM purchases
JOIN suppliers ON purchases.supplier_id = suppliers.id
WHERE purchases.status = 0;

-- Categories View

CREATE VIEW view_categories AS
SELECT id, name 
FROM categories;

-- Suppliers View
CREATE VIEW view_suppliers AS
SELECT id, name 
FROM suppliers;


-- ---------------------------------------Store Procedure---------------------------------------

-- Get Purchase Details by Purchase ID

DELIMITER $$

CREATE PROCEDURE GetPurchaseDetails(IN purchase_id INT)
BEGIN
    SELECT 
        p.*, 
        s.name AS supplier_name, 
        u1.name AS created_by_name, 
        u2.name AS updated_by_name
    FROM 
        purchases p
    LEFT JOIN 
        suppliers s ON p.supplier_id = s.id
    LEFT JOIN 
        users u1 ON p.created_by = u1.id
    LEFT JOIN 
        users u2 ON p.updated_by = u2.id
    WHERE 
        p.id = purchase_id;
END$$

DELIMITER ;

-- Get Purchase Product Details by Purchase ID

DELIMITER $$

CREATE PROCEDURE GetPurchaseProductDetails(IN purchase_id INT)
BEGIN
    SELECT 
        pd.*, 
        pr.name AS product_name, 
        pr.code AS product_code, 
        pr.product_image
    FROM 
        purchase_details pd
    LEFT JOIN 
        products pr ON pd.product_id = pr.id
    WHERE 
        pd.purchase_id = purchase_id;
END$$

DELIMITER ;

-- Insert Purchase

DELIMITER $$

CREATE PROCEDURE InsertPurchase(
    IN supplier_id INT, 
    IN date DATE, 
    IN purchase_no VARCHAR(50), 
    IN status TINYINT, 
    IN total_amount DECIMAL(10, 2), 
    IN created_by INT
)
BEGIN
    INSERT INTO purchases (supplier_id, date, purchase_no, status, total_amount, created_by, created_at)
    VALUES (supplier_id, date, purchase_no, status, total_amount, created_by, NOW());
END$$

DELIMITER ;

-- Insert Purchase Detail

DELIMITER $$

CREATE PROCEDURE InsertPurchaseDetail(
    IN purchase_id INT, 
    IN product_id INT, 
    IN quantity INT, 
    IN unitcost DECIMAL(10, 2), 
    IN total DECIMAL(10, 2), 
    IN created_at TIMESTAMP
)
BEGIN
    INSERT INTO purchase_details (purchase_id, product_id, quantity, unitcost, total, created_at)
    VALUES (purchase_id, product_id, quantity, unitcost, total, created_at);
END$$

DELIMITER ;

-- Update Product Quantity 

DELIMITER $$

CREATE PROCEDURE UpdateProductQuantity(IN quantity INT, IN product_id INT)
BEGIN
    UPDATE products
    SET quantity = quantity + quantity
    WHERE id = product_id;
END$$

DELIMITER ;

-- Update Purchase Status

DELIMITER $$

CREATE PROCEDURE UpdatePurchaseStatus(
    IN status TINYINT,
    IN updated_by INT,
    IN purchase_id INT
)
BEGIN
    UPDATE purchases
    SET status = status, updated_by = updated_by, updated_at = NOW()
    WHERE id = purchase_id;
END$$

DELIMITER ;

-- Delete Purchase by ID

DELIMITER $$

CREATE PROCEDURE DeletePurchaseById(IN purchase_id INT)
BEGIN
    DELETE FROM purchases WHERE id = purchase_id;
END$$

DELIMITER ;




