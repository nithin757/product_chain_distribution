DELIMITER //

CREATE PROCEDURE get_order_details(IN p_order_id INT)
BEGIN
    SELECT * FROM order_details_view
    WHERE order_id = p_order_id;
END //

DELIMITER ;
