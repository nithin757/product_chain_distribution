CREATE OR REPLACE VIEW distributor_orders AS
SELECT 
    co.order_id,
    co.order_date,
    co.order_status,
    co.payment_status,
    oi.order_item_id,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    p.product_name,
    c.first_name AS customer_first_name,
    c.last_name AS customer_last_name,
    co.shipping_address,
    co.total_amount
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
JOIN customer c ON co.customer_id = c.customer_id
JOIN product p ON oi.product_id = p.product_id
WHERE oi.seller_type = 'distributor'
ORDER BY co.order_date DESC;

-- Grant permission to access the view
GRANT SELECT ON distributor_orders TO 'distributor_role';
