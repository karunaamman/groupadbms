ALTER TABLE orders
MODIFY COLUMN order_status tinyint NOT NULL DEFAULT 0,
MODIFY COLUMN total_products INT NOT NULL DEFAULT 0,
MODIFY COLUMN sub_total DECIMAL(15,2) NOT NULL DEFAULT 0,
MODIFY COLUMN vat DECIMAL(15,2) NOT NULL DEFAULT 0,
MODIFY COLUMN total DECIMAL(15,2) NOT NULL DEFAULT 0,
MODIFY COLUMN payment_type VARCHAR(20) NOT NULL DEFAULT "due",
MODIFY COLUMN pay DECIMAL(15,2) NOT NULL DEFAULT 0,
MODIFY COLUMN due DECIMAL(15,2) NOT NULL DEFAULT 0,
MODIFY COLUMN created_at timestamp NOT NULL default current_timestamp(),
MODIFY COLUMN updated_at timestamp NOT NULL default current_timestamp();


ALTER TABLE order_details
MODIFY COLUMN unitcost DECIMAL(15,2) NOT NULL,
MODIFY COLUMN total DECIMAL(15,2) NOT NULL,
MODIFY COLUMN created_at timestamp NOT NULL default current_timestamp(),
MODIFY COLUMN updated_at timestamp NOT NULL default current_timestamp();


ALTER TABLE products 
MODIFY COLUMN buying_price DECIMAL(15,2) NOT NULL,
MODIFY COLUMN selling_price DECIMAL(15,2) NOT NULL,
MODIFY COLUMN tax DECIMAL(5,2) NOT NULL,
MODIFY COLUMN created_at timestamp NOT NULL default current_timestamp(),
MODIFY COLUMN updated_at timestamp NOT NULL default current_timestamp();

ALTER TABLE categories
MODIFY COLUMN created_at timestamp NOT NULL default current_timestamp(),
MODIFY COLUMN updated_at timestamp NOT NULL default current_timestamp();

-- CREATE DELETED_PRODUCTS TABLE --------
CREATE TABLE IF NOT EXISTS deleted_products AS SELECT * FROM products WHERE 1 = 0;
ALTER TABLE deleted_products ADD PRIMARY KEY(id);