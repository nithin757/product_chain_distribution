CREATE OR REPLACE VIEW order_details_view AS
SELECT 
    co.order_id,
    co.customer_id,
    co.order_date,
    co.total_amount,
    co.order_status,
    co.payment_status,
    co.shipping_address,
    oi.order_item_id,
    oi.product_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    oi.seller_type,
    oi.seller_id,
    CASE 
        WHEN oi.seller_type = 'manufacturer' THEN m.company_name
        WHEN oi.seller_type = 'distributor' THEN d.company_name
    END as seller_name,
    s.shipment_status,
    s.tracking_number,
    s.estimated_delivery_date
FROM customer_order co
LEFT JOIN order_item oi ON co.order_id = oi.order_id
LEFT JOIN product p ON oi.product_id = p.product_id
LEFT JOIN manufacturer m ON (oi.seller_id = m.manufacturer_id AND oi.seller_type = 'manufacturer')
LEFT JOIN distributor d ON (oi.seller_id = d.distributor_id AND oi.seller_type = 'distributor')
LEFT JOIN shipment s ON co.order_id = s.order_id;
