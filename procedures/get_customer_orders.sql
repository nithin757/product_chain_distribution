DELIMITER //

CREATE PROCEDURE get_customer_orders(
    IN p_customer_id INT,
    IN p_status VARCHAR(20)
)
BEGIN
    IF p_status IS NULL THEN
        SELECT DISTINCT 
            order_id, 
            order_date, 
            total_amount, 
            order_status, 
            payment_status,
            shipment_status
        FROM order_details_view
        WHERE customer_id = p_customer_id
        ORDER BY order_date DESC;
    ELSE
        SELECT DISTINCT 
            order_id, 
            order_date, 
            total_amount, 
            order_status, 
            payment_status,
            shipment_status
        FROM order_details_view
        WHERE customer_id = p_customer_id 
        AND order_status = p_status
        ORDER BY order_date DESC;
    END IF;
END //

DELIMITER ;
