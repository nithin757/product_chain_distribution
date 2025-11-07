# app.py - Complete Flask Application with MySQL Connector

from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import mysql.connector
from mysql.connector import errorcode
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
from decimal import Decimal

app = Flask(__name__)
app.secret_key = 'your_secret_key_change_this_in_production'

# MySQL Configuration using mysql-connector-python
db_config = {
    'user': 'root',
    'password': '757575',
    'host': 'localhost',
    'database': 'product_chain_distribution',
    'raise_on_warnings': True,
    'autocommit': True
}

# Get database connection
def get_db_connection():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
            print("Database does not exist")
        else:
            print(err)
        return None

# Login required decorator
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

# Get current user
def get_user():
    if 'user_id' not in session:
        return None
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE user_id=%s", (session['user_id'],))
    user = cursor.fetchone()
    cursor.close()
    conn.close()
    return user

# ======================= HOME & AUTH ROUTES =======================

@app.route('/')
def home():
    user = get_user()
    if user:
        if user['user_type'] == 'manufacturer':
            return redirect(url_for('manufacturer_dashboard'))
        elif user['user_type'] == 'distributor':
            return redirect(url_for('distributor_dashboard'))
        elif user['user_type'] == 'customer':
            return redirect(url_for('customer_dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = ''
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        user_type = request.form.get('user_type')

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE username = %s AND user_type = %s", (username, user_type))
        user = cursor.fetchone()
        
        if user and check_password_hash(user['password'], password):
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['user_type'] = user['user_type']
            
            cursor.execute("UPDATE users SET last_login=NOW() WHERE user_id=%s", (user['user_id'],))
            conn.commit()
            cursor.close()
            conn.close()
            return redirect(url_for('home'))
        else:
            error = 'Invalid username or password'
        
        cursor.close()
        conn.close()
    
    return render_template('login.html', error=error)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

# ======================= MANUFACTURER ROUTES =======================

@app.route('/manufacturer/dashboard')
@login_required
def manufacturer_dashboard():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get manufacturer id and company name
    cursor.execute("SELECT manufacturer_id, company_name FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    mfg = cursor.fetchone()
    manufacturer_id = mfg['manufacturer_id']
    company_name = mfg['company_name']
    
    # Total products
    cursor.execute("SELECT COUNT(*) as total FROM product WHERE manufacturer_id = %s", (manufacturer_id,))
    total_products = cursor.fetchone()['total']
    
    # Inventory value
    cursor.execute("""SELECT COALESCE(SUM(i.quantity_available * p.unit_price), 0) as value 
                      FROM inventory i 
                      JOIN product p ON i.product_id = p.product_id 
                      WHERE i.manufacturer_id = %s""", (manufacturer_id,))
    inventory_value = cursor.fetchone()['value']
    
    # Low stock count
    cursor.execute("SELECT COUNT(*) as total FROM inventory WHERE manufacturer_id = %s AND quantity_available <= reorder_level", (manufacturer_id,))
    low_stock = cursor.fetchone()['total']
    
    # Recent allocations
    cursor.execute("""SELECT a.*, d.company_name, p.product_name 
                      FROM allocation a
                      JOIN distributor d ON a.distributor_id = d.distributor_id
                      JOIN product p ON a.product_id = p.product_id
                      WHERE a.manufacturer_id = %s
                      ORDER BY a.allocation_date DESC
                      LIMIT 5""", (manufacturer_id,))
    recent_allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_dashboard.html', 
                         company_name=company_name,
                         total_products=total_products, 
                         inventory_value=inventory_value, 
                         low_stock=low_stock,
                         recent_allocations=recent_allocations)

@app.route('/manufacturer/add_product', methods=['GET', 'POST'])
@login_required
def add_product():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    error = None
    message = None
    
    if request.method == 'POST':
        product_name = request.form.get('product_name')
        description = request.form.get('description')
        category = request.form.get('category')
        unit_price = float(request.form.get('unit_price'))
        manufacturing_cost = float(request.form.get('manufacturing_cost'))
        weight = request.form.get('weight')
        dimensions = request.form.get('dimensions')
        initial_quantity = int(request.form.get('initial_quantity'))
        reorder_level = int(request.form.get('reorder_level'))
        
        # ✅ Validation: Minimum quantity must be at least 100
        if initial_quantity < 100:
            error = "Initial quantity must be 100 or more to add a new product."
            return render_template('manufacturer_add_product.html', error=error)

        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Get manufacturer id
            cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
            manufacturer_id = cursor.fetchone()[0]
            
            # Insert product
            cursor.execute("""INSERT INTO product
                            (manufacturer_id, product_name, description, category, unit_price, manufacturing_cost, weight, dimensions)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)""",
                         (manufacturer_id, product_name, description, category, unit_price, manufacturing_cost, weight, dimensions))
            
            product_id = cursor.lastrowid
            
            # Insert inventory
            cursor.execute("""INSERT INTO inventory (product_id, manufacturer_id, quantity_available, reorder_level)
                            VALUES (%s, %s, %s, %s)""",
                         (product_id, manufacturer_id, initial_quantity, reorder_level))
            
            conn.commit()
            message = 'Product added successfully!'
        except Exception as e:
            conn.rollback()
            error = f'Error: {str(e)}'
        finally:
            cursor.close()
            conn.close()
    
    return render_template('manufacturer_add_product.html', error=error, message=message)


@app.route('/manufacturer/products')
@login_required
def manufacturer_products():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get manufacturer id
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    # Get products
    cursor.execute("""SELECT p.*, i.quantity_available, i.reorder_level 
                      FROM product p
                      LEFT JOIN inventory i ON p.product_id = i.product_id
                      WHERE p.manufacturer_id = %s
                      ORDER BY p.product_name""", (manufacturer_id,))
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_products.html', products=products)

@app.route('/manufacturer/inventory')
@login_required
def manufacturer_inventory():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get manufacturer id
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    # Get inventory
    cursor.execute("""SELECT i.*, p.product_name, p.category, p.unit_price
                      FROM inventory i
                      JOIN product p ON i.product_id = p.product_id
                      WHERE i.manufacturer_id = %s
                      ORDER BY p.product_name""", (manufacturer_id,))
    inventory = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_inventory.html', inventory=inventory)

@app.route('/manufacturer/allocate', methods=['GET', 'POST'])
@login_required
def allocate_product():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    error = None
    message = None
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get manufacturer ID
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer = cursor.fetchone()
    if not manufacturer:
        cursor.close()
        conn.close()
        return render_template('manufacturer_allocate.html', error="Manufacturer profile not found.")
    
    manufacturer_id = manufacturer['manufacturer_id']

    if request.method == 'POST':
        distributor_id = int(request.form.get('distributor_id'))
        product_id = int(request.form.get('product_id'))
        quantity = int(request.form.get('quantity'))

        try:
            # 1️⃣ Check available inventory
            cursor.execute("""
                SELECT i.quantity_available, p.manufacturing_cost, p.unit_price
                FROM inventory i
                JOIN product p ON i.product_id = p.product_id
                WHERE i.product_id = %s AND i.manufacturer_id = %s
            """, (product_id, manufacturer_id))
            inv_row = cursor.fetchone()

            if not inv_row:
                error = 'Inventory record not found for this product.'
            elif inv_row['quantity_available'] < quantity:
                error = f"Insufficient stock! Only {inv_row['quantity_available']} units available."
            else:
                # 2️⃣ Compute prices
                cost_price = Decimal(inv_row['manufacturing_cost'])
                manufacturer_unit_price = Decimal(inv_row['unit_price'])
                distributor_price = (manufacturer_unit_price * Decimal('1.10')).quantize(Decimal('0.01'))  # 10% markup

                # 3️⃣ Record allocation
                cursor.execute("""
                    INSERT INTO allocation 
                        (manufacturer_id, distributor_id, product_id, allocated_quantity, unit_price, status)
                    VALUES (%s, %s, %s, %s, %s, 'completed')
                """, (manufacturer_id, distributor_id, product_id, quantity, distributor_price))

                # 4️⃣ Deduct from manufacturer inventory
                cursor.execute("""
                    UPDATE inventory 
                    SET quantity_available = quantity_available - %s 
                    WHERE product_id = %s AND manufacturer_id = %s
                """, (quantity, product_id, manufacturer_id))

                # 5️⃣ Add/update distributor inventory using alias for MySQL 8+ compliance
                cursor.execute("""
                    INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, cost_price, unit_price)
                    VALUES (%s, %s, %s, %s, %s) AS new
                    ON DUPLICATE KEY UPDATE
                        quantity_available = distributor_inventory.quantity_available + new.quantity_available,
                        cost_price = new.cost_price,
                        unit_price = new.unit_price
                """, (distributor_id, product_id, quantity, cost_price, distributor_price))

                conn.commit()
                message = f'✅ Successfully allocated {quantity} units to distributor.'

        except Exception as e:
            conn.rollback()
            error = f"Error during allocation: {str(e)}"
    
    # Load distributor and product dropdowns
    cursor.execute("SELECT distributor_id, company_name FROM distributor ORDER BY company_name")
    distributors = cursor.fetchall()
    
    cursor.execute("""
        SELECT p.product_id, p.product_name, i.quantity_available 
        FROM product p
        LEFT JOIN inventory i ON p.product_id = i.product_id
        WHERE p.manufacturer_id = %s
        ORDER BY p.product_name
    """, (manufacturer_id,))
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template(
        'manufacturer_allocate.html',
        error=error,
        message=message,
        distributors=distributors,
        products=products
    )


@app.route('/manufacturer/allocations')
@login_required
def manufacturer_allocations():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get manufacturer id
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    # Get allocations
    cursor.execute("""SELECT a.*, d.company_name, p.product_name 
                      FROM allocation a
                      JOIN distributor d ON a.distributor_id = d.distributor_id
                      JOIN product p ON a.product_id = p.product_id
                      WHERE a.manufacturer_id = %s
                      ORDER BY a.allocation_date DESC""", (manufacturer_id,))
    allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_allocations.html', allocations=allocations)

# ======================= DISTRIBUTOR ROUTES =======================

@app.route('/distributor/dashboard')
@login_required
def distributor_dashboard():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get distributor id and company name
    cursor.execute("SELECT distributor_id, company_name FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist = cursor.fetchone()
    distributor_id = dist['distributor_id']
    company_name = dist['company_name']
    
    # Get stats
    cursor.execute("""SELECT COUNT(DISTINCT product_id) as unique_products,
                             COALESCE(SUM(quantity_available), 0) as total_units,
                             COALESCE(SUM(quantity_available * unit_price), 0) as inventory_value
                      FROM distributor_inventory
                      WHERE distributor_id = %s""", (distributor_id,))
    stats = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_dashboard.html',
                         company_name=company_name,
                         unique_products=stats['unique_products'] or 0,
                         total_units=stats['total_units'] or 0,
                         inventory_value=stats['inventory_value'] or 0)

@app.route('/distributor/inventory')
@login_required
def distributor_inventory():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get distributor id
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    distributor_id = cursor.fetchone()['distributor_id']
    
    # Get inventory
    cursor.execute("""SELECT di.*, p.product_name, p.category, p.description
                      FROM distributor_inventory di
                      JOIN product p ON di.product_id = p.product_id
                      WHERE di.distributor_id = %s
                      ORDER BY p.product_name""", (distributor_id,))
    inventory = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_inventory.html', inventory=inventory)

@app.route('/distributor/update_price', methods=['POST'])
@login_required
def update_distributor_price():
    if session.get('user_type') != 'distributor':
        return jsonify({'success': False, 'message': 'Unauthorized'})
    
    dist_inventory_id = request.form.get('dist_inventory_id')
    new_price = float(request.form.get('new_price'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Get distributor id
        cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
        distributor_id = cursor.fetchone()[0]
        
        # Update price
        cursor.execute("""UPDATE distributor_inventory 
                         SET unit_price = %s 
                         WHERE dist_inventory_id = %s AND distributor_id = %s""",
                     (new_price, dist_inventory_id, distributor_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Price updated successfully'})
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': str(e)})

@app.route('/distributor/allocations')
@login_required
def distributor_allocations():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get distributor id
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    distributor_id = cursor.fetchone()['distributor_id']
    
    # Get allocations
    cursor.execute("""SELECT a.*, m.company_name as manufacturer_name, p.product_name 
                      FROM allocation a
                      JOIN manufacturer m ON a.manufacturer_id = m.manufacturer_id
                      JOIN product p ON a.product_id = p.product_id
                      WHERE a.distributor_id = %s
                      ORDER BY a.allocation_date DESC""", (distributor_id,))
    allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_allocations.html', allocations=allocations)

@app.route('/distributor/customer_orders')
@login_required
def distributor_customer_orders():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    # Get distributor ID
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    distributor = cursor.fetchone()
    distributor_id = distributor['distributor_id']

    # ✅ Retrieve customer orders for products that this distributor currently has in inventory
    cursor.execute("""
        SELECT 
            co.order_id,
            co.order_date,
            co.total_amount,
            co.order_status,
            co.payment_status,
            c.first_name,
            c.last_name,
            p.product_name,
            oi.quantity,
            oi.unit_price,
            di.quantity_available AS dist_stock
        FROM customer_order co
        JOIN order_item oi ON co.order_id = oi.order_id
        JOIN product p ON oi.product_id = p.product_id
        JOIN customer c ON co.customer_id = c.customer_id
        JOIN distributor_inventory di 
             ON di.product_id = oi.product_id 
             AND di.distributor_id = oi.seller_id
        WHERE oi.seller_type = 'distributor' 
          AND oi.seller_id = %s
        ORDER BY co.order_date DESC
    """, (distributor_id,))

    orders = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('distributor_customer_orders.html', orders=orders)


# ======================= CUSTOMER ROUTES =======================

@app.route('/customer/dashboard')
@login_required
def customer_dashboard():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get customer id and name
    cursor.execute("SELECT customer_id, first_name, last_name, loyalty_points FROM customer WHERE user_id = %s", 
                 (session['user_id'],))
    cust = cursor.fetchone()
    customer_id = cust['customer_id']
    customer_name = f"{cust['first_name']} {cust['last_name']}"
    
    # Order stats
    cursor.execute("""SELECT COUNT(*) as total_orders, COALESCE(SUM(total_amount), 0) as total_spent
                      FROM customer_order
                      WHERE customer_id = %s""", (customer_id,))
    stats = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    return render_template('customer_dashboard.html',
                         customer_name=customer_name,
                         loyalty_points=cust['loyalty_points'],
                         total_orders=stats['total_orders'] or 0,
                         total_spent=stats['total_spent'] or 0)

@app.route('/customer/browse_products')
@login_required
def browse_products():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    category = request.args.get('category', '')
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if category:
        cursor.execute("""
            SELECT 
                p.product_id,
                p.product_name,
                p.category,
                p.description,
                m.company_name,
                COALESCE(
                    (SELECT MIN(di.unit_price)
                    FROM distributor_inventory di
                    WHERE di.product_id = p.product_id AND di.quantity_available > 0),
                    p.unit_price
                ) AS display_price
            FROM product p
            JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
            WHERE p.category = %s
            ORDER BY p.product_name
        """, (category,))
    else:
        cursor.execute("""
            SELECT 
                p.product_id,
                p.product_name,
                p.category,
                p.description,
                m.company_name,
                COALESCE(
                    (SELECT MIN(di.unit_price)
                    FROM distributor_inventory di
                    WHERE di.product_id = p.product_id AND di.quantity_available > 0),
                    p.unit_price
                ) AS display_price
            FROM product p
            JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
            ORDER BY p.product_name
        """)

    
    products = cursor.fetchall()
    
    # Get categories
    cursor.execute("SELECT DISTINCT category FROM product ORDER BY category")
    categories = [row['category'] for row in cursor.fetchall()]
    
    cursor.close()
    conn.close()
    
    return render_template('customer_browse_products.html', 
                         products=products, 
                         categories=categories, 
                         selected_category=category)

@app.route('/customer/place_order', methods=['POST'])
@login_required
def place_order():
    if session.get('user_type') != 'customer':
        return jsonify({'success': False, 'message': 'Unauthorized'})
    
    product_id = int(request.form.get('product_id'))
    quantity = int(request.form.get('quantity'))
    shipping_address = request.form.get('shipping_address')

    # ✅ Enforce minimum order quantity of 2
    warning = None
    if quantity < 2:
        warning = "Minimum order quantity is 2. Your order has been adjusted automatically."
        quantity = 2

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Get customer id
        cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
        customer_id = cursor.fetchone()['customer_id']
        
        # Check distributor inventory first
        cursor.execute("""SELECT di.distributor_id, di.unit_price, di.quantity_available
                          FROM distributor_inventory di
                          WHERE di.product_id = %s AND di.quantity_available >= %s
                          LIMIT 1""", (product_id, quantity))
        
        dist_inv = cursor.fetchone()
        
        if dist_inv:
            seller_type = 'distributor'
            seller_id = dist_inv['distributor_id']
            unit_price = dist_inv['unit_price']
        else:
            # Try manufacturer
            cursor.execute("""SELECT i.manufacturer_id, p.unit_price, i.quantity_available
                              FROM inventory i
                              JOIN product p ON i.product_id = p.product_id
                              WHERE i.product_id = %s AND i.quantity_available >= %s
                              LIMIT 1""", (product_id, quantity))
            
            mfg_inv = cursor.fetchone()
            
            if not mfg_inv:
                return jsonify({'success': False, 'message': 'Product not available'})
            
            seller_type = 'manufacturer'
            seller_id = mfg_inv['manufacturer_id']
            unit_price = mfg_inv['unit_price']
        
        # Create order
        total_amount = quantity * unit_price
        
        cursor.execute("""INSERT INTO customer_order 
                         (customer_id, total_amount, order_status, payment_status, shipping_address)
                         VALUES (%s, %s, 'pending', 'pending', %s)""",
                     (customer_id, total_amount, shipping_address))
        
        order_id = cursor.lastrowid
        
        # Add order item
        cursor.execute("""INSERT INTO order_item 
                         (order_id, product_id, seller_type, seller_id, quantity, unit_price)
                         VALUES (%s, %s, %s, %s, %s, %s)""",
                     (order_id, product_id, seller_type, seller_id, quantity, unit_price))
        
        # Update inventory
        if seller_type == 'distributor':
            cursor.execute("""UPDATE distributor_inventory 
                             SET quantity_available = quantity_available - %s 
                             WHERE distributor_id = %s AND product_id = %s""",
                         (quantity, seller_id, product_id))
        else:
            cursor.execute("""UPDATE inventory 
                             SET quantity_available = quantity_available - %s 
                             WHERE manufacturer_id = %s AND product_id = %s""",
                         (quantity, seller_id, product_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        response = {
            'success': True,
            'message': 'Order placed successfully',
            'order_id': order_id
        }

        # Include warning if triggered
        if warning:
            response['warning'] = warning

        return jsonify(response)

    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': str(e)})


@app.route('/customer/orders')
@login_required
def customer_orders():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get customer id
    cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
    customer_id = cursor.fetchone()['customer_id']
    
    # Get orders
    cursor.execute("""SELECT * FROM customer_order 
                      WHERE customer_id = %s
                      ORDER BY order_date DESC""", (customer_id,))
    orders = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('customer_orders.html', orders=orders)

@app.route('/customer/order_details/<int:order_id>')
@login_required
def order_details(order_id):
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Get customer id
    cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
    customer_id = cursor.fetchone()['customer_id']
    
    # Get order
    cursor.execute("""SELECT * FROM customer_order 
                      WHERE order_id = %s AND customer_id = %s""", (order_id, customer_id))
    order = cursor.fetchone()
    
    if not order:
        cursor.close()
        conn.close()
        return redirect(url_for('customer_orders'))
    
    # Get order items
    cursor.execute("""SELECT oi.*, p.product_name, p.category
                      FROM order_item oi
                      JOIN product p ON oi.product_id = p.product_id
                      WHERE oi.order_id = %s""", (order_id,))
    items = cursor.fetchall()
    
    # Get shipment
    cursor.execute("""SELECT * FROM shipment WHERE order_id = %s""", (order_id,))
    shipment = cursor.fetchone()
    
    cursor.close()
    conn.close()
    
    return render_template('customer_order_details.html', order=order, items=items, shipment=shipment)

@app.route('/customer/process_payment/<int:order_id>', methods=['POST'])
@login_required
def process_payment(order_id):
    if session.get('user_type') != 'customer':
        return jsonify({'success': False, 'message': 'Unauthorized'})
    
    payment_method = request.form.get('payment_method')
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Get customer id
        cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
        customer_id = cursor.fetchone()['customer_id']
        
        # Get order
        cursor.execute("""SELECT total_amount FROM customer_order 
                          WHERE order_id = %s AND customer_id = %s""", (order_id, customer_id))
        order = cursor.fetchone()
        
        if not order:
            return jsonify({'success': False, 'message': 'Order not found'})
        
        # Create payment record
        transaction_id = f"TXN-{order_id}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        cursor.execute("""INSERT INTO payment 
                         (order_id, payment_method, amount, payment_status, transaction_id)
                         VALUES (%s, %s, %s, 'success', %s)""",
                     (order_id, payment_method, order['total_amount'], transaction_id))
        
        # Update order status
        cursor.execute("""UPDATE customer_order 
                         SET payment_status = 'paid', order_status = 'processing'
                         WHERE order_id = %s""", (order_id,))
        
        # Create shipment
        tracking_number = f"TRACK-{order_id}-{datetime.now().strftime('%Y%m%d')}"
        
        cursor.execute("""INSERT INTO shipment 
                         (order_id, estimated_delivery_date, tracking_number, carrier, shipment_status)
                         VALUES (%s, DATE_ADD(NOW(), INTERVAL 7 DAY), %s, 'Standard Carrier', 'preparing')""",
                     (order_id, tracking_number))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({'success': True, 'message': 'Payment processed successfully'})
    except Exception as e:
        conn.rollback()
        cursor.close()
        conn.close()
        return jsonify({'success': False, 'message': str(e)})

if __name__ == '__main__':
    app.run(debug=True, host='localhost', port=5000)
