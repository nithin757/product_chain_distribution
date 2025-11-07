DELIMITER //

CREATE PROCEDURE get_distributor_orders(IN p_distributor_id INT)
BEGIN
    SELECT 
        do.*
    FROM distributor_orders do
    JOIN order_item oi ON do.order_item_id = oi.order_item_id
    WHERE oi.seller_id = p_distributor_id;
END //

DELIMITER ;

-- Grant execute permission
GRANT EXECUTE ON PROCEDURE get_distributor_orders TO 'distributor_role';
