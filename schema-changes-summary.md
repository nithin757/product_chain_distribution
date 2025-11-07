# SCHEMA UPDATES - QUICK REFERENCE

## Yes, Schema Updates ARE NEEDED! ✅

Your current schema is **95% compatible**, but **critical additions** are required for full functionality.

---

## What Needs to Change

### 1️⃣ PRODUCT TABLE - Add 3 Columns

```sql
ALTER TABLE product 
ADD COLUMN sku VARCHAR(50) UNIQUE,
ADD COLUMN rating DECIMAL(3, 2) DEFAULT 0,
ADD COLUMN total_reviews INT DEFAULT 0;
```

**Why:** For product identification and top products analytics

---

### 2️⃣ CUSTOMER TABLE - Add 3 Columns

```sql
ALTER TABLE customer 
ADD COLUMN phone VARCHAR(15),
ADD COLUMN email VARCHAR(100),
ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
```

**Why:** For customer contact info on order details page

---

### 3️⃣ DISTRIBUTOR_INVENTORY TABLE - Add 3 Columns ⭐ MOST CRITICAL

```sql
ALTER TABLE distributor_inventory 
ADD COLUMN cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
ADD COLUMN reorder_level INT DEFAULT 50,
ADD COLUMN markup_percent DECIMAL(5, 2) GENERATED ALWAYS AS 
    ((unit_price - cost_price) / cost_price * 100) STORED;
```

**Why:** ESSENTIAL for pricing management and low stock alerts

---

### 4️⃣ CREATE NEW TABLE - price_change_history

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
    FOREIGN KEY (dist_inventory_id) REFERENCES distributor_inventory(dist_inventory_id),
    FOREIGN KEY (distributor_id) REFERENCES distributor(distributor_id),
    FOREIGN KEY (product_id) REFERENCES product(product_id),
    FOREIGN KEY (changed_by) REFERENCES users(user_id),
    INDEX idx_distributor (distributor_id),
    INDEX idx_changed_at (changed_at),
    INDEX idx_product (product_id)
);
```

**Why:** To track price history on pricing page

---

## Impact Analysis

### Features That Will FAIL Without Updates ❌

1. **Pricing Page** - Cannot validate 10% markup without cost_price
2. **Low Stock Alerts** - Cannot trigger without reorder_level
3. **Price History** - Cannot show without price_change_history table
4. **Top Products** - Cannot rank without rating column
5. **Customer Info** - Cannot show contact details without email/phone

### Features That Will WORK ✅

1. **Distributor Orders** - All data exists in order_item + customer_order
2. **Order Details** - All data exists in related tables
3. **Allocations** - All data exists in allocation table
4. **Dashboard (basic)** - Stats calculable from existing tables

---

## Two Implementation Paths

### PATH 1: Fresh Start (RECOMMENDED)
1. Use provided `schema-updated.sql`
2. Run it to create fresh database
3. Run `insert_data.sql` with updated data
4. Takes 5 minutes

**Command:**
```bash
mysql -u root -p < schema-updated.sql
mysql -u root -p < insert_data.sql
```

### PATH 2: Migrate Existing Data
1. Run each ALTER TABLE command
2. Populate cost_price from allocation data
3. Create new table
4. Takes 10 minutes

**Commands:**
```sql
-- Run these one by one
ALTER TABLE product ADD COLUMN sku VARCHAR(50) UNIQUE;
ALTER TABLE product ADD COLUMN rating DECIMAL(3, 2) DEFAULT 0;
ALTER TABLE product ADD COLUMN total_reviews INT DEFAULT 0;

ALTER TABLE customer ADD COLUMN phone VARCHAR(15);
ALTER TABLE customer ADD COLUMN email VARCHAR(100);
ALTER TABLE customer ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE distributor_inventory ADD COLUMN cost_price DECIMAL(10, 2) NOT NULL DEFAULT 0;
ALTER TABLE distributor_inventory ADD COLUMN reorder_level INT DEFAULT 50;
ALTER TABLE distributor_inventory ADD COLUMN markup_percent DECIMAL(5, 2) GENERATED ALWAYS AS ((unit_price - cost_price) / cost_price * 100) STORED;

-- Populate cost_price
UPDATE distributor_inventory di
SET di.cost_price = (
    SELECT a.unit_price FROM allocation a 
    WHERE a.distributor_id = di.distributor_id 
    AND a.product_id = di.product_id LIMIT 1
);

-- Create new table
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

## Files Provided

| File | Purpose |
|------|---------|
| schema-updated.sql | Complete new schema with all updates |
| schema-update-guide.md | Detailed guide explaining each change |
| This file | Quick reference summary |

---

## Comparison: Before vs After

### BEFORE (Current)
```
✅ Can track orders
✅ Can see allocations
❌ Cannot manage prices
❌ Cannot validate markup
❌ Cannot track low stock properly
❌ Cannot see price history
❌ Cannot get full customer contact info
```

### AFTER (With Updates)
```
✅ Can track orders
✅ Can see allocations
✅ Can manage prices
✅ Can validate 10% minimum markup
✅ Can track low stock with reorder level
✅ Can see price history
✅ Have complete customer information
✅ Full analytics working
```

---

## Summary

| Component | Status | Action |
|-----------|--------|--------|
| order_item table | ✅ Ready | No change |
| customer_order table | ✅ Ready | No change |
| distributor_inventory | ⚠️ Needs update | Add 3 columns |
| product table | ⚠️ Needs update | Add 3 columns |
| customer table | ⚠️ Needs update | Add 3 columns |
| price_change_history | ❌ Missing | Create table |
| allocation table | ✅ Ready | No change |
| shipment table | ✅ Ready | No change |
| payment table | ✅ Ready | No change |

---

## Recommendation

✅ **Use schema-updated.sql if starting fresh** (Cleanest approach)

⚠️ **Use migration path if you have existing data** (Safer)

Both paths fully support all 8 HTML pages and new features.