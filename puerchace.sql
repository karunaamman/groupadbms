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

