CREATE OR REPLACE VIEW distributor_order_management_view AS
SELECT 
    co.order_id,
    co.order_date,
    co.order_status,
    co.payment_status,
    co.total_amount,
    co.shipping_address,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id as distributor_id,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    p.product_name,
    c.customer_id,
    c.first_name as customer_first_name,
    c.last_name as customer_last_name,
    s.shipment_status,
    s.tracking_number,
    s.estimated_delivery_date
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
JOIN product p ON oi.product_id = p.product_id
JOIN customer c ON co.customer_id = c.customer_id
LEFT JOIN shipment s ON co.order_id = s.order_id
WHERE oi.seller_type = 'distributor';
