-- Trigger trg_after_insert_order_details ------------------------------
DELIMITER #
CREATE TRIGGER trg_after_insert_order_details
AFTER INSERT ON order_details FOR EACH ROW
BEGIN
    DECLARE TotalProducts INT;
    DECLARE TotalAmount DECIMAL(15,2);
    DECLARE TotalVatAmount DECIMAL(15,2);
    DECLARE SubTotal DECIMAL(15,2);
    DECLARE TaxPercentageOfProduct DECIMAL(5,2);

    -- Retrieve values from orders and products tables
    SELECT total_products, total, vat, sub_total INTO TotalProducts, TotalAmount, TotalVatAmount, SubTotal 
    FROM orders WHERE id = NEW.order_id;
    
    SELECT tax INTO TaxPercentageOfProduct FROM products WHERE id = NEW.product_id;

    -- Update totals based on the new order details
    SET TotalProducts = TotalProducts + NEW.quantity;
    SET TotalAmount = TotalAmount + NEW.total;
    SET TotalVatAmount = TotalVatAmount + (NEW.unitcost * TaxPercentageOfProduct / 100) * NEW.quantity;
    SET SubTotal = TotalAmount + TotalVatAmount;

    -- Update the orders table with the new totals
    UPDATE orders SET 
        total_products = TotalProducts,
        total = TotalAmount,
        vat = TotalVatAmount,
        sub_total = SubTotal
    WHERE id = NEW.order_id;
END #
DELIMITER ;


-- trg_BeforeProductDelete ----
DELIMITER $$
CREATE TRIGGER trg_BeforeProductDelete
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    -- Insert the deleted product into deleted_products table
    INSERT INTO deleted_products (id, name, slug, code, quantity, buying_price, selling_price, quantity_alert, tax, tax_type, notes, product_image, category_id, unit_id, created_at, updated_at)
    VALUES (OLD.id, OLD.name, OLD.slug, OLD.code, OLD.quantity, OLD.buying_price, OLD.selling_price, OLD.quantity_alert, OLD.tax, OLD.tax_type, OLD.notes, OLD.product_image, OLD.category_id, OLD.unit_id, OLD.created_at, OLD.updated_at);
END $$
DELIMITER ;
