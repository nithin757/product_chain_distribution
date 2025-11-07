# SCHEMA UPDATE GUIDE - Distributor Features

## Summary of Changes

Your current schema is **95% ready** for the new distributor features. However, there are some **important additions and modifications** needed to support all the new functionality properly.

---

## Changes Required

### ✅ GOOD - Already Exists (No Changes Needed)

1. **order_item table** - Has `seller_type` and `seller_id` columns ✓
   - Perfect for tracking which distributor sold which products
   
2. **distributor_inventory table** - Stores distributor's inventory ✓
   - Enables distributor to manage their products
   
3. **customer_order table** - Tracks customer orders ✓
   - Enables order visibility
   
4. **shipment table** - Tracks shipping status ✓
   - Enables order tracking
   
5. **payment table** - Records payment information ✓
   - Enables payment status tracking
   
6. **allocation table** - Tracks allocations from manufacturers ✓
   - Enables distributor to see what they received

---

## ⚠️ ADDITIONS REQUIRED

### 1. **PRODUCT TABLE - Add 3 Columns**

**Current Columns:**
```sql
product_id, manufacturer_id, product_name, description, category, 
unit_price, manufacturing_cost, weight, dimensions, created_at
```

**Add These:**

```sql
-- Column 1: SKU (Stock Keeping Unit)
sku VARCHAR(50) UNIQUE,

-- Column 2: Rating (For analytics - top products)
rating DECIMAL(3, 2) DEFAULT 0,

-- Column 3: Total Reviews
total_reviews INT DEFAULT 0
```

**Why:** 
- SKU is needed for the distributor_inventory listing page
- Rating helps identify top-selling products in analytics
- Needed for "Top Selling Products" dashboard

**SQL Migration:**
```sql
ALTER TABLE product 
ADD COLUMN sku VARCHAR(50) UNIQUE,
ADD COLUMN rating DECIMAL(3, 2) DEFAULT 0,
ADD COLUMN total_reviews INT DEFAULT 0,
ADD INDEX idx_sku (sku),
ADD INDEX idx_category (category);
```

---

### 2. **CUSTOMER TABLE - Add 2 Columns**

**Current Columns:**
```sql
customer_id, user_id, first_name, last_name, address, city, 
state, country, postal_code, loyalty_points
```

**Add These:**

```sql
-- Column 1: Phone (Already in users, but duplicated for convenience)
phone VARCHAR(15),

-- Column 2: Email (Already in users, but duplicated for convenience)
email VARCHAR(100),

-- Column 3: Created Date (For customer analytics)
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

**Why:**
- Needed for order details page to show customer contact info
- Avoid needing to join with users table for basic info
- Created_at helps track customer acquisition date

**SQL Migration:**
```sql
ALTER TABLE customer 
ADD COLUMN phone VARCHAR(15),
ADD COLUMN email VARCHAR(100),
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD INDEX idx_customer_created (created_at);
```

---

### 3. **DISTRIBUTOR_INVENTORY TABLE - Add 2 Columns** ⭐ CRITICAL

**Current Columns:**
```sql
dist_inventory_id, distributor_id, product_id, quantity_available, 
unit_price, last_updated
```

**Add These:**

```sql
-- Column 1: Cost Price (Purchase price from manufacturer)
cost_price DECIMAL(10, 2) NOT NULL,

-- Column 2: Reorder Level (When to trigger low stock alert)
reorder_level INT DEFAULT 50,

-- Column 3: Markup Percent (Generated - calculated from cost & selling price)
markup_percent DECIMAL(5, 2) GENERATED ALWAYS AS 
    ((unit_price - cost_price) / cost_price * 100) STORED
```

**Why:**
- `cost_price` is ESSENTIAL for calculating markup % 
- `reorder_level` enables low stock alerts
- `markup_percent` shows profit margin at a glance
- Needed for pricing management page to validate minimum 10% markup

**SQL Migration:**
```sql
ALTER TABLE distributor_inventory 
ADD COLUMN cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
ADD COLUMN reorder_level INT DEFAULT 50,
ADD COLUMN markup_percent DECIMAL(5, 2) GENERATED ALWAYS AS 
    ((unit_price - cost_price) / cost_price * 100) STORED,
ADD INDEX idx_stock_status (distributor_id, quantity_available);
```

**Important:** When you run this, you need to update existing records with the cost price from the `allocation` table (use the unit_price that was allocated).

---

### 4. **CREATE NEW TABLE - price_change_history** ⭐ NEW

This table tracks all price changes made by distributors.

```sql
CREATE TABLE price_change_history (
    price_history_id INT AUTO_INCREMENT PRIMARY KEY,
    dist_inventory_id INT NOT NULL,
    distributor_id INT NOT NULL,
    product_id INT NOT NULL,
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL,
    old_markup_percent DECIMAL(5, 2),
    new_markup_percent DECIMAL(5, 2),
    change_reason VARCHAR(255),
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dist_inventory_id) REFERENCES distributor_inventory(dist_inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_distributor (distributor_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_product (product_id)
);
```

**Why:**
- Needed for "Price History" section on pricing page
- Maintains audit trail of all price changes
- Shows when and who changed prices

**SQL Command:**
```sql
CREATE TABLE price_change_history (
    price_history_id INT AUTO_INCREMENT PRIMARY KEY,
    dist_inventory_id INT NOT NULL,
    distributor_id INT NOT NULL,
    product_id INT NOT NULL,
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL,
    old_markup_percent DECIMAL(5, 2),
    new_markup_percent DECIMAL(5, 2),
    change_reason VARCHAR(255),
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dist_inventory_id) REFERENCES distributor_inventory(dist_inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_distributor (distributor_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_product (product_id)
);
```

---

## 📊 OPTIONAL - Add Analytics Views

These views make analytics queries much faster:

```sql
-- View 1: Distributor Sales Summary
CREATE VIEW distributor_sales_summary AS
SELECT 
    d.distributor_id,
    d.company_name,
    COUNT(DISTINCT co.order_id) as total_orders,
    SUM(oi.quantity) as total_units_sold,
    SUM(oi.subtotal) as total_revenue,
    COUNT(DISTINCT co.customer_id) as unique_customers,
    AVG(oi.unit_price) as avg_selling_price
FROM distributor d
LEFT JOIN order_item oi ON d.distributor_id = oi.seller_id AND oi.seller_type = 'distributor'
LEFT JOIN customer_order co ON oi.order_id = co.order_id
WHERE co.order_status = 'delivered'
GROUP BY d.distributor_id, d.company_name;

-- View 2: Top Products by Distributor
CREATE VIEW top_products_by_distributor AS
SELECT 
    d.distributor_id,
    d.company_name,
    p.product_name,
    p.category,
    SUM(oi.quantity) as units_sold,
    SUM(oi.subtotal) as revenue,
    AVG(p.rating) as avg_rating
FROM distributor d
JOIN order_item oi ON d.distributor_id = oi.seller_id AND oi.seller_type = 'distributor'
JOIN product p ON oi.product_id = p.product_id
JOIN customer_order co ON oi.order_id = co.order_id
WHERE co.order_status = 'delivered'
GROUP BY d.distributor_id, p.product_id
ORDER BY units_sold DESC;

-- View 3: Low Stock Alert
CREATE VIEW distributor_low_stock_alert AS
SELECT 
    di.dist_inventory_id,
    d.distributor_id,
    d.company_name,
    p.product_id,
    p.product_name,
    di.quantity_available,
    di.reorder_level,
    di.cost_price,
    di.unit_price,
    (di.reorder_level * 2 - di.quantity_available) as suggested_reorder_qty,
    m.company_name as manufacturer_name
FROM distributor_inventory di
JOIN distributor d ON di.distributor_id = d.distributor_id
JOIN product p ON di.product_id = p.product_id
JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
WHERE di.quantity_available <= di.reorder_level;
```

---

## 🔄 EXECUTION PLAN

### Option 1: Fresh Start (RECOMMENDED for project)
If you haven't inserted much data yet:

1. Use the new `schema-updated.sql` file provided
2. Drop existing database and recreate with new schema
3. Run `insert_data.sql` again to populate sample data

**Command:**
```bash
# In MySQL
mysql -u root -p < schema-updated.sql
mysql -u root -p < insert_data.sql
```

### Option 2: Migrate Existing Data
If you have important data:

```sql
-- Step 1: Add columns to product
ALTER TABLE product 
ADD COLUMN sku VARCHAR(50) UNIQUE,
ADD COLUMN rating DECIMAL(3, 2) DEFAULT 0,
ADD COLUMN total_reviews INT DEFAULT 0;

-- Step 2: Add columns to customer
ALTER TABLE customer 
ADD COLUMN phone VARCHAR(15),
ADD COLUMN email VARCHAR(100),
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Step 3: Add columns to distributor_inventory (CRITICAL)
ALTER TABLE distributor_inventory 
ADD COLUMN cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
ADD COLUMN reorder_level INT DEFAULT 50;

-- Step 4: Populate cost_price from allocation table
UPDATE distributor_inventory di
SET di.cost_price = (
    SELECT a.unit_price 
    FROM allocation a 
    WHERE a.distributor_id = di.distributor_id 
    AND a.product_id = di.product_id 
    LIMIT 1
);

-- Step 5: Add generated column for markup
ALTER TABLE distributor_inventory 
ADD COLUMN markup_percent DECIMAL(5, 2) GENERATED ALWAYS AS 
    ((unit_price - cost_price) / cost_price * 100) STORED;

-- Step 6: Create price change history table
CREATE TABLE price_change_history (
    price_history_id INT AUTO_INCREMENT PRIMARY KEY,
    dist_inventory_id INT NOT NULL,
    distributor_id INT NOT NULL,
    product_id INT NOT NULL,
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL,
    old_markup_percent DECIMAL(5, 2),
    new_markup_percent DECIMAL(5, 2),
    change_reason VARCHAR(255),
    changed_by INT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (dist_inventory_id) REFERENCES distributor_inventory(dist_inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_distributor (distributor_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_product (product_id)
);

-- Step 7: Add indexes for performance
CREATE INDEX idx_user_type ON users(user_type);
CREATE INDEX idx_customer_created ON customer(created_at);
CREATE INDEX idx_order_customer ON customer_order(customer_id);
CREATE INDEX idx_distributor_allocations ON allocation(distributor_id, allocation_date);
CREATE INDEX idx_manufacturer_products ON product(manufacturer_id);
```

---

## ⚠️ CRITICAL UPDATES FOR SAMPLE DATA

Your `insert_data.sql` also needs updating to include:

1. **SKU values** for products
2. **cost_price in distributor_inventory** 
3. **Email/phone in customers**

---

## Summary Table

| Table | Change | Type | Importance |
|-------|--------|------|-----------|
| product | Add SKU, rating, total_reviews | Add Columns | Medium |
| customer | Add phone, email, created_at | Add Columns | Medium |
| distributor_inventory | Add cost_price, reorder_level, markup_percent | Add Columns | ⭐ CRITICAL |
| price_change_history | Create new table | New Table | High |
| Views | Create 3 views | New Views | Optional |

---

## Files Provided

1. **schema-updated.sql** - Complete updated schema with all changes
2. **This guide** - Explains what changed and why

---

## What Works Without These Changes?

Even without these schema updates, the following will work:

✅ Distributor Orders page (customer_order + order_item have all data)
✅ Order Details page (shipment, payment info available)
✅ Allocations page (allocation table complete)
✅ Basic Dashboard (existing data sufficient)

## What Won't Work Without Updates?

❌ Pricing Management (needs cost_price in distributor_inventory)
❌ Markup Validation (needs cost_price calculation)
❌ Price History (needs price_change_history table)
❌ Low Stock Alerts (needs reorder_level in distributor_inventory)
❌ Some Analytics calculations (needs rating in product)

---

## Recommendation

**Run Option 1 (Fresh Start)** - It's cleaner and ensures everything works perfectly. The updated schema is complete and ready to use.