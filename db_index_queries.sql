-- indexes --
CREATE INDEX idx_product_name ON products(name);

CREATE UNIQUE INDEX idx_unique_invoice_no ON orders(invoice_no);
CREATE INDEX idx_composite_order_date_total ON orders(order_date,total);