-- Add index for better performance
USE product_chain_distribution;
CREATE INDEX idx_seller ON order_item(seller_type, seller_id);

-- Add check constraint for quantity
ALTER TABLE order_item
ADD CONSTRAINT chk_quantity_positive CHECK (quantity > 0);

-- Add trigger to validate seller_id
DELIMITER //

CREATE TRIGGER before_order_item_insert 
BEFORE INSERT ON order_item
FOR EACH ROW
BEGIN
    IF NEW.seller_type = 'manufacturer' THEN
        IF NOT EXISTS (SELECT 1 FROM manufacturer WHERE manufacturer_id = NEW.seller_id) THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Invalid manufacturer_id in seller_id';
        END IF;
    ELSEIF NEW.seller_type = 'distributor' THEN
        IF NOT EXISTS (SELECT 1 FROM distributor WHERE distributor_id = NEW.seller_id) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid distributor_id in seller_id';
        END IF;
    END IF;
END //

DELIMITER ;
