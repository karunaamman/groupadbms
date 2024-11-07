-- perchase controller 

use inventory_management_system_backup;

-- get resent puercases 
CREATE VIEW recent_purchases AS
SELECT * 
FROM purchases
ORDER BY created_at DESC;

select * from recent_purchases;

-- get aproved perchases 

CREATE VIEW approved_purchases AS
SELECT purchases.*, suppliers.name AS supplier_name
FROM purchases
JOIN suppliers ON purchases.supplier_id = suppliers.id
WHERE purchases.status = 1;

SELECT * FROM approved_purchases;

-- get pending puercheses

CREATE VIEW pending_purchases AS
SELECT purchases.*, suppliers.name AS supplier_name
FROM purchases
JOIN suppliers ON purchases.supplier_id = suppliers.id
WHERE purchases.status = 0;

SELECT * FROM pending_purchases;

-- get view for catogory 
CREATE VIEW view_categories AS
SELECT id, name 
FROM categories;

SELECT * FROM view_categories;

-- get supplier view
CREATE VIEW view_suppliers AS
SELECT id, name 
FROM suppliers;

SELECT * FROM view_suppliers;

desc purchases;


-- SELECT p.*, s.name AS supplier_name, u1.name AS created_by_name, u2.name AS updated_by_name
--         FROM purchases p
--         LEFT JOIN suppliers s ON p.supplier_id = s.id
--         LEFT JOIN users u1 ON p.created_by = u1.id
--         LEFT JOIN users u2 ON p.updated_by = u2.id
--         WHERE p.id = 1;
        
-- perchase details get by using puerchase id

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

CALL GetPurchaseDetails(1);


-- get purchase product details by purchace id

SELECT pd.*, pr.name AS product_name, pr.code AS product_code, pr.product_image
--         FROM purchase_details pd
--         LEFT JOIN products pr ON pd.product_id = pr.id
--         WHERE pd.purchase_id = 61;
        
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

CALL GetPurchaseProductDetails(61);

SELECT p.*, s.name AS supplier_name, u1.name AS created_by_name, u2.name AS updated_by_name
        FROM purchases p
        LEFT JOIN suppliers s ON p.supplier_id = s.id
        LEFT JOIN users u1 ON p.created_by = u1.id
        LEFT JOIN users u2 ON p.updated_by = u2.id
        WHERE p.id = 61;
        
DELIMITER $$

-- Load purchase data with supplier and user information using raw SQL

CREATE PROCEDURE GetPurchaseData(IN purchaseId INT)
BEGIN
    SELECT p.*, 
           s.name AS supplier_name, 
           u1.name AS created_by_name, 
           u2.name AS updated_by_name
    FROM purchases p
    LEFT JOIN suppliers s ON p.supplier_id = s.id
    LEFT JOIN users u1 ON p.created_by = u1.id
    LEFT JOIN users u2 ON p.updated_by = u2.id
    WHERE p.id = purchaseId;
END $$

DELIMITER ;

CALL GetPurchaseData(61);

-- 

-- SELECT pd.*, pr.name AS product_name, pr.code AS product_code, pr.product_image
--         FROM purchase_details pd
--         LEFT JOIN products pr ON pd.product_id = pr.id
--         WHERE pd.purchase_id =  61;


--  Load purchase details with product information using raw SQL
        
DELIMITER $$

CREATE PROCEDURE GetPurchaseDetailsByPurchaseId(IN purchaseId INT)
BEGIN
    SELECT pd.*, 
           pr.name AS product_name, 
           pr.code AS product_code, 
           pr.product_image
    FROM purchase_details pd
    LEFT JOIN products pr ON pd.product_id = pr.id
    WHERE pd.purchase_id = purchaseId;
END $$

DELIMITER ;

CALL GetPurchaseDetailsByPurchaseId(61);

-- insert data to purchase 
INSERT INTO purchases 
(date, purchase_no, status, total_amount, created_by, updated_by, created_at, updated_at)
VALUES 
('2024-11-08', 'PUR2024110801', 1, 5000, 1, NULL, '2024-11-08 12:00:00', NULL);






