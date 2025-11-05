
-- =====================================================
-- SAMPLE DATA INSERTION FOR PRODUCT CHAIN DISTRIBUTION
-- =====================================================

USE product_chain_distribution;

-- =====================================================
-- INSERT USERS
-- =====================================================
INSERT INTO users (username, password, user_type, email, phone) VALUES
-- Manufacturers
('nike_mfg', 'hashed_password_123', 'manufacturer', 'contact@nike.com', '1234567890'),
('adidas_mfg', 'hashed_password_456', 'manufacturer', 'info@adidas.com', '1234567891'),
('puma_mfg', 'hashed_password_789', 'manufacturer', 'sales@puma.com', '1234567892'),

-- Distributors
('metro_dist', 'hashed_password_111', 'distributor', 'contact@metrodist.com', '2234567890'),
('global_dist', 'hashed_password_222', 'distributor', 'info@globaldist.com', '2234567891'),
('rapid_dist', 'hashed_password_333', 'distributor', 'sales@rapiddist.com', '2234567892'),

-- Customers
('john_doe', 'hashed_password_aaa', 'customer', 'john.doe@email.com', '3334567890'),
('jane_smith', 'hashed_password_bbb', 'customer', 'jane.smith@email.com', '3334567891'),
('bob_johnson', 'hashed_password_ccc', 'customer', 'bob.j@email.com', '3334567892'),
('alice_williams', 'hashed_password_ddd', 'customer', 'alice.w@email.com', '3334567893'),
('charlie_brown', 'hashed_password_eee', 'customer', 'charlie.b@email.com', '3334567894');

-- =====================================================
-- INSERT MANUFACTURERS
-- =====================================================
INSERT INTO manufacturer (user_id, company_name, address, city, state, country, postal_code, contact_person, registration_number) VALUES
(1, 'Nike Manufacturing Inc.', '123 Industrial Ave', 'Portland', 'Oregon', 'USA', '97209', 'Mike Johnson', 'MFG-NIKE-001'),
(2, 'Adidas Production GmbH', '456 Factory Road', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Hans Mueller', 'MFG-ADIDAS-002'),
(3, 'Puma Sports Manufacturing', '789 Production Lane', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Klaus Schmidt', 'MFG-PUMA-003');

-- =====================================================
-- INSERT DISTRIBUTORS
-- =====================================================
INSERT INTO distributor (user_id, company_name, address, city, state, country, postal_code, contact_person, license_number, credit_limit) VALUES
(4, 'Metro Distribution LLC', '321 Warehouse St', 'New York', 'NY', 'USA', '10001', 'Sarah Connor', 'DIST-METRO-001', 500000.00),
(5, 'Global Supply Chain Inc.', '654 Logistics Blvd', 'London', 'England', 'UK', 'E14 5AB', 'James Bond', 'DIST-GLOBAL-002', 750000.00),
(6, 'Rapid Distributors Pvt Ltd', '987 Commerce Park', 'Bangalore', 'Karnataka', 'India', '560001', 'Raj Kumar', 'DIST-RAPID-003', 300000.00);

-- =====================================================
-- INSERT CUSTOMERS
-- =====================================================
INSERT INTO customer (user_id, first_name, last_name, address, city, state, country, postal_code, loyalty_points) VALUES
(7, 'John', 'Doe', '111 Main Street', 'Los Angeles', 'CA', 'USA', '90001', 150),
(8, 'Jane', 'Smith', '222 Oak Avenue', 'Chicago', 'IL', 'USA', '60601', 320),
(9, 'Bob', 'Johnson', '333 Pine Road', 'Houston', 'TX', 'USA', '77001', 80),
(10, 'Alice', 'Williams', '444 Maple Drive', 'Phoenix', 'AZ', 'USA', '85001', 500),
(11, 'Charlie', 'Brown', '555 Elm Street', 'Philadelphia', 'PA', 'USA', '19101', 200);

-- =====================================================
-- INSERT PRODUCTS
-- =====================================================
INSERT INTO product (manufacturer_id, product_name, description, category, unit_price, manufacturing_cost, weight, dimensions) VALUES
-- Nike Products
(1, 'Nike Air Max 270', 'Premium running shoes with air cushioning', 'Footwear', 150.00, 60.00, 0.85, '32x20x12 cm'),
(1, 'Nike Dri-FIT T-Shirt', 'Moisture-wicking athletic t-shirt', 'Apparel', 35.00, 12.00, 0.25, '40x30x2 cm'),
(1, 'Nike Pro Shorts', 'Compression training shorts', 'Apparel', 45.00, 15.00, 0.20, '35x25x2 cm'),
(1, 'Nike Backpack', 'Sports backpack with laptop compartment', 'Accessories', 80.00, 30.00, 0.60, '45x30x15 cm'),

-- Adidas Products
(2, 'Adidas Ultraboost 21', 'Energy-returning running shoes', 'Footwear', 180.00, 70.00, 0.90, '33x21x13 cm'),
(2, 'Adidas Training Jersey', 'Breathable sports jersey', 'Apparel', 40.00, 14.00, 0.30, '42x32x2 cm'),
(2, 'Adidas Track Pants', 'Classic three-stripe track pants', 'Apparel', 60.00, 20.00, 0.40, '45x35x3 cm'),
(2, 'Adidas Sports Bag', 'Durable gym duffel bag', 'Accessories', 70.00, 25.00, 0.50, '50x30x25 cm'),

-- Puma Products
(3, 'Puma RS-X Sneakers', 'Retro-style running sneakers', 'Footwear', 110.00, 45.00, 0.80, '31x20x12 cm'),
(3, 'Puma Performance Polo', 'Golf and casual polo shirt', 'Apparel', 50.00, 18.00, 0.28, '40x30x2 cm'),
(3, 'Puma Training Jacket', 'Lightweight training jacket', 'Apparel', 90.00, 35.00, 0.55, '48x38x3 cm'),
(3, 'Puma Baseball Cap', 'Adjustable sports cap', 'Accessories', 25.00, 8.00, 0.15, '25x25x10 cm');

-- =====================================================
-- INSERT INVENTORY (Manufacturer's Inventory)
-- =====================================================
INSERT INTO inventory (product_id, manufacturer_id, quantity_available, reorder_level) VALUES
-- Nike Inventory
(1, 1, 500, 100),
(2, 1, 1200, 200),
(3, 1, 800, 150),
(4, 1, 300, 80),

-- Adidas Inventory
(5, 2, 600, 120),
(6, 2, 1500, 250),
(7, 2, 700, 140),
(8, 2, 250, 60),

-- Puma Inventory
(9, 3, 400, 90),
(10, 3, 1000, 180),
(11, 3, 450, 100),
(12, 3, 2000, 300);

-- =====================================================
-- INSERT ALLOCATIONS (Manufacturer to Distributor)
-- =====================================================
INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, status, unit_price) VALUES
-- Nike to Metro Distribution
(1, 1, 1, 100, 'completed', 150.00),
(1, 1, 2, 200, 'completed', 35.00),
(1, 1, 3, 150, 'completed', 45.00),

-- Nike to Global Supply
(1, 2, 1, 80, 'completed', 150.00),
(1, 2, 4, 50, 'completed', 80.00),

-- Adidas to Metro Distribution
(2, 1, 5, 120, 'completed', 180.00),
(2, 1, 6, 180, 'completed', 40.00),

-- Adidas to Rapid Distributors
(2, 3, 5, 100, 'completed', 180.00),
(2, 3, 7, 120, 'completed', 60.00),

-- Puma to Global Supply
(3, 2, 9, 90, 'completed', 110.00),
(3, 2, 10, 150, 'completed', 50.00),

-- Puma to Rapid Distributors
(3, 3, 11, 80, 'completed', 90.00),
(3, 3, 12, 300, 'completed', 25.00);

-- =====================================================
-- INSERT DISTRIBUTOR INVENTORY
-- =====================================================
INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, unit_price) VALUES
-- Metro Distribution
(1, 1, 100, 165.00),
(1, 2, 200, 38.50),
(1, 3, 150, 49.50),
(1, 5, 120, 198.00),
(1, 6, 180, 44.00),

-- Global Supply Chain
(2, 1, 80, 165.00),
(2, 4, 50, 88.00),
(2, 9, 90, 121.00),
(2, 10, 150, 55.00),

-- Rapid Distributors
(3, 5, 100, 198.00),
(3, 7, 120, 66.00),
(3, 11, 80, 99.00),
(3, 12, 300, 27.50);

-- =====================================================
-- INSERT CUSTOMER ORDERS
-- =====================================================
INSERT INTO customer_order (customer_id, total_amount, order_status, payment_status, shipping_address) VALUES
(1, 350.00, 'delivered', 'paid', '111 Main Street, Los Angeles, CA 90001'),
(2, 242.00, 'shipped', 'paid', '222 Oak Avenue, Chicago, IL 60601'),
(3, 198.00, 'processing', 'paid', '333 Pine Road, Houston, TX 77001'),
(4, 495.00, 'delivered', 'paid', '444 Maple Drive, Phoenix, AZ 85001'),
(5, 165.00, 'pending', 'pending', '555 Elm Street, Philadelphia, PA 19101');

-- =====================================================
-- INSERT ORDER ITEMS
-- =====================================================
INSERT INTO order_item (order_id, product_id, seller_type, seller_id, quantity, unit_price) VALUES
-- Order 1 (John Doe)
(1, 1, 'distributor', 1, 2, 165.00),
(1, 3, 'manufacturer', 1, 1, 45.00),

-- Order 2 (Jane Smith)
(2, 5, 'distributor', 1, 1, 198.00),
(2, 6, 'distributor', 1, 1, 44.00),

-- Order 3 (Bob Johnson)
(3, 5, 'distributor', 1, 1, 198.00),

-- Order 4 (Alice Williams)
(4, 1, 'distributor', 2, 3, 165.00),

-- Order 5 (Charlie Brown)
(5, 1, 'distributor', 1, 1, 165.00);

-- =====================================================
-- INSERT SHIPMENTS
-- =====================================================
INSERT INTO shipment (order_id, estimated_delivery_date, actual_delivery_date, tracking_number, carrier, shipment_status) VALUES
(1, '2025-10-20', '2025-10-19', 'TRACK-001-2025', 'FedEx', 'delivered'),
(2, '2025-11-08', NULL, 'TRACK-002-2025', 'UPS', 'in_transit'),
(3, '2025-11-10', NULL, 'TRACK-003-2025', 'DHL', 'preparing'),
(4, '2025-10-25', '2025-10-24', 'TRACK-004-2025', 'FedEx', 'delivered');

-- =====================================================
-- INSERT PAYMENTS
-- =====================================================
INSERT INTO payment (order_id, payment_method, amount, transaction_id, payment_status) VALUES
(1, 'credit_card', 350.00, 'TXN-CC-001', 'success'),
(2, 'upi', 242.00, 'TXN-UPI-002', 'success'),
(3, 'debit_card', 198.00, 'TXN-DC-003', 'success'),
(4, 'net_banking', 495.00, 'TXN-NB-004', 'success'),
(5, 'credit_card', 165.00, 'TXN-CC-005', 'pending');
