-- =====================================================
-- COMPREHENSIVE QUERIES FOR UPDATED SCHEMA
-- =====================================================
-- Supporting all new features:
-- - SKU field in products
-- - Rating field in products
-- - cost_price in distributor_inventory
-- - reorder_level in distributor_inventory
-- - price_change_history table
-- - Distributor order visibility
-- =====================================================

USE product_chain_distribution;

-- ===========================
-- SECTION 1: AUTHENTICATION QUERIES
-- ===========================

-- 1.1 User Login (with all details)
SELECT u.user_id, u.username, u.user_type, u.email, u.phone, u.last_login
FROM users u
WHERE u.username = 'nike_mfg' AND u.password = SHA2('nike123', 256);

-- 1.2 Get Manufacturer ID from User
SELECT m.manufacturer_id, m.company_name, m.address, m.city, m.state
FROM manufacturer m
WHERE m.user_id = 1;

-- 1.3 Get Distributor ID from User
SELECT d.distributor_id, d.company_name, d.credit_limit
FROM distributor d
WHERE d.user_id = 5;

-- 1.4 Get Customer ID from User
SELECT c.customer_id, c.first_name, c.last_name, c.email, c.phone, c.loyalty_points
FROM customer c
WHERE c.user_id = 11;

-- ===========================
-- SECTION 2: MANUFACTURER QUERIES
-- ===========================

-- 2.1 Get All Products with SKU and Rating
SELECT p.product_id, p.product_name, p.sku, p.category, p.unit_price, 
       p.manufacturing_cost, p.rating, p.total_reviews, p.description
FROM product p
WHERE p.manufacturer_id = 1
ORDER BY p.category, p.product_name;

-- 2.2 Get Manufacturer Inventory with Details
SELECT i.inventory_id, p.product_name, p.sku, i.quantity_available, i.reorder_level,
       p.unit_price, (i.quantity_available * p.unit_price) as inventory_value,
       CASE WHEN i.quantity_available <= i.reorder_level THEN 'LOW STOCK' ELSE 'OK' END as stock_status
FROM inventory i
JOIN product p ON i.product_id = p.product_id
WHERE i.manufacturer_id = 1
ORDER BY i.quantity_available ASC;

-- 2.3 Get Low Stock Items (Alert)
SELECT i.inventory_id, p.product_name, p.sku, i.quantity_available, i.reorder_level,
       (i.reorder_level - i.quantity_available) as quantity_to_order
FROM inventory i
JOIN product p ON i.product_id = p.product_id
WHERE i.manufacturer_id = 1 AND i.quantity_available <= i.reorder_level
ORDER BY quantity_to_order DESC;

-- 2.4 Get All Allocations Made by Manufacturer
SELECT a.allocation_id, d.company_name, p.product_name, p.sku, a.allocated_quantity,
       a.unit_price, a.total_amount, a.allocation_date, a.status
FROM allocation a
JOIN distributor d ON a.distributor_id = d.distributor_id
JOIN product p ON a.product_id = p.product_id
WHERE a.manufacturer_id = 1
ORDER BY a.allocation_date DESC;

-- 2.5 Allocate Product to Distributor (Template for INSERT)
-- INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, unit_price, status)
-- VALUES (1, 1, 1, 100, 150.00, 'completed');

-- 2.6 Get Total Inventory Value
SELECT manufacturer_id, 
       COUNT(DISTINCT product_id) as total_products,
       SUM(quantity_available) as total_units,
       ROUND(SUM(quantity_available * (SELECT unit_price FROM product WHERE product_id = inventory.product_id)), 2) as total_value
FROM inventory
WHERE manufacturer_id = 1
GROUP BY manufacturer_id;

-- 2.7 Get Top Products by Rating
SELECT p.product_id, p.product_name, p.sku, p.category, p.rating, 
       p.total_reviews, p.unit_price
FROM product p
WHERE p.manufacturer_id = 1
ORDER BY p.rating DESC, p.total_reviews DESC
LIMIT 10;

-- ===========================
-- SECTION 3: DISTRIBUTOR QUERIES (NEW - ORDERS & PRICING)
-- ===========================

-- 3.1 Get All Customer Orders from This Distributor
SELECT DISTINCT co.order_id, co.order_date, c.first_name, c.last_name, c.email,
       COUNT(oi.order_item_id) as item_count, co.total_amount,
       co.order_status, co.payment_status, s.tracking_number, s.shipment_status
FROM customer_order co
JOIN customer c ON co.customer_id = c.customer_id
JOIN order_item oi ON co.order_id = oi.order_id
LEFT JOIN shipment s ON co.order_id = s.order_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
GROUP BY co.order_id
ORDER BY co.order_date DESC;

-- 3.2 Get Single Order Details with All Information
SELECT co.order_id, co.order_date, c.first_name, c.last_name, c.email, c.phone,
       c.address, c.city, c.state, co.total_amount, co.order_status, co.payment_status,
       co.shipping_address, p.payment_method, p.payment_status as payment_method_status,
       s.tracking_number, s.carrier, s.shipment_status, s.estimated_delivery_date
FROM customer_order co
JOIN customer c ON co.customer_id = c.customer_id
LEFT JOIN payment p ON co.order_id = p.order_id
LEFT JOIN shipment s ON co.order_id = s.order_id
WHERE co.order_id = 1;

-- 3.3 Get Order Items with Product Details
SELECT oi.order_item_id, p.product_name, p.sku, p.category, oi.quantity, 
       oi.unit_price, oi.subtotal
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
WHERE oi.order_id = 1 AND oi.seller_type = 'distributor' AND oi.seller_id = 1;

-- 3.4 Get Distributor Inventory (with NEW cost_price and reorder_level)
SELECT di.dist_inventory_id, p.product_name, p.sku, p.category,
       di.quantity_available, di.cost_price, di.unit_price, di.reorder_level,
       ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as markup_percent,
       (di.quantity_available * di.unit_price) as inventory_value,
       CASE WHEN di.quantity_available <= di.reorder_level THEN 'LOW STOCK' ELSE 'OK' END as stock_status
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
WHERE di.distributor_id = 1
ORDER BY p.product_name;

-- 3.5 Get Products Below Reorder Level (Low Stock Alert)
SELECT di.dist_inventory_id, p.product_name, p.sku, di.quantity_available, 
       di.reorder_level, (di.reorder_level - di.quantity_available) as shortage,
       m.company_name as manufacturer
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
WHERE di.distributor_id = 1 AND di.quantity_available <= di.reorder_level
ORDER BY shortage DESC;

-- 3.6 Get All Product Prices (with cost, retail, and markup)
SELECT di.dist_inventory_id, p.product_name, p.sku, p.category,
       di.cost_price, di.unit_price, 
       ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as markup_percent,
       ROUND(di.cost_price * 1.10, 2) as minimum_price,
       CASE WHEN ((di.unit_price - di.cost_price) / di.cost_price * 100) >= 10 THEN 'OK' 
            ELSE 'BELOW MINIMUM' END as price_status
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
WHERE di.distributor_id = 1
ORDER BY p.product_name;

-- 3.7 Get Price Change History (NEW - for audit trail)
SELECT pch.price_history_id, p.product_name, p.sku,
       pch.old_price, pch.new_price, 
       ROUND(pch.old_markup_percent, 2) as old_markup,
       ROUND(pch.new_markup_percent, 2) as new_markup,
       pch.change_reason, pch.changed_by, pch.changed_at
FROM price_change_history pch
JOIN product p ON pch.product_id = p.product_id
WHERE pch.distributor_id = 1
ORDER BY pch.changed_at DESC;

-- 3.8 Get Revenue Summary
SELECT COUNT(DISTINCT co.order_id) as total_orders,
       SUM(co.total_amount) as total_revenue,
       AVG(co.total_amount) as avg_order_value,
       MIN(co.total_amount) as min_order,
       MAX(co.total_amount) as max_order,
       COUNT(DISTINCT co.customer_id) as total_customers
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
AND co.order_status = 'delivered';

-- 3.9 Get Monthly Revenue
SELECT YEAR(co.order_date) as year, MONTH(co.order_date) as month,
       COUNT(co.order_id) as order_count,
       SUM(co.total_amount) as monthly_revenue
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
GROUP BY YEAR(co.order_date), MONTH(co.order_date)
ORDER BY year DESC, month DESC;

-- 3.10 Get Top Selling Products
SELECT p.product_name, p.sku, p.category, p.rating,
       SUM(oi.quantity) as units_sold,
       SUM(oi.subtotal) as revenue
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
GROUP BY p.product_id
ORDER BY units_sold DESC
LIMIT 10;

-- 3.11 Get Top Customers
SELECT c.first_name, c.last_name, c.email, c.phone,
       COUNT(co.order_id) as order_count,
       SUM(co.total_amount) as total_spent
FROM customer_order co
JOIN customer c ON co.customer_id = c.customer_id
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
GROUP BY c.customer_id
ORDER BY total_spent DESC
LIMIT 10;

-- 3.12 Get Orders by Status
SELECT co.order_status, COUNT(co.order_id) as count,
       SUM(co.total_amount) as total_amount
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'distributor' AND oi.seller_id = 1
GROUP BY co.order_status;

-- 3.13 Get Allocations Received (Products Received from Manufacturers)
SELECT a.allocation_id, m.company_name as manufacturer, p.product_name, p.sku,
       a.allocated_quantity, a.unit_price, a.total_amount, a.allocation_date, a.status
FROM allocation a
JOIN manufacturer m ON a.manufacturer_id = m.manufacturer_id
JOIN product p ON a.product_id = p.product_id
WHERE a.distributor_id = 1
ORDER BY a.allocation_date DESC;

-- 3.14 Get Inventory Value by Category
SELECT p.category,
       COUNT(DISTINCT p.product_id) as product_count,
       SUM(di.quantity_available) as total_units,
       ROUND(SUM(di.quantity_available * di.unit_price), 2) as category_value
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
WHERE di.distributor_id = 1
GROUP BY p.category
ORDER BY category_value DESC;

-- ===========================
-- SECTION 4: PRICING QUERIES (NEW)
-- ===========================

-- 4.1 Update Product Price (validate minimum 10% markup)
-- SELECT new_price, 
--        CASE WHEN ((new_price - cost_price) / cost_price * 100) >= 10 THEN 'VALID' 
--            ELSE 'INVALID - Below 10% markup' END as validation
-- FROM distributor_inventory
-- WHERE dist_inventory_id = 1;

-- 4.2 Get Products with Low Markup (below 10%)
SELECT di.dist_inventory_id, p.product_name, p.sku, di.cost_price, di.unit_price,
       ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as current_markup,
       ROUND(di.cost_price * 1.10, 2) as required_minimum
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
WHERE di.distributor_id = 1 
AND ((di.unit_price - di.cost_price) / di.cost_price * 100) < 10;

-- 4.3 Get Recent Price Changes
SELECT pch.price_history_id, p.product_name, p.sku,
       pch.old_price, pch.new_price, 
       ROUND(pch.old_markup_percent, 2) as old_markup,
       ROUND(pch.new_markup_percent, 2) as new_markup,
       pch.change_reason, pch.changed_at
FROM price_change_history pch
JOIN product p ON pch.product_id = p.product_id
WHERE pch.distributor_id = 1
ORDER BY pch.changed_at DESC
LIMIT 20;

-- 4.4 Get Price Statistics
SELECT 
       MIN(di.cost_price) as min_cost,
       MAX(di.cost_price) as max_cost,
       AVG(di.cost_price) as avg_cost,
       MIN(di.unit_price) as min_retail,
       MAX(di.unit_price) as max_retail,
       AVG(di.unit_price) as avg_retail,
       ROUND(AVG((di.unit_price - di.cost_price) / di.cost_price * 100), 2) as avg_markup
FROM distributor_inventory di
WHERE di.distributor_id = 1;

-- ===========================
-- SECTION 5: CUSTOMER QUERIES
-- ===========================

-- 5.1 Get Customer Order History (with email & phone)
SELECT co.order_id, co.order_date, co.total_amount, co.order_status, co.payment_status
FROM customer_order co
WHERE co.customer_id = 11
ORDER BY co.order_date DESC;

-- 5.2 Get All Available Products (with rating and SKU)
SELECT p.product_id, p.product_name, p.sku, p.category, p.description,
       p.unit_price, p.rating, p.total_reviews,
       CASE WHEN di.quantity_available > 0 THEN 'Available from Distributor'
            WHEN i.quantity_available > 0 THEN 'Available from Manufacturer'
            ELSE 'Out of Stock' END as availability
FROM product p
LEFT JOIN distributor_inventory di ON p.product_id = di.product_id AND di.quantity_available > 0
LEFT JOIN inventory i ON p.product_id = i.product_id AND i.quantity_available > 0
WHERE di.dist_inventory_id IS NOT NULL OR i.inventory_id IS NOT NULL
ORDER BY p.category, p.rating DESC;

-- 5.3 Browse Products by Category
SELECT p.product_id, p.product_name, p.sku, p.unit_price, p.rating, p.total_reviews
FROM product p
WHERE p.category = 'Footwear'
ORDER BY p.rating DESC, p.product_name;

-- 5.4 Search Products by Name
SELECT p.product_id, p.product_name, p.sku, p.category, p.unit_price, 
       p.rating, p.description
FROM product p
WHERE p.product_name LIKE '%Nike%' OR p.sku LIKE '%NIKE%'
ORDER BY p.rating DESC;

-- ===========================
-- SECTION 6: ANALYTICS QUERIES
-- ===========================

-- 6.1 Get Distributor Sales Summary
SELECT d.distributor_id, d.company_name,
       COUNT(DISTINCT co.order_id) as total_orders,
       SUM(oi.quantity) as total_units_sold,
       SUM(co.total_amount) as total_revenue,
       COUNT(DISTINCT co.customer_id) as unique_customers,
       AVG(co.total_amount) as avg_order_value
FROM distributor d
LEFT JOIN order_item oi ON d.distributor_id = oi.seller_id AND oi.seller_type = 'distributor'
LEFT JOIN customer_order co ON oi.order_id = co.order_id
GROUP BY d.distributor_id
ORDER BY total_revenue DESC;

-- 6.2 Get Best Selling Products Across All Distributors
SELECT p.product_id, p.product_name, p.sku, p.category, p.rating,
       SUM(oi.quantity) as total_units_sold,
       SUM(oi.subtotal) as total_revenue
FROM order_item oi
JOIN product p ON oi.product_id = p.product_id
WHERE oi.seller_type = 'distributor'
GROUP BY p.product_id
ORDER BY total_units_sold DESC
LIMIT 10;

-- 6.3 Get Product Performance by Category
SELECT p.category,
       COUNT(DISTINCT p.product_id) as product_count,
       AVG(p.rating) as avg_rating,
       SUM(oi.quantity) as total_units_sold,
       SUM(oi.subtotal) as total_revenue
FROM product p
LEFT JOIN order_item oi ON p.product_id = oi.product_id AND oi.seller_type = 'distributor'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 6.4 Get Low Stock Alert Across All Distributors
SELECT d.company_name, p.product_name, p.sku, di.quantity_available,
       di.reorder_level, (di.reorder_level - di.quantity_available) as shortage
FROM distributor_inventory di
JOIN distributor d ON di.distributor_id = d.distributor_id
JOIN product p ON di.product_id = p.product_id
WHERE di.quantity_available <= di.reorder_level
ORDER BY d.company_name, shortage DESC;

-- 6.5 Get Revenue Comparison (Distributor vs Manufacturer Direct)
SELECT 'Distributor' as source,
       COUNT(DISTINCT co.order_id) as orders,
       SUM(co.total_amount) as revenue
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'distributor'
UNION ALL
SELECT 'Manufacturer' as source,
       COUNT(DISTINCT co.order_id) as orders,
       SUM(co.total_amount) as revenue
FROM customer_order co
JOIN order_item oi ON co.order_id = oi.order_id
WHERE oi.seller_type = 'manufacturer'
ORDER BY revenue DESC;

-- ===========================
-- SECTION 7: REPORTING QUERIES
-- ===========================

-- 7.1 Generate Daily Sales Report
SELECT DATE(co.order_date) as date,
       COUNT(co.order_id) as orders,
       SUM(co.total_amount) as revenue,
       COUNT(DISTINCT co.customer_id) as customers
FROM customer_order co
WHERE co.order_status = 'delivered'
GROUP BY DATE(co.order_date)
ORDER BY date DESC
LIMIT 30;

-- 7.2 Generate Monthly Revenue Report
SELECT DATE_FORMAT(co.order_date, '%Y-%m') as month,
       COUNT(co.order_id) as orders,
       SUM(co.total_amount) as revenue,
       AVG(co.total_amount) as avg_order_value
FROM customer_order co
WHERE co.order_status = 'delivered'
GROUP BY DATE_FORMAT(co.order_date, '%Y-%m')
ORDER BY month DESC;

-- 7.3 Inventory Valuation Report
SELECT p.category,
       COUNT(p.product_id) as products,
       SUM(i.quantity_available) as mfg_units,
       SUM(di.quantity_available) as dist_units,
       ROUND(SUM(i.quantity_available * p.unit_price), 2) as mfg_value,
       ROUND(SUM(di.quantity_available * di.unit_price), 2) as dist_value
FROM product p
LEFT JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN distributor_inventory di ON p.product_id = di.product_id
GROUP BY p.category
ORDER BY category;

-- 7.4 Product Markup Analysis
SELECT p.product_name, p.sku, p.category,
       COUNT(DISTINCT di.distributor_id) as distributors_carrying,
       ROUND(AVG((di.unit_price - di.cost_price) / di.cost_price * 100), 2) as avg_markup,
       ROUND(MIN((di.unit_price - di.cost_price) / di.cost_price * 100), 2) as min_markup,
       ROUND(MAX((di.unit_price - di.cost_price) / di.cost_price * 100), 2) as max_markup
FROM product p
JOIN distributor_inventory di ON p.product_id = di.product_id
GROUP BY p.product_id
ORDER BY avg_markup DESC;

-- 7.5 Customer Segmentation
SELECT 
       COUNT(DISTINCT customer_id) as total_customers,
       SUM(CASE WHEN order_count = 1 THEN 1 ELSE 0 END) as single_purchase,
       SUM(CASE WHEN order_count >= 2 AND order_count <= 5 THEN 1 ELSE 0 END) as repeat_2to5,
       SUM(CASE WHEN order_count > 5 THEN 1 ELSE 0 END) as loyal_5plus,
       SUM(CASE WHEN total_spent > 1000 THEN 1 ELSE 0 END) as high_value
FROM (
    SELECT c.customer_id,
           COUNT(co.order_id) as order_count,
           SUM(co.total_amount) as total_spent
    FROM customer c
    LEFT JOIN customer_order co ON c.customer_id = co.customer_id
    GROUP BY c.customer_id
) AS customer_stats;

-- ===========================
-- SECTION 8: DASHBOARD QUERIES
-- ===========================

-- 8.1 Distributor Dashboard Summary (All Stats)
SELECT 
    (SELECT COUNT(DISTINCT product_id) FROM distributor_inventory WHERE distributor_id = 1) as products_in_stock,
    (SELECT SUM(quantity_available) FROM distributor_inventory WHERE distributor_id = 1) as total_units,
    (SELECT ROUND(SUM(quantity_available * unit_price), 2) FROM distributor_inventory WHERE distributor_id = 1) as inventory_value,
    (SELECT COUNT(DISTINCT order_id) FROM customer_order co JOIN order_item oi ON co.order_id = oi.order_id WHERE oi.seller_id = 1 AND oi.seller_type = 'distributor') as total_orders,
    (SELECT ROUND(SUM(co.total_amount), 2) FROM customer_order co JOIN order_item oi ON co.order_id = oi.order_id WHERE oi.seller_id = 1 AND oi.seller_type = 'distributor') as total_revenue,
    (SELECT COUNT(*) FROM distributor_inventory WHERE distributor_id = 1 AND quantity_available <= reorder_level) as low_stock_count;

-- 8.2 Manufacturer Dashboard Summary
SELECT 
    (SELECT COUNT(*) FROM product WHERE manufacturer_id = 1) as total_products,
    (SELECT SUM(quantity_available) FROM inventory WHERE manufacturer_id = 1) as total_units,
    (SELECT ROUND(SUM(quantity_available * (SELECT unit_price FROM product p WHERE p.product_id = inventory.product_id)), 2) FROM inventory WHERE manufacturer_id = 1) as inventory_value,
    (SELECT COUNT(*) FROM inventory WHERE manufacturer_id = 1 AND quantity_available <= reorder_level) as low_stock_count;

-- 8.3 Customer Dashboard Summary
SELECT 
    (SELECT COUNT(*) FROM customer_order WHERE customer_id = 11) as total_orders,
    (SELECT ROUND(SUM(total_amount), 2) FROM customer_order WHERE customer_id = 11) as total_spent,
    (SELECT loyalty_points FROM customer WHERE customer_id = 11) as loyalty_points;

-- ===========================
-- SECTION 9: MAINTENANCE QUERIES
-- ===========================

-- 9.1 Check Data Integrity
SELECT 'Orphan Orders' as check_type,
       COUNT(*) as count
FROM customer_order co
WHERE NOT EXISTS (SELECT 1 FROM customer c WHERE c.customer_id = co.customer_id)
UNION ALL
SELECT 'Orphan Order Items',
       COUNT(*)
FROM order_item oi
WHERE NOT EXISTS (SELECT 1 FROM customer_order co WHERE co.order_id = oi.order_id)
UNION ALL
SELECT 'Products Without Inventory',
       COUNT(*)
FROM product p
WHERE NOT EXISTS (SELECT 1 FROM inventory i WHERE i.product_id = p.product_id);

-- 9.2 Verify Markup Compliance (All prices must have >= 10% markup)
SELECT di.dist_inventory_id, p.product_name, p.sku, di.cost_price, di.unit_price,
       ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as markup_percent,
       'NON-COMPLIANT' as status
FROM distributor_inventory di
JOIN product p ON di.product_id = p.product_id
WHERE ((di.unit_price - di.cost_price) / di.cost_price * 100) < 10;

-- 9.3 Find Deleted Products in Orders (should be 0)
SELECT oi.product_id, COUNT(*) as orphan_count
FROM order_item oi
WHERE NOT EXISTS (SELECT 1 FROM product p WHERE p.product_id = oi.product_id)
GROUP BY oi.product_id;

-- ===========================
-- END OF QUERIES
-- ===========================