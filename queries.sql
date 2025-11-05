
-- =====================================================
-- STORED PROCEDURES, TRIGGERS, AND COMPLEX QUERIES
-- Product Chain Distribution System
-- =====================================================

USE product_chain_distribution;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- 1. Procedure to create a new allocation from manufacturer to distributor
DELIMITER //
CREATE PROCEDURE AllocateProductToDistributor(
    IN p_manufacturer_id INT,
    IN p_distributor_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_unit_price DECIMAL(10,2)
)
BEGIN
    DECLARE available_qty INT;

    -- Check if manufacturer has sufficient inventory
    SELECT quantity_available INTO available_qty
    FROM inventory
    WHERE product_id = p_product_id AND manufacturer_id = p_manufacturer_id;

    IF available_qty >= p_quantity THEN
        -- Create allocation
        INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, unit_price, status)
        VALUES (p_manufacturer_id, p_distributor_id, p_product_id, p_quantity, p_unit_price, 'completed');

        -- Update manufacturer inventory
        UPDATE inventory
        SET quantity_available = quantity_available - p_quantity
        WHERE product_id = p_product_id AND manufacturer_id = p_manufacturer_id;

        -- Update or insert distributor inventory
        INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, unit_price)
        VALUES (p_distributor_id, p_product_id, p_quantity, p_unit_price * 1.10)
        ON DUPLICATE KEY UPDATE 
            quantity_available = quantity_available + p_quantity,
            unit_price = p_unit_price * 1.10;

        SELECT 'Allocation successful' AS message;
    ELSE
        SELECT 'Insufficient inventory' AS message;
    END IF;
END//
DELIMITER ;

-- 2. Procedure to place customer order
DELIMITER //
CREATE PROCEDURE PlaceCustomerOrder(
    IN p_customer_id INT,
    IN p_product_id INT,
    IN p_quantity INT,
    IN p_seller_type ENUM('manufacturer', 'distributor'),
    IN p_seller_id INT,
    IN p_shipping_address VARCHAR(300)
)
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_unit_price DECIMAL(10,2);
    DECLARE v_available_qty INT;

    -- Get available quantity and price based on seller type
    IF p_seller_type = 'manufacturer' THEN
        SELECT i.quantity_available, p.unit_price INTO v_available_qty, v_unit_price
        FROM inventory i
        JOIN product p ON i.product_id = p.product_id
        WHERE i.product_id = p_product_id AND i.manufacturer_id = p_seller_id;
    ELSE
        SELECT quantity_available, unit_price INTO v_available_qty, v_unit_price
        FROM distributor_inventory
        WHERE product_id = p_product_id AND distributor_id = p_seller_id;
    END IF;

    -- Check if sufficient quantity is available
    IF v_available_qty >= p_quantity THEN
        -- Create order
        INSERT INTO customer_order (customer_id, total_amount, shipping_address)
        VALUES (p_customer_id, p_quantity * v_unit_price, p_shipping_address);

        SET v_order_id = LAST_INSERT_ID();

        -- Add order item
        INSERT INTO order_item (order_id, product_id, seller_type, seller_id, quantity, unit_price)
        VALUES (v_order_id, p_product_id, p_seller_type, p_seller_id, p_quantity, v_unit_price);

        -- Update inventory
        IF p_seller_type = 'manufacturer' THEN
            UPDATE inventory
            SET quantity_available = quantity_available - p_quantity
            WHERE product_id = p_product_id AND manufacturer_id = p_seller_id;
        ELSE
            UPDATE distributor_inventory
            SET quantity_available = quantity_available - p_quantity
            WHERE product_id = p_product_id AND distributor_id = p_seller_id;
        END IF;

        SELECT v_order_id AS order_id, 'Order placed successfully' AS message;
    ELSE
        SELECT 'Insufficient stock' AS message;
    END IF;
END//
DELIMITER ;

-- 3. Procedure to get inventory status
DELIMITER //
CREATE PROCEDURE GetInventoryStatus(IN p_manufacturer_id INT)
BEGIN
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        i.quantity_available,
        i.reorder_level,
        CASE 
            WHEN i.quantity_available <= i.reorder_level THEN 'Low Stock'
            WHEN i.quantity_available <= i.reorder_level * 2 THEN 'Medium Stock'
            ELSE 'Good Stock'
        END AS stock_status
    FROM inventory i
    JOIN product p ON i.product_id = p.product_id
    WHERE i.manufacturer_id = p_manufacturer_id
    ORDER BY stock_status, p.product_name;
END//
DELIMITER ;

-- 4. Procedure to get customer order history
DELIMITER //
CREATE PROCEDURE GetCustomerOrderHistory(IN p_customer_id INT)
BEGIN
    SELECT 
        co.order_id,
        co.order_date,
        co.total_amount,
        co.order_status,
        co.payment_status,
        GROUP_CONCAT(CONCAT(p.product_name, ' (', oi.quantity, ')') SEPARATOR ', ') AS products
    FROM customer_order co
    JOIN order_item oi ON co.order_id = oi.order_id
    JOIN product p ON oi.product_id = p.product_id
    WHERE co.customer_id = p_customer_id
    GROUP BY co.order_id
    ORDER BY co.order_date DESC;
END//
DELIMITER ;

-- 5. Procedure to calculate distributor performance
DELIMITER //
CREATE PROCEDURE GetDistributorPerformance(IN p_distributor_id INT)
BEGIN
    SELECT 
        d.company_name,
        COUNT(DISTINCT a.allocation_id) AS total_allocations,
        SUM(a.total_amount) AS total_purchase_value,
        COUNT(DISTINCT di.product_id) AS unique_products,
        SUM(di.quantity_available) AS current_inventory,
        SUM(di.quantity_available * di.unit_price) AS inventory_value
    FROM distributor d
    LEFT JOIN allocation a ON d.distributor_id = a.distributor_id
    LEFT JOIN distributor_inventory di ON d.distributor_id = di.distributor_id
    WHERE d.distributor_id = p_distributor_id
    GROUP BY d.distributor_id, d.company_name;
END//
DELIMITER ;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- 1. Trigger to update order total when order item is inserted
DELIMITER //
CREATE TRIGGER after_order_item_insert
AFTER INSERT ON order_item
FOR EACH ROW
BEGIN
    UPDATE customer_order
    SET total_amount = (
        SELECT SUM(subtotal)
        FROM order_item
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END//
DELIMITER ;

-- 2. Trigger to check reorder level and log when inventory is low
DELIMITER //
CREATE TRIGGER after_inventory_update
AFTER UPDATE ON inventory
FOR EACH ROW
BEGIN
    IF NEW.quantity_available <= NEW.reorder_level THEN
        INSERT INTO reorder_log (product_id, manufacturer_id, quantity_needed, status)
        VALUES (
            NEW.product_id, 
            NEW.manufacturer_id, 
            NEW.reorder_level * 2 - NEW.quantity_available,
            'pending'
        );
    END IF;
END//
DELIMITER ;

-- 3. Trigger to log user login
DELIMITER //
CREATE TRIGGER after_user_login
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.last_login <> OLD.last_login OR OLD.last_login IS NULL THEN
        INSERT INTO audit_log (table_name, operation, user_id, old_value, new_value)
        VALUES (
            'users',
            'UPDATE',
            NEW.user_id,
            CONCAT('Last login: ', IFNULL(OLD.last_login, 'Never')),
            CONCAT('Last login: ', NEW.last_login)
        );
    END IF;
END//
DELIMITER ;

-- 4. Trigger to update payment status in order
DELIMITER //
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payment
FOR EACH ROW
BEGIN
    IF NEW.payment_status = 'success' THEN
        UPDATE customer_order
        SET payment_status = 'paid'
        WHERE order_id = NEW.order_id;
    END IF;
END//
DELIMITER ;

-- 5. Trigger to create shipment when order is confirmed
DELIMITER //
CREATE TRIGGER after_order_status_update
AFTER UPDATE ON customer_order
FOR EACH ROW
BEGIN
    IF NEW.order_status = 'processing' AND OLD.order_status = 'pending' THEN
        INSERT INTO shipment (order_id, estimated_delivery_date, tracking_number, carrier, shipment_status)
        VALUES (
            NEW.order_id,
            DATE_ADD(CURDATE(), INTERVAL 7 DAY),
            CONCAT('TRACK-', LPAD(NEW.order_id, 6, '0'), '-', YEAR(CURDATE())),
            'Standard Carrier',
            'preparing'
        );
    END IF;
END//
DELIMITER ;

DELIMITER ;

-- =====================================================
-- COMPLEX QUERIES
-- =====================================================

-- BASIC QUERIES

-- 1. Get all products with manufacturer details
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    m.company_name AS manufacturer,
    m.city,
    m.country
FROM product p
JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
ORDER BY p.category, p.product_name;

-- 2. Get all active users by type
SELECT 
    user_type,
    username,
    email,
    phone,
    created_at
FROM users
WHERE is_active = TRUE
ORDER BY user_type, username;

-- 3. Get products within a price range
SELECT 
    product_name,
    category,
    unit_price,
    description
FROM product
WHERE unit_price BETWEEN 50 AND 150
ORDER BY unit_price;

-- =====================================================
-- AGGREGATE QUERIES
-- =====================================================

-- 4. Total sales by product
SELECT 
    p.product_name,
    p.category,
    COUNT(oi.order_item_id) AS total_orders,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.subtotal) AS total_revenue,
    AVG(oi.unit_price) AS avg_selling_price,
    MIN(oi.unit_price) AS min_price,
    MAX(oi.unit_price) AS max_price
FROM product p
LEFT JOIN order_item oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING total_revenue > 0
ORDER BY total_revenue DESC;

-- 5. Monthly order summary
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(order_id) AS total_orders,
    SUM(total_amount) AS total_sales,
    AVG(total_amount) AS avg_order_value,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_order
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month DESC;

-- 6. Customer purchase statistics
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    COUNT(DISTINCT co.order_id) AS total_orders,
    SUM(co.total_amount) AS total_spent,
    AVG(co.total_amount) AS avg_order_value,
    MAX(co.order_date) AS last_order_date,
    c.loyalty_points
FROM customer c
LEFT JOIN customer_order co ON c.customer_id = co.customer_id
GROUP BY c.customer_id
HAVING total_orders > 0
ORDER BY total_spent DESC;

-- 7. Inventory value by manufacturer
SELECT 
    m.company_name,
    COUNT(DISTINCT i.product_id) AS total_products,
    SUM(i.quantity_available) AS total_units,
    SUM(i.quantity_available * p.unit_price) AS total_inventory_value,
    AVG(i.quantity_available) AS avg_stock_per_product
FROM manufacturer m
JOIN inventory i ON m.manufacturer_id = i.manufacturer_id
JOIN product p ON i.product_id = p.product_id
GROUP BY m.manufacturer_id, m.company_name
ORDER BY total_inventory_value DESC;

-- =====================================================
-- JOIN QUERIES
-- =====================================================

-- 8. INNER JOIN: Get all completed orders with customer and product details
SELECT 
    co.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    co.order_date,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    co.order_status,
    s.shipment_status,
    s.tracking_number
FROM customer_order co
INNER JOIN customer c ON co.customer_id = c.customer_id
INNER JOIN order_item oi ON co.order_id = oi.order_id
INNER JOIN product p ON oi.product_id = p.product_id
INNER JOIN shipment s ON co.order_id = s.order_id
WHERE co.order_status IN ('shipped', 'delivered')
ORDER BY co.order_date DESC;

-- 9. LEFT JOIN: All distributors and their inventory (including those with no inventory)
SELECT 
    d.distributor_id,
    d.company_name,
    d.city,
    d.country,
    COALESCE(p.product_name, 'No Inventory') AS product_name,
    COALESCE(di.quantity_available, 0) AS quantity,
    COALESCE(di.unit_price, 0) AS price
FROM distributor d
LEFT JOIN distributor_inventory di ON d.distributor_id = di.distributor_id
LEFT JOIN product p ON di.product_id = p.product_id
ORDER BY d.company_name, p.product_name;

-- 10. RIGHT JOIN: All products and their allocations (including unallocated products)
SELECT 
    p.product_id,
    p.product_name,
    m.company_name AS manufacturer,
    COALESCE(d.company_name, 'Not Allocated') AS distributor,
    COALESCE(a.allocated_quantity, 0) AS allocated_qty,
    COALESCE(a.status, 'N/A') AS allocation_status
FROM allocation a
RIGHT JOIN product p ON a.product_id = p.product_id
LEFT JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
LEFT JOIN distributor d ON a.distributor_id = d.distributor_id
ORDER BY p.product_name;

-- 11. Multiple JOIN: Complete order flow from customer to manufacturer
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    co.order_id,
    co.order_date,
    p.product_name,
    m.company_name AS manufacturer,
    oi.seller_type,
    CASE 
        WHEN oi.seller_type = 'distributor' THEN d.company_name
        ELSE m.company_name
    END AS seller_name,
    oi.quantity,
    oi.subtotal,
    pay.payment_method,
    pay.payment_status,
    s.tracking_number,
    s.shipment_status
FROM customer_order co
JOIN customer c ON co.customer_id = c.customer_id
JOIN order_item oi ON co.order_id = oi.order_id
JOIN product p ON oi.product_id = p.product_id
JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
LEFT JOIN distributor d ON oi.seller_id = d.distributor_id AND oi.seller_type = 'distributor'
LEFT JOIN payment pay ON co.order_id = pay.order_id
LEFT JOIN shipment s ON co.order_id = s.order_id
ORDER BY co.order_date DESC;

-- =====================================================
-- NESTED QUERIES / SUBQUERIES
-- =====================================================

-- 12. Products with above-average prices
SELECT 
    product_name,
    category,
    unit_price,
    (SELECT AVG(unit_price) FROM product) AS avg_price,
    unit_price - (SELECT AVG(unit_price) FROM product) AS price_difference
FROM product
WHERE unit_price > (SELECT AVG(unit_price) FROM product)
ORDER BY unit_price DESC;

-- 13. Customers who spent more than average
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    (SELECT SUM(total_amount) FROM customer_order WHERE customer_id = c.customer_id) AS total_spent
FROM customer c
WHERE (SELECT SUM(total_amount) FROM customer_order WHERE customer_id = c.customer_id) > 
      (SELECT AVG(order_total) FROM (SELECT SUM(total_amount) AS order_total FROM customer_order GROUP BY customer_id) AS avg_customer_spending)
ORDER BY total_spent DESC;

-- 14. Products never ordered
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    m.company_name AS manufacturer
FROM product p
JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
WHERE p.product_id NOT IN (SELECT DISTINCT product_id FROM order_item)
ORDER BY p.category, p.product_name;

-- 15. Distributors with highest inventory value
SELECT 
    d.distributor_id,
    d.company_name,
    d.city,
    (SELECT SUM(di.quantity_available * di.unit_price) 
     FROM distributor_inventory di 
     WHERE di.distributor_id = d.distributor_id) AS inventory_value
FROM distributor d
WHERE (SELECT SUM(di.quantity_available * di.unit_price) 
       FROM distributor_inventory di 
       WHERE di.distributor_id = d.distributor_id) IS NOT NULL
ORDER BY inventory_value DESC;

-- 16. Top selling products by category
SELECT 
    p.category,
    p.product_name,
    (SELECT SUM(oi.quantity) 
     FROM order_item oi 
     WHERE oi.product_id = p.product_id) AS total_sold,
    (SELECT SUM(oi.subtotal) 
     FROM order_item oi 
     WHERE oi.product_id = p.product_id) AS total_revenue
FROM product p
WHERE (SELECT SUM(oi.quantity) FROM order_item oi WHERE oi.product_id = p.product_id) IS NOT NULL
ORDER BY p.category, total_sold DESC;

-- 17. Manufacturers with low inventory products
SELECT 
    m.manufacturer_id,
    m.company_name,
    (SELECT COUNT(*) 
     FROM inventory i 
     WHERE i.manufacturer_id = m.manufacturer_id 
     AND i.quantity_available <= i.reorder_level) AS low_stock_products,
    (SELECT COUNT(*) 
     FROM inventory i 
     WHERE i.manufacturer_id = m.manufacturer_id) AS total_products
FROM manufacturer m
HAVING low_stock_products > 0
ORDER BY low_stock_products DESC;
