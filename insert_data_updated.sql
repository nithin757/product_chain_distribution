-- =====================================================
-- COMPLETE INSERT DATA FOR UPDATED SCHEMA
-- =====================================================
-- Includes: SKU, rating, email/phone in customer, cost_price, reorder_level
-- 15+ insertions per major table
-- =====================================================

USE product_chain_distribution;

-- =====================================================
-- 1. INSERT USERS (15 total)
-- =====================================================



-- =====================================================
-- 2. INSERT MANUFACTURERS (4)
-- =====================================================

INSERT INTO manufacturer (user_id, company_name, address, city, state, country, postal_code, contact_person, registration_number) VALUES
(1, 'Nike Manufacturing Inc.', '123 Industrial Ave', 'Portland', 'Oregon', 'USA', '97209', 'Mike Johnson', 'MFG-NIKE-001'),
(2, 'Adidas Production GmbH', '456 Factory Road', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Hans Mueller', 'MFG-ADIDAS-002'),
(3, 'Puma Sports Manufacturing', '789 Production Lane', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Klaus Schmidt', 'MFG-PUMA-003'),
(4, 'Reebok International Ltd', '321 Sport Street', 'Boston', 'Massachusetts', 'USA', '02110', 'Paul Thompson', 'MFG-REEBOK-004');

-- =====================================================
-- 3. INSERT DISTRIBUTORS (6)
-- =====================================================

INSERT INTO distributor (user_id, company_name, address, city, state, country, postal_code, contact_person, license_number, credit_limit) VALUES
(5, 'Metro Distribution LLC', '321 Warehouse St', 'New York', 'NY', 'USA', '10001', 'Sarah Connor', 'DIST-METRO-001', 500000.00),
(6, 'Global Supply Chain Inc.', '654 Logistics Blvd', 'London', 'England', 'UK', 'E14 5AB', 'James Bond', 'DIST-GLOBAL-002', 750000.00),
(7, 'Rapid Distributors Pvt Ltd', '987 Commerce Park', 'Bangalore', 'Karnataka', 'India', '560001', 'Raj Kumar', 'DIST-RAPID-003', 300000.00),
(8, 'Express Distribution Co.', '246 Trade Center', 'Toronto', 'Ontario', 'Canada', 'M5H 2Y2', 'Michael Chen', 'DIST-EXPRESS-004', 450000.00),
(9, 'Premier Supply Chain', '135 Business Plaza', 'Sydney', 'New South Wales', 'Australia', '2000', 'Emma Wilson', 'DIST-PREMIER-005', 400000.00),
(10, 'Optimal Logistics Solutions', '369 Distribution Way', 'Singapore', 'Singapore', 'Singapore', '018956', 'David Lim', 'DIST-OPTIMAL-006', 550000.00);

-- =====================================================
-- 4. INSERT CUSTOMERS (15)
-- =====================================================

INSERT INTO customer (user_id, first_name, last_name, address, city, state, country, postal_code, phone, email, loyalty_points) VALUES
(11, 'John', 'Doe', '111 Main Street', 'Los Angeles', 'CA', 'USA', '90001', '3334567890', 'john.doe@email.com', 150),
(12, 'Jane', 'Smith', '222 Oak Avenue', 'Chicago', 'IL', 'USA', '60601', '3334567891', 'jane.smith@email.com', 320),
(13, 'Bob', 'Johnson', '333 Pine Road', 'Houston', 'TX', 'USA', '77001', '3334567892', 'bob.j@email.com', 80),
(14, 'Alice', 'Williams', '444 Maple Drive', 'Phoenix', 'AZ', 'USA', '85001', '3334567893', 'alice.w@email.com', 500),
(15, 'Charlie', 'Brown', '555 Elm Street', 'Philadelphia', 'PA', 'USA', '19101', '3334567894', 'charlie.b@email.com', 200),
(16, 'Diana', 'Prince', '666 Cedar Lane', 'San Antonio', 'TX', 'USA', '78201', '3334567895', 'diana.p@email.com', 450),
(17, 'Evan', 'Martin', '777 Birch Blvd', 'San Diego', 'CA', 'USA', '92101', '3334567896', 'evan.m@email.com', 120),
(18, 'Fiona', 'Green', '888 Spruce St', 'Dallas', 'TX', 'USA', '75201', '3334567897', 'fiona.g@email.com', 380),
(19, 'George', 'Davis', '999 Walnut Way', 'San Jose', 'CA', 'USA', '95101', '3334567898', 'george.d@email.com', 160),
(20, 'Hannah', 'Lee', '101 Ash Ave', 'Austin', 'TX', 'USA', '78701', '3334567899', 'hannah.l@email.com', 420),
(21, 'Isaac', 'Harris', '202 Oak Oak', 'Jacksonville', 'FL', 'USA', '32099', '3334567900', 'isaac.h@email.com', 90),
(22, 'Julia', 'Clark', '303 Chestnut', 'Fort Worth', 'TX', 'USA', '76102', '3334567901', 'julia.c@email.com', 280),
(23, 'Kevin', 'Baker', '404 Hazel Hts', 'Columbus', 'OH', 'USA', '43085', '3334567902', 'kevin.b@email.com', 310);

-- =====================================================
-- 5. INSERT PRODUCTS (16 - with SKU and rating)
-- =====================================================

INSERT INTO product (manufacturer_id, product_name, description, category, sku, unit_price, manufacturing_cost, weight, dimensions, rating, total_reviews) VALUES
-- Nike Products (4)
(1, 'Nike Air Max 270', 'Premium running shoes with air cushioning', 'Footwear', 'SKU-NIKE-AM270', 150.00, 60.00, 0.85, '32x20x12 cm', 4.8, 245),
(1, 'Nike Dri-FIT T-Shirt', 'Moisture-wicking athletic t-shirt', 'Apparel', 'SKU-NIKE-DFIT-TS', 35.00, 12.00, 0.25, '40x30x2 cm', 4.5, 180),
(1, 'Nike Pro Shorts', 'Compression training shorts', 'Apparel', 'SKU-NIKE-PRO-SH', 45.00, 15.00, 0.20, '35x25x2 cm', 4.6, 152),
(1, 'Nike Backpack', 'Sports backpack with laptop compartment', 'Accessories', 'SKU-NIKE-BP-001', 80.00, 30.00, 0.60, '45x30x15 cm', 4.7, 198),

-- Adidas Products (4)
(2, 'Adidas Ultraboost 21', 'Energy-returning running shoes', 'Footwear', 'SKU-ADIDAS-UB21', 180.00, 70.00, 0.90, '33x21x13 cm', 4.9, 312),
(2, 'Adidas Training Jersey', 'Breathable sports jersey', 'Apparel', 'SKU-ADIDAS-TJ', 40.00, 14.00, 0.30, '42x32x2 cm', 4.4, 165),
(2, 'Adidas Track Pants', 'Classic three-stripe track pants', 'Apparel', 'SKU-ADIDAS-TP', 60.00, 20.00, 0.40, '45x35x3 cm', 4.5, 198),
(2, 'Adidas Sports Bag', 'Durable gym duffel bag', 'Accessories', 'SKU-ADIDAS-SB', 70.00, 25.00, 0.50, '50x30x25 cm', 4.6, 174),

-- Puma Products (4)
(3, 'Puma RS-X Sneakers', 'Retro-style running sneakers', 'Footwear', 'SKU-PUMA-RSX', 110.00, 45.00, 0.80, '31x20x12 cm', 4.3, 142),
(3, 'Puma Performance Polo', 'Golf and casual polo shirt', 'Apparel', 'SKU-PUMA-POLO', 50.00, 18.00, 0.28, '40x30x2 cm', 4.4, 128),
(3, 'Puma Training Jacket', 'Lightweight training jacket', 'Apparel', 'SKU-PUMA-JACKET', 90.00, 35.00, 0.55, '48x38x3 cm', 4.5, 156),
(3, 'Puma Baseball Cap', 'Adjustable sports cap', 'Accessories', 'SKU-PUMA-CAP', 25.00, 8.00, 0.15, '25x25x10 cm', 4.2, 98),

-- Reebok Products (4)
(4, 'Reebok Flex Running', 'Lightweight and flexible running shoe', 'Footwear', 'SKU-REEBOK-FLEX', 120.00, 50.00, 0.75, '30x19x11 cm', 4.4, 134),
(4, 'Reebok Workout Shirt', 'Classic Reebok workout shirt', 'Apparel', 'SKU-REEBOK-WS', 32.00, 11.00, 0.22, '38x28x2 cm', 4.3, 112),
(4, 'Reebok Training Tights', 'High-waisted training tights', 'Apparel', 'SKU-REEBOK-TT', 55.00, 18.00, 0.35, '42x30x2 cm', 4.5, 144),
(4, 'Reebok Gym Bag', 'Spacious gym bag with compartments', 'Accessories', 'SKU-REEBOK-GB', 65.00, 22.00, 0.55, '48x28x22 cm', 4.4, 121);

-- =====================================================
-- 6. INSERT INVENTORY - Manufacturer (16)
-- =====================================================

INSERT INTO inventory (product_id, manufacturer_id, quantity_available, reorder_level) VALUES
-- Nike
(1, 1, 500, 100),
(2, 1, 1200, 200),
(3, 1, 800, 150),
(4, 1, 300, 80),
-- Adidas
(5, 2, 600, 120),
(6, 2, 1500, 250),
(7, 2, 700, 140),
(8, 2, 250, 60),
-- Puma
(9, 3, 400, 90),
(10, 3, 1000, 180),
(11, 3, 450, 100),
(12, 3, 2000, 300),
-- Reebok
(13, 4, 350, 75),
(14, 4, 900, 150),
(15, 4, 550, 120),
(16, 4, 280, 70);

-- =====================================================
-- 7. INSERT ALLOCATIONS (18 - with proper cost_price)
-- =====================================================

INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, status, unit_price) VALUES
-- Nike to distributors
(1, 1, 1, 100, 'completed', 150.00),
(1, 1, 2, 200, 'completed', 35.00),
(1, 1, 3, 150, 'completed', 45.00),
(1, 2, 1, 80, 'completed', 150.00),
(1, 2, 4, 50, 'completed', 80.00),
(1, 3, 2, 100, 'completed', 35.00),
-- Adidas to distributors
(2, 1, 5, 120, 'completed', 180.00),
(2, 1, 6, 180, 'completed', 40.00),
(2, 3, 5, 100, 'completed', 180.00),
(2, 3, 7, 120, 'completed', 60.00),
(2, 4, 6, 150, 'completed', 40.00),
-- Puma to distributors
(3, 2, 9, 90, 'completed', 110.00),
(3, 2, 10, 150, 'completed', 50.00),
(3, 3, 11, 80, 'completed', 90.00),
(3, 3, 12, 300, 'completed', 25.00),
-- Reebok to distributors
(4, 5, 13, 100, 'completed', 120.00),
(4, 5, 14, 150, 'completed', 32.00),
(4, 6, 15, 120, 'completed', 55.00);

-- =====================================================
-- 8. INSERT DISTRIBUTOR_INVENTORY (18 - with cost_price & reorder_level)
-- =====================================================

INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, cost_price, unit_price, reorder_level) VALUES
-- Metro Distribution (5 products)
(1, 1, 100, 150.00, 165.00, 50),
(1, 2, 200, 35.00, 38.50, 80),
(1, 3, 150, 45.00, 49.50, 60),
(1, 5, 120, 180.00, 198.00, 50),
(1, 6, 180, 40.00, 44.00, 70),

-- Global Supply Chain (4 products)
(2, 1, 80, 150.00, 165.00, 40),
(2, 4, 50, 80.00, 88.00, 25),
(2, 9, 90, 110.00, 121.00, 45),
(2, 10, 150, 50.00, 55.00, 60),

-- Rapid Distributors (4 products)
(3, 5, 100, 180.00, 198.00, 50),
(3, 7, 120, 60.00, 66.00, 50),
(3, 11, 80, 90.00, 99.00, 40),
(3, 12, 300, 25.00, 27.50, 100),

-- Express Distribution (3 products)
(4, 6, 150, 40.00, 44.00, 60),
(4, 14, 150, 32.00, 35.20, 50),

-- Premier Supply Chain (2 products)
(5, 13, 100, 120.00, 132.00, 40),
(5, 14, 150, 32.00, 35.20, 50),

-- Optimal Logistics (2 products)
(6, 15, 120, 55.00, 60.50, 45),
(6, 16, 100, 65.00, 71.50, 35);

-- =====================================================
-- 9. INSERT CUSTOMER_ORDERS (15)
-- =====================================================

INSERT INTO customer_order (customer_id, total_amount, order_status, payment_status, shipping_address) VALUES
(1, 350.00, 'delivered', 'paid', '111 Main Street, Los Angeles, CA 90001'),
(2, 242.00, 'shipped', 'paid', '222 Oak Avenue, Chicago, IL 60601'),
(3, 198.00, 'processing', 'paid', '333 Pine Road, Houston, TX 77001'),
(4, 495.00, 'delivered', 'paid', '444 Maple Drive, Phoenix, AZ 85001'),
(5, 165.00, 'pending', 'pending', '555 Elm Street, Philadelphia, PA 19101'),
(6, 330.00, 'delivered', 'paid', '666 Cedar Lane, San Antonio, TX 78201'),
(7, 279.00, 'shipped', 'paid', '777 Birch Blvd, San Diego, CA 92101'),
(8, 412.50, 'processing', 'paid', '888 Spruce St, Dallas, TX 75201'),
(9, 220.00, 'delivered', 'paid', '999 Walnut Way, San Jose, CA 95101'),
(10, 371.00, 'shipped', 'paid', '101 Ash Ave, Austin, TX 78701'),
(11, 165.00, 'pending', 'pending', '202 Oak Oak, Jacksonville, FL 32099'),
(12, 288.00, 'delivered', 'paid', '303 Chestnut, Fort Worth, TX 76102'),
(13, 442.00, 'processing', 'paid', '404 Hazel Hts, Columbus, OH 43085'),
(1, 275.50, 'delivered', 'paid', '111 Main Street, Los Angeles, CA 90001'),
(2, 220.00, 'shipped', 'paid', '222 Oak Avenue, Chicago, IL 60601');

-- =====================================================
-- 10. INSERT ORDER_ITEMS (20)
-- =====================================================

INSERT INTO order_item (order_id, product_id, seller_type, seller_id, quantity, unit_price) VALUES
-- Order 1
(1, 1, 'distributor', 1, 2, 165.00),
(1, 3, 'manufacturer', 1, 1, 45.00),
-- Order 2
(2, 5, 'distributor', 1, 1, 198.00),
(2, 6, 'distributor', 1, 1, 44.00),
-- Order 3
(3, 5, 'distributor', 1, 1, 198.00),
-- Order 4
(4, 1, 'distributor', 2, 3, 165.00),
-- Order 5
(5, 1, 'distributor', 1, 1, 165.00),
-- Order 6
(6, 2, 'distributor', 1, 2, 38.50),
(6, 4, 'manufacturer', 1, 1, 80.00),
-- Order 7
(7, 9, 'distributor', 2, 1, 121.00),
(7, 10, 'distributor', 2, 3, 55.00),
-- Order 8
(8, 5, 'distributor', 3, 2, 198.00),
(8, 7, 'distributor', 3, 1, 66.00),
-- Order 9
(9, 1, 'distributor', 1, 2, 165.00),
(9, 2, 'distributor', 1, 0.5, 38.50),
-- Order 10
(10, 11, 'distributor', 3, 1, 99.00),
(10, 12, 'distributor', 3, 11, 27.50),
-- Order 11
(11, 6, 'distributor', 4, 1, 44.00),
(11, 14, 'distributor', 4, 3, 35.20),
-- Order 12
(12, 13, 'distributor', 5, 1, 132.00),
(12, 14, 'distributor', 5, 4, 35.20),
-- Order 13
(13, 15, 'distributor', 6, 2, 60.50),
(13, 16, 'distributor', 6, 3, 71.50);

-- =====================================================
-- 11. INSERT SHIPMENTS (12)
-- =====================================================

INSERT INTO shipment (order_id, estimated_delivery_date, actual_delivery_date, tracking_number, carrier, shipment_status) VALUES
(1, '2025-10-20', '2025-10-19', 'TRACK-001-2025', 'FedEx', 'delivered'),
(2, '2025-11-08', NULL, 'TRACK-002-2025', 'UPS', 'in_transit'),
(3, '2025-11-10', NULL, 'TRACK-003-2025', 'DHL', 'preparing'),
(4, '2025-10-25', '2025-10-24', 'TRACK-004-2025', 'FedEx', 'delivered'),
(6, '2025-11-12', '2025-11-10', 'TRACK-006-2025', 'UPS', 'delivered'),
(7, '2025-11-15', NULL, 'TRACK-007-2025', 'DHL', 'in_transit'),
(8, '2025-11-18', NULL, 'TRACK-008-2025', 'FedEx', 'preparing'),
(9, '2025-11-05', '2025-11-04', 'TRACK-009-2025', 'UPS', 'delivered'),
(10, '2025-11-20', NULL, 'TRACK-010-2025', 'DHL', 'in_transit'),
(12, '2025-11-22', '2025-11-20', 'TRACK-012-2025', 'FedEx', 'delivered'),
(13, '2025-11-25', NULL, 'TRACK-013-2025', 'UPS', 'preparing'),
(14, '2025-11-10', '2025-11-09', 'TRACK-014-2025', 'DHL', 'delivered');

-- =====================================================
-- 12. INSERT PAYMENTS (15)
-- =====================================================

INSERT INTO payment (order_id, payment_method, amount, transaction_id, payment_status) VALUES
(1, 'credit_card', 350.00, 'TXN-CC-001', 'success'),
(2, 'upi', 242.00, 'TXN-UPI-002', 'success'),
(3, 'debit_card', 198.00, 'TXN-DC-003', 'success'),
(4, 'net_banking', 495.00, 'TXN-NB-004', 'success'),
(5, 'credit_card', 165.00, 'TXN-CC-005', 'pending'),
(6, 'upi', 330.00, 'TXN-UPI-006', 'success'),
(7, 'debit_card', 279.00, 'TXN-DC-007', 'success'),
(8, 'credit_card', 412.50, 'TXN-CC-008', 'success'),
(9, 'net_banking', 220.00, 'TXN-NB-009', 'success'),
(10, 'upi', 371.00, 'TXN-UPI-010', 'success'),
(11, 'credit_card', 165.00, 'TXN-CC-011', 'pending'),
(12, 'debit_card', 288.00, 'TXN-DC-012', 'success'),
(13, 'credit_card', 442.00, 'TXN-CC-013', 'success'),
(14, 'upi', 275.50, 'TXN-UPI-014', 'success'),
(15, 'net_banking', 220.00, 'TXN-NB-015', 'success');

-- =====================================================
-- 13. INSERT PRICE_CHANGE_HISTORY (10+ entries)
-- =====================================================

INSERT INTO price_change_history (dist_inventory_id, distributor_id, product_id, old_price, new_price, old_markup_percent, new_markup_percent, changed_by, change_reason) VALUES
(1, 1, 1, 155.00, 165.00, 3.33, 10.00, 5, 'Adjusted to 10% minimum markup'),
(2, 1, 2, 36.00, 38.50, 2.86, 10.00, 5, 'Adjusted to 10% minimum markup'),
(3, 1, 3, 47.00, 49.50, 4.44, 10.00, 5, 'Adjusted to 10% minimum markup'),
(4, 1, 5, 195.00, 198.00, 8.33, 10.00, 5, 'Adjusted to 10% minimum markup'),
(5, 1, 6, 42.00, 44.00, 5.00, 10.00, 5, 'Adjusted to 10% minimum markup'),
(6, 2, 1, 160.00, 165.00, 6.67, 10.00, 6, 'Competitive pricing adjustment'),
(7, 2, 4, 85.00, 88.00, 6.25, 10.00, 6, 'Seasonal markup increase'),
(8, 2, 9, 118.00, 121.00, 7.27, 10.00, 6, 'Strategic pricing'),
(9, 3, 5, 195.00, 198.00, 8.33, 10.00, 7, 'Market alignment'),
(10, 3, 7, 63.00, 66.00, 5.00, 10.00, 7, 'Premium tier pricing'),
(11, 3, 11, 95.00, 99.00, 5.56, 10.00, 7, 'Bulk discount tier'),
(12, 3, 12, 26.00, 27.50, 4.00, 10.00, 7, 'Base price adjustment');

-- =====================================================
-- 14. VERIFICATION QUERIES
-- =====================================================

-- Verify all tables have data
SELECT 'Users' as Table_Name, COUNT(*) as Record_Count FROM users
UNION ALL
SELECT 'Manufacturers', COUNT(*) FROM manufacturer
UNION ALL
SELECT 'Distributors', COUNT(*) FROM distributor
UNION ALL
SELECT 'Customers', COUNT(*) FROM customer
UNION ALL
SELECT 'Products', COUNT(*) FROM product
UNION ALL
SELECT 'Inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'Allocations', COUNT(*) FROM allocation
UNION ALL
SELECT 'Distributor_Inventory', COUNT(*) FROM distributor_inventory
UNION ALL
SELECT 'Customer_Orders', COUNT(*) FROM customer_order
UNION ALL
SELECT 'Order_Items', COUNT(*) FROM order_item
UNION ALL
SELECT 'Shipments', COUNT(*) FROM shipment
UNION ALL
SELECT 'Payments', COUNT(*) FROM payment
UNION ALL
SELECT 'Price_Change_History', COUNT(*) FROM price_change_history;

-- =====================================================
-- END OF INSERT DATA
-- =====================================================