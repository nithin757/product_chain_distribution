-- =====================================================
-- COMPLETE INSERT DATA FOR UPDATED SCHEMA
-- WITH WERKZEUG HASHED PASSWORDS
-- =====================================================

USE product_chain_distribution;

-- =====================================================
-- 1. DELETE EXISTING DATA (CLEAN SLATE)
-- =====================================================

DELETE FROM price_change_history;
DELETE FROM payment;
DELETE FROM shipment;
DELETE FROM order_item;
DELETE FROM customer_order;
DELETE FROM distributor_inventory;
DELETE FROM allocation;
DELETE FROM inventory;
DELETE FROM product;
DELETE FROM customer;
DELETE FROM distributor;
DELETE FROM manufacturer;
DELETE FROM users;

-- =====================================================
-- 2. INSERT USERS (23 total) - WITH WERKZEUG HASHED PASSWORDS
-- =====================================================

INSERT INTO users (username, password, user_type, email, phone) VALUES
-- Manufacturers (4)
('nike_mfg', 'pbkdf2:sha256:600000$nOAN64gSirE2DHq1$6970dbb28edf8140bafaba09a5682fde44cdc16e47f8183a17384dc63c79e0f2', 'manufacturer', 'contact@nike.com', '1234567890'),
('adidas_mfg', 'pbkdf2:sha256:600000$Y4xFwNrDcJyjyiMO$01107a38fde5d278838af087606042e82225c729240d8f7180e764ccb6e62cd1', 'manufacturer', 'info@adidas.com', '1234567891'),
('puma_mfg', 'pbkdf2:sha256:600000$VEn1P8ItylXSCCJo$dc4f8ec885c844337ceae4963b25cf485dda585b2f08a82bb31e4818fac81a2a', 'manufacturer', 'sales@puma.com', '1234567892'),
('reebok_mfg', 'pbkdf2:sha256:600000$Rs2HawnkYOCYZ4Zc$0e543f6c1beeb9ebc2c0f16c65030519ef21b9c726202b4d7ef2055dbf886102', 'manufacturer', 'contact@reebok.com', '1234567893'),

-- Distributors (6)
('metro_dist', 'pbkdf2:sha256:600000$XS8XoMrvOUWHvOzE$255a1d64a450b22b10db728f7f28995cb2030593fe9c0d412dc0fba0ef5872fe', 'distributor', 'contact@metrodist.com', '2234567890'),
('global_dist', 'pbkdf2:sha256:600000$DQU143LekIJjelm5$c9a1048c78c382490146a2bdfb08e323eb80f4da190b7150902a44d6deaea8d5', 'distributor', 'info@globaldist.com', '2234567891'),
('rapid_dist', 'pbkdf2:sha256:600000$z1e5aFW5oHmBUWq2$76afd2339f4e0be17680cd6a4dfc858e264687da5366e738179a9a3625e80f74', 'distributor', 'sales@rapiddist.com', '2234567892'),
('express_dist', 'pbkdf2:sha256:600000$kxTw5i4jKWOYxFjA$bd35f0306c834e23e4c103f43c8b7c5191ae612338e40b9abe838daf4c8db9c1', 'distributor', 'contact@expressdist.com', '2234567893'),
('premier_dist', 'pbkdf2:sha256:600000$CuFaxpOmmU3RmCn1$7df5cbeedb8daa1f9e3faeb9eaaf86e23b99fc26f020eb3df0fdb25413ab54ac', 'distributor', 'info@premierdist.com', '2234567894'),
('optimal_dist', 'pbkdf2:sha256:600000$ApIfarUgoJJoBqPz$54e3e68f642525f244e1bd7eab70965a430fddfa5b6ae663c754ace72e3f26cb', 'distributor', 'sales@optimaldist.com', '2234567895'),

-- Customers (13)
('john_doe', 'pbkdf2:sha256:600000$KtZ1ss085arWy2dq$173fc61002038c223e605bd8f1042fa4f587668dbb8be7e8bf9f86ad6ac66163', 'customer', 'john.doe@email.com', '3334567890'),
('jane_smith', 'pbkdf2:sha256:600000$yMCn4IUsRK2yXMq1$c176bb504166e7a12ace2081b85dfbd7ac4946ba6c74a71ee64296effbbdfce3', 'customer', 'jane.smith@email.com', '3334567891'),
('bob_johnson', 'pbkdf2:sha256:600000$MpyFjez8KqoYTHpy$3342be3623abdd30ded8ecd9e97f2f207fb0b9cf96d680d5134db19e78859402', 'customer', 'bob.j@email.com', '3334567892'),
('alice_williams', 'pbkdf2:sha256:600000$0nwzURYA4OmrhFkh$9c24a9300bd785ce7faee131182afe38f66061115bd67a1f65b198b61437099c', 'customer', 'alice.w@email.com', '3334567893'),
('charlie_brown', 'pbkdf2:sha256:600000$wz023lBmVLpSfKuW$31a2f1f16de327fd7982a593f12bcabd5fe261e3461f4d1ca0b1c1a876b9197a', 'customer', 'charlie.b@email.com', '3334567894'),
('diana_prince', 'pbkdf2:sha256:600000$dh1jWY120W6zjVB8$b66de059831f91724f2c802e503eda6c401008d515aff7d30fb9da1f8235a674', 'customer', 'diana.p@email.com', '3334567895'),
('evan_martin', 'pbkdf2:sha256:600000$RxbebTOAW2g2VWsF$2d9ed54c145f44a15d0c4b8833bb134eafb26a7028da7c7e178dbff8ab4077ea', 'customer', 'evan.m@email.com', '3334567896'),
('fiona_green', 'pbkdf2:sha256:600000$ChfUf6DAqaSJyHth$41e49f7660e208cab534f081e4d538c3d7c911db3cb8a5a7c59a333a93ebd9f8', 'customer', 'fiona.g@email.com', '3334567897'),
('george_davis', 'pbkdf2:sha256:600000$QhDfPdPp3NAWc3Dv$2435dad71d9bfa11f0cc40cc682401fb35a1cc0137331d15e3b872e2b849b484', 'customer', 'george.d@email.com', '3334567898'),
('hannah_lee', 'pbkdf2:sha256:600000$zCKNIn39EcFNPAcg$13fbbdba70f307268c700623425fd8c3ffbd19474e3fd7f00f7e62050b6f037a', 'customer', 'hannah.l@email.com', '3334567899'),
('isaac_harris', 'pbkdf2:sha256:600000$aWkZT4Ha7zvobYJr$523937cf8e907ad44cbeb3f201c354b0f35b4587460d8da5b20228ed11246f4b', 'customer', 'isaac.h@email.com', '3334567900'),
('julia_clark', 'pbkdf2:sha256:600000$9g5rshfedQdqZqQj$9732cab674ad538527ddf814055c8d863452ec6e9f2579c433c5386bba1be891', 'customer', 'julia.c@email.com', '3334567901'),
('kevin_baker', 'pbkdf2:sha256:600000$pltfLvu2tiLyazKo$c96d31aa25a237ffd6d02b69d34ea833a51c243ef667cc3b6943b9ee61dd243d', 'customer', 'kevin.b@email.com', '3334567902');

-- =====================================================
-- 3. INSERT MANUFACTURERS (4)
-- =====================================================

INSERT INTO manufacturer (user_id, company_name, address, city, state, country, postal_code, contact_person, registration_number) VALUES
(1, 'Nike Manufacturing Inc.', '123 Industrial Ave', 'Portland', 'Oregon', 'USA', '97209', 'Mike Johnson', 'MFG-NIKE-001'),
(2, 'Adidas Production GmbH', '456 Factory Road', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Hans Mueller', 'MFG-ADIDAS-002'),
(3, 'Puma Sports Manufacturing', '789 Production Lane', 'Herzogenaurach', 'Bavaria', 'Germany', '91074', 'Klaus Schmidt', 'MFG-PUMA-003'),
(4, 'Reebok International Ltd', '321 Sport Street', 'Boston', 'Massachusetts', 'USA', '02110', 'Paul Thompson', 'MFG-REEBOK-004');

-- =====================================================
-- 4. INSERT DISTRIBUTORS (6)
-- =====================================================

INSERT INTO distributor (user_id, company_name, address, city, state, country, postal_code, contact_person, license_number, credit_limit) VALUES
(5, 'Metro Distribution LLC', '321 Warehouse St', 'New York', 'NY', 'USA', '10001', 'Sarah Connor', 'DIST-METRO-001', 500000.00),
(6, 'Global Supply Chain Inc.', '654 Logistics Blvd', 'London', 'England', 'UK', 'E14 5AB', 'James Bond', 'DIST-GLOBAL-002', 750000.00),
(7, 'Rapid Distributors Pvt Ltd', '987 Commerce Park', 'Bangalore', 'Karnataka', 'India', '560001', 'Raj Kumar', 'DIST-RAPID-003', 300000.00),
(8, 'Express Distribution Co.', '246 Trade Center', 'Toronto', 'Ontario', 'Canada', 'M5H 2Y2', 'Michael Chen', 'DIST-EXPRESS-004', 450000.00),
(9, 'Premier Supply Chain', '135 Business Plaza', 'Sydney', 'New South Wales', 'Australia', '2000', 'Emma Wilson', 'DIST-PREMIER-005', 400000.00),
(10, 'Optimal Logistics Solutions', '369 Distribution Way', 'Singapore', 'Singapore', 'Singapore', '018956', 'David Lim', 'DIST-OPTIMAL-006', 550000.00);

-- =====================================================
-- 5. INSERT CUSTOMERS (13)
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
-- 6. INSERT PRODUCTS (16 - with SKU and rating)
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
-- 7. INSERT INVENTORY - Manufacturer (16)
-- =====================================================

INSERT INTO inventory (product_id, manufacturer_id, quantity_available, reorder_level) VALUES
(1, 1, 500, 100),
(2, 1, 1200, 200),
(3, 1, 800, 150),
(4, 1, 300, 80),
(5, 2, 600, 120),
(6, 2, 1500, 250),
(7, 2, 700, 140),
(8, 2, 250, 60),
(9, 3, 400, 90),
(10, 3, 1000, 180),
(11, 3, 450, 100),
(12, 3, 2000, 300),
(13, 4, 350, 75),
(14, 4, 900, 150),
(15, 4, 550, 120),
(16, 4, 280, 70);

-- =====================================================
-- 8. INSERT ALLOCATIONS (18)
-- =====================================================

INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, status, unit_price) VALUES
(1, 1, 1, 100, 'completed', 150.00),
(1, 1, 2, 200, 'completed', 35.00),
(1, 1, 3, 150, 'completed', 45.00),
(1, 2, 1, 80, 'completed', 150.00),
(1, 2, 4, 50, 'completed', 80.00),
(1, 3, 2, 100, 'completed', 35.00),
(2, 1, 5, 120, 'completed', 180.00),
(2, 1, 6, 180, 'completed', 40.00),
(2, 3, 5, 100, 'completed', 180.00),
(2, 3, 7, 120, 'completed', 60.00),
(2, 4, 6, 150, 'completed', 40.00),
(3, 2, 9, 90, 'completed', 110.00),
(3, 2, 10, 150, 'completed', 50.00),
(3, 3, 11, 80, 'completed', 90.00),
(3, 3, 12, 300, 'completed', 25.00),
(4, 5, 13, 100, 'completed', 120.00),
(4, 5, 14, 150, 'completed', 32.00),
(4, 6, 15, 120, 'completed', 55.00);

-- =====================================================
-- 9. INSERT DISTRIBUTOR_INVENTORY (18 - with cost_price & reorder_level)
-- =====================================================

INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, cost_price, unit_price, reorder_level) VALUES
(1, 1, 100, 150.00, 165.00, 50),
(1, 2, 200, 35.00, 38.50, 80),
(1, 3, 150, 45.00, 49.50, 60),
(1, 5, 120, 180.00, 198.00, 50),
(1, 6, 180, 40.00, 44.00, 70),
(2, 1, 80, 150.00, 165.00, 40),
(2, 4, 50, 80.00, 88.00, 25),
(2, 9, 90, 110.00, 121.00, 45),
(2, 10, 150, 50.00, 55.00, 60),
(3, 5, 100, 180.00, 198.00, 50),
(3, 7, 120, 60.00, 66.00, 50),
(3, 11, 80, 90.00, 99.00, 40),
(3, 12, 300, 25.00, 27.50, 100),
(4, 6, 150, 40.00, 44.00, 60),
(4, 14, 150, 32.00, 35.20, 50),
(5, 13, 100, 120.00, 132.00, 40),
(5, 14, 150, 32.00, 35.20, 50),
(6, 15, 120, 55.00, 60.50, 45);

-- =====================================================
-- 10. INSERT CUSTOMER_ORDERS (15)
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
-- 11. INSERT ORDER_ITEMS (20)
-- =====================================================

INSERT INTO order_item (order_id, product_id, seller_type, seller_id, quantity, unit_price) VALUES
(1, 1, 'distributor', 1, 2, 165.00),
(1, 3, 'manufacturer', 1, 1, 45.00),
(2, 5, 'distributor', 1, 1, 198.00),
(2, 6, 'distributor', 1, 1, 44.00),
(3, 5, 'distributor', 1, 1, 198.00),
(4, 1, 'distributor', 2, 3, 165.00),
(5, 1, 'distributor', 1, 1, 165.00),
(6, 2, 'distributor', 1, 2, 38.50),
(6, 4, 'manufacturer', 1, 1, 80.00),
(7, 9, 'distributor', 2, 1, 121.00),
(7, 10, 'distributor', 2, 3, 55.00),
(8, 5, 'distributor', 3, 2, 198.00),
(8, 7, 'distributor', 3, 1, 66.00),
(9, 1, 'distributor', 1, 2, 165.00),
(9, 2, 'distributor', 1, 1, 38.50),
(10, 11, 'distributor', 3, 1, 99.00),
(10, 12, 'distributor', 3, 11, 27.50),
(11, 6, 'distributor', 4, 1, 44.00),
(11, 14, 'distributor', 4, 3, 35.20),
(12, 13, 'distributor', 5, 1, 132.00);

-- =====================================================
-- 12. INSERT SHIPMENTS (12)
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
-- 13. INSERT PAYMENTS (15)
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
-- 14. INSERT PRICE_CHANGE_HISTORY (12)
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
-- END OF INSERT DATA
-- =====================================================