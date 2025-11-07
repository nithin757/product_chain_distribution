
-- =====================================================
-- PRODUCT CHAIN DISTRIBUTION DATABASE SCHEMA
-- =====================================================

-- Drop existing tables if they exist
DROP DATABASE IF EXISTS product_chain_distribution;
CREATE DATABASE product_chain_distribution;
USE product_chain_distribution;

-- =====================================================
-- TABLE 1: USERS (For authentication and role management)
-- =====================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    user_type ENUM('manufacturer', 'distributor', 'customer') NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- TABLE 2: MANUFACTURER
-- =====================================================
CREATE TABLE manufacturer (
    manufacturer_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(10),
    contact_person VARCHAR(100),
    registration_number VARCHAR(50) UNIQUE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 3: DISTRIBUTOR
-- =====================================================
CREATE TABLE distributor (
    distributor_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(10),
    contact_person VARCHAR(100),
    license_number VARCHAR(50) UNIQUE,
    credit_limit DECIMAL(12, 2) DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 4: CUSTOMER
-- =====================================================
CREATE TABLE customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50),
    postal_code VARCHAR(10),
    loyalty_points INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 5: PRODUCT
-- =====================================================
CREATE TABLE product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    manufacturer_id INT NOT NULL,
    product_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    unit_price DECIMAL(10, 2) NOT NULL,
    manufacturing_cost DECIMAL(10, 2),
    weight DECIMAL(8, 2),
    dimensions VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturer(manufacturer_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 6: INVENTORY (Manufacturer's Inventory)
-- =====================================================
CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    manufacturer_id INT NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    reorder_level INT DEFAULT 100,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturer(manufacturer_id) ON DELETE CASCADE,
    UNIQUE KEY unique_product_manufacturer (product_id, manufacturer_id)
);

-- =====================================================
-- TABLE 7: DISTRIBUTOR_INVENTORY
-- =====================================================
CREATE TABLE distributor_inventory (
    dist_inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    distributor_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_available INT NOT NULL DEFAULT 0,
    unit_price DECIMAL(10, 2) NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    UNIQUE KEY unique_dist_product (distributor_id, product_id)
);

-- =====================================================
-- TABLE 8: ALLOCATION (Manufacturer to Distributor)
-- =====================================================
CREATE TABLE allocation (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    manufacturer_id INT NOT NULL,
    distributor_id INT NOT NULL,
    product_id INT NOT NULL,
    allocated_quantity INT NOT NULL,
    allocation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'cancelled') DEFAULT 'pending',
    unit_price DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(12, 2) GENERATED ALWAYS AS (allocated_quantity * unit_price) STORED,
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturer(manufacturer_id) ON DELETE CASCADE,
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 9: CUSTOMER_ORDER
-- =====================================================
CREATE TABLE customer_order (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12, 2) DEFAULT 0.00,
    order_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'failed') DEFAULT 'pending',
    shipping_address VARCHAR(300),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 10: ORDER_ITEM
-- =====================================================
CREATE TABLE order_item (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    seller_type ENUM('manufacturer', 'distributor') NOT NULL,
    seller_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    subtotal DECIMAL(12, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 11: SHIPMENT
-- =====================================================
CREATE TABLE shipment (
    shipment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    shipment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    tracking_number VARCHAR(100) UNIQUE,
    carrier VARCHAR(50),
    shipment_status ENUM('preparing', 'in_transit', 'delivered', 'returned') DEFAULT 'preparing',
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 12: PAYMENT
-- =====================================================
CREATE TABLE payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('credit_card', 'debit_card', 'net_banking', 'upi', 'cash') NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    transaction_id VARCHAR(100) UNIQUE,
    payment_status ENUM('success', 'failed', 'pending') DEFAULT 'pending',
    FOREIGN KEY (order_id) REFERENCES customer_order(order_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 13: REORDER_LOG (For tracking low inventory)
-- =====================================================
CREATE TABLE reorder_log (
    reorder_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    manufacturer_id INT NOT NULL,
    quantity_needed INT NOT NULL,
    reorder_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'ordered', 'completed') DEFAULT 'pending',
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    FOREIGN KEY (manufacturer_id) REFERENCES manufacturer(manufacturer_id) ON DELETE CASCADE
);

-- =====================================================
-- TABLE 14: AUDIT_LOG (For tracking changes)
-- =====================================================
CREATE TABLE audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    user_id INT,
    old_value TEXT,
    new_value TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);
