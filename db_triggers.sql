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
