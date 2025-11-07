DELIMITER //

CREATE PROCEDURE get_distributor_customer_orders(
    IN p_distributor_id INT,
    IN p_status VARCHAR(20)
)
BEGIN
    IF p_status IS NULL THEN
        SELECT DISTINCT 
            order_id, 
            order_date, 
            customer_first_name,
            customer_last_name,
            total_amount, 
            order_status, 
            payment_status,
            shipment_status
        FROM distributor_order_management_view
        WHERE distributor_id = p_distributor_id
        ORDER BY order_date DESC;
    ELSE
        SELECT DISTINCT 
            order_id, 
            order_date, 
            customer_first_name,
            customer_last_name,
            total_amount, 
            order_status, 
            payment_status,
            shipment_status
        FROM distributor_order_management_view
        WHERE distributor_id = p_distributor_id 
        AND order_status = p_status
        ORDER BY order_date DESC;
    END IF;
END //

DELIMITER ;
