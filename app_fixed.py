from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import mysql.connector
from mysql.connector import errorcode
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime, timedelta
from decimal import Decimal

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-this-in-production'

# MySQL Configuration
db_config = {
    'user': 'root',
    'password': '757575',  # Change this to your MySQL password
    'host': 'localhost',
    'database': 'product_chain_distribution',
    'raise_on_warnings': True,
    'autocommit': True
}

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

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function

def get_user():
    if 'user_id' not in session:
        return None
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE user_id = %s", (session['user_id'],))
    user = cursor.fetchone()
    cursor.close()
    conn.close()
    return user

# ===========================
# HOME & AUTH ROUTES
# ===========================

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
    error = None
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
            
            cursor.execute("UPDATE users SET last_login = NOW() WHERE user_id = %s", (user['user_id'],))
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

# ===========================
# MANUFACTURER ROUTES
# ===========================

@app.route('/manufacturer/dashboard')
@login_required
def manufacturer_dashboard():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT manufacturer_id, company_name FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    mfg = cursor.fetchone()
    manufacturer_id = mfg['manufacturer_id']
    company_name = mfg['company_name']
    
    cursor.execute("SELECT COUNT(*) as total FROM product WHERE manufacturer_id = %s", (manufacturer_id,))
    total_products = cursor.fetchone()['total']
    
    cursor.execute("SELECT COALESCE(SUM(i.quantity_available * p.unit_price), 0) as value FROM inventory i JOIN product p ON i.product_id = p.product_id WHERE i.manufacturer_id = %s", (manufacturer_id,))
    inventory_value = cursor.fetchone()['value']
    
    cursor.execute("SELECT COUNT(*) as total FROM inventory WHERE manufacturer_id = %s AND quantity_available <= reorder_level", (manufacturer_id,))
    low_stock = cursor.fetchone()['total']
    
    cursor.execute("SELECT a.*, d.company_name, p.product_name FROM allocation a JOIN distributor d ON a.distributor_id = d.distributor_id JOIN product p ON a.product_id = p.product_id WHERE a.manufacturer_id = %s ORDER BY a.allocation_date DESC LIMIT 5", (manufacturer_id,))
    recent_allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_dashboard.html',
                         company_name=company_name,
                         total_products=total_products,
                         inventory_value=inventory_value,
                         low_stock=low_stock,
                         recent_allocations=recent_allocations,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/manufacturer_products')
@login_required
def manufacturer_products():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    cursor.execute("SELECT p.*, i.quantity_available, i.reorder_level FROM product p LEFT JOIN inventory i ON p.product_id = i.product_id WHERE p.manufacturer_id = %s ORDER BY p.product_name", (manufacturer_id,))
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_products.html',
                         products=products,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/manufacturer_inventory')
@login_required
def manufacturer_inventory():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    cursor.execute("SELECT i.*, p.product_name, p.category, p.unit_price, p.sku FROM inventory i JOIN product p ON i.product_id = p.product_id WHERE i.manufacturer_id = %s ORDER BY p.product_name", (manufacturer_id,))
    inventory = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_inventory.html',
                         inventory=inventory,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/manufacturer_add_product', methods=['GET', 'POST'])
@login_required
def manufacturer_add_product():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    error = None
    message = None
    
    if request.method == 'POST':
        product_name = request.form.get('product_name')
        description = request.form.get('description')
        category = request.form.get('category')
        sku = request.form.get('sku')
        unit_price = float(request.form.get('unit_price'))
        manufacturing_cost = float(request.form.get('manufacturing_cost'))
        weight = request.form.get('weight')
        dimensions = request.form.get('dimensions')
        initial_quantity = int(request.form.get('initial_quantity'))
        reorder_level = int(request.form.get('reorder_level'))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
            manufacturer_id = cursor.fetchone()[0]
            
            cursor.execute("""INSERT INTO product (manufacturer_id, product_name, description, category, sku, unit_price, manufacturing_cost, weight, dimensions)
                            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                          (manufacturer_id, product_name, description, category, sku, unit_price, manufacturing_cost, weight, dimensions))
            
            product_id = cursor.lastrowid
            
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
    
    return render_template('manufacturer_add_product.html',
                         error=error,
                         message=message,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/manufacturer_allocate', methods=['GET', 'POST'])
@login_required
def manufacturer_allocate():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    error = None
    message = None
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    if request.method == 'POST':
        distributor_id = int(request.form.get('distributor_id'))
        product_id = int(request.form.get('product_id'))
        quantity = int(request.form.get('quantity'))
        
        try:
            cursor.execute("SELECT quantity_available FROM inventory WHERE product_id = %s AND manufacturer_id = %s", (product_id, manufacturer_id))
            inv_row = cursor.fetchone()
            
            if not inv_row or inv_row['quantity_available'] < quantity:
                error = 'Insufficient inventory'
            else:
                cursor.execute("SELECT unit_price FROM product WHERE product_id = %s", (product_id,))
                product = cursor.fetchone()
                unit_price = product['unit_price']
                
                cursor.execute("""INSERT INTO allocation (manufacturer_id, distributor_id, product_id, allocated_quantity, unit_price, status)
                                VALUES (%s, %s, %s, %s, %s, 'completed')""",
                              (manufacturer_id, distributor_id, product_id, quantity, unit_price))
                
                cursor.execute("""UPDATE inventory SET quantity_available = quantity_available - %s
                                WHERE product_id = %s AND manufacturer_id = %s""",
                              (quantity, product_id, manufacturer_id))
                
                # Calculate distributor price (with 10% minimum markup)
                distributor_price = unit_price * 1.10
                markup_percent = 10
                
                # Update or insert in distributor_inventory
                cursor.execute("SELECT * FROM distributor_inventory WHERE distributor_id = %s AND product_id = %s", (distributor_id, product_id))
                
                if cursor.fetchone():
                    cursor.execute("""UPDATE distributor_inventory SET quantity_available = quantity_available + %s, unit_price = %s, cost_price = %s, reorder_level = 50
                                    WHERE distributor_id = %s AND product_id = %s""",
                                  (quantity, distributor_price, unit_price, distributor_id, product_id))
                else:
                    cursor.execute("""INSERT INTO distributor_inventory (distributor_id, product_id, quantity_available, unit_price, cost_price, reorder_level)
                                    VALUES (%s, %s, %s, %s, %s, 50)""",
                                  (distributor_id, product_id, quantity, distributor_price, unit_price))
                
                conn.commit()
                message = 'Product allocated successfully!'
        except Exception as e:
            conn.rollback()
            error = f'Error: {str(e)}'
    
    cursor.execute("SELECT distributor_id, company_name FROM distributor ORDER BY company_name")
    distributors = cursor.fetchall()
    
    cursor.execute("SELECT p.product_id, p.product_name, p.sku, i.quantity_available FROM product p LEFT JOIN inventory i ON p.product_id = i.product_id WHERE p.manufacturer_id = %s ORDER BY p.product_name", (manufacturer_id,))
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_allocate.html',
                         error=error,
                         message=message,
                         distributors=distributors,
                         products=products,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/manufacturer_allocations')
@login_required
def manufacturer_allocations():
    if session.get('user_type') != 'manufacturer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT manufacturer_id FROM manufacturer WHERE user_id = %s", (session['user_id'],))
    manufacturer_id = cursor.fetchone()['manufacturer_id']
    
    cursor.execute("""SELECT a.*, d.company_name, p.product_name FROM allocation a
                    JOIN distributor d ON a.distributor_id = d.distributor_id
                    JOIN product p ON a.product_id = p.product_id
                    WHERE a.manufacturer_id = %s ORDER BY a.allocation_date DESC""", (manufacturer_id,))
    allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('manufacturer_allocations.html',
                         allocations=allocations,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

# ===========================
# DISTRIBUTOR ROUTES
# ===========================

@app.route('/distributor/dashboard')
@login_required
def distributor_dashboard():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT distributor_id, company_name FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist = cursor.fetchone()
    if not dist:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    distributor_id = dist['distributor_id']
    company_name = dist['company_name']
    
    cursor.execute("""SELECT DISTINCT product_id FROM distributor_inventory WHERE distributor_id = %s""", (distributor_id,))
    unique_products = len(cursor.fetchall())
    
    cursor.execute("""SELECT COALESCE(SUM(quantity_available), 0) as total_units FROM distributor_inventory WHERE distributor_id = %s""", (distributor_id,))
    total_units = cursor.fetchone()['total_units']
    
    cursor.execute("""SELECT COALESCE(SUM(quantity_available * unit_price), 0) as value FROM distributor_inventory WHERE distributor_id = %s""", (distributor_id,))
    inventory_value = cursor.fetchone()['value']
    
    cursor.execute("""SELECT COALESCE(COUNT(DISTINCT co.order_id), 0) as total FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    total_orders = cursor.fetchone()['total']
    
    cursor.execute("""SELECT COALESCE(SUM(co.total_amount), 0) as value FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    total_revenue = cursor.fetchone()['value']
    
    cursor.execute("""SELECT COUNT(*) as count FROM distributor_inventory WHERE distributor_id = %s AND quantity_available <= reorder_level""", (distributor_id,))
    low_stock_count = cursor.fetchone()['count']
    
    cursor.execute("""SELECT a.*, m.company_name as manufacturer_name, p.product_name FROM allocation a
                    JOIN manufacturer m ON a.manufacturer_id = m.manufacturer_id
                    JOIN product p ON a.product_id = p.product_id
                    WHERE a.distributor_id = %s ORDER BY a.allocation_date DESC LIMIT 5""", (distributor_id,))
    allocations = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_dashboard.html',
                         company_name=company_name,
                         unique_products=unique_products,
                         total_units=total_units,
                         inventory_value=inventory_value,
                         total_orders=total_orders,
                         total_revenue=total_revenue,
                         low_stock_count=low_stock_count,
                         allocations=allocations,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/distributor_inventory')
@login_required
def distributor_inventory():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist_row = cursor.fetchone()
    if not dist_row:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    distributor_id = dist_row['distributor_id']
    
    cursor.execute("""SELECT di.*, p.product_name, p.category, p.description, p.sku,
                    ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as markup_percent
                    FROM distributor_inventory di
                    JOIN product p ON di.product_id = p.product_id
                    WHERE di.distributor_id = %s ORDER BY p.product_name""", (distributor_id,))
    inventory = cursor.fetchall()
    
    cursor.execute("""SELECT di.*, p.product_name, i.reorder_level, m.company_name
                    FROM distributor_inventory di
                    JOIN product p ON di.product_id = p.product_id
                    JOIN inventory i ON p.product_id = i.product_id
                    JOIN manufacturer m ON p.manufacturer_id = m.manufacturer_id
                    WHERE di.distributor_id = %s AND di.quantity_available <= di.reorder_level""", (distributor_id,))
    low_stock_items = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    total_products = len(inventory)
    total_units = sum(item['quantity_available'] for item in inventory)
    inventory_total = sum(item['quantity_available'] * item['unit_price'] for item in inventory)
    low_stock_count = len(low_stock_items)
    
    return render_template('distributor_inventory.html',
                         inventory=inventory,
                         low_stock_items=low_stock_items,
                         total_products=total_products,
                         total_units=total_units,
                         inventory_value=inventory_total,
                         low_stock_count=low_stock_count,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/distributor_orders')
@login_required
def distributor_orders():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist_row = cursor.fetchone()
    if not dist_row:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    distributor_id = dist_row['distributor_id']
    
    cursor.execute("""SELECT DISTINCT co.order_id, co.order_date, c.first_name, c.last_name, c.email,
                    COUNT(oi.order_item_id) as item_count, co.total_amount,
                    co.order_status, co.payment_status
                    FROM customer_order co
                    JOIN customer c ON co.customer_id = c.customer_id
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s
                    GROUP BY co.order_id
                    ORDER BY co.order_date DESC""", (distributor_id,))
    orders = cursor.fetchall()
    
    cursor.execute("""SELECT COALESCE(COUNT(DISTINCT co.order_id), 0) as total FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    total_orders = cursor.fetchone()['total']
    
    cursor.execute("""SELECT COALESCE(SUM(co.total_amount), 0) as value FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    total_revenue = cursor.fetchone()['value']
    
    cursor.execute("""SELECT COUNT(CASE WHEN co.order_status = 'processing' OR co.order_status = 'pending' THEN 1 END) as count FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    pending_shipments = cursor.fetchone()['count']
    
    cursor.execute("""SELECT COUNT(CASE WHEN co.order_status = 'delivered' THEN 1 END) as count FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    completed_orders = cursor.fetchone()['count']
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_orders.html',
                         orders=orders,
                         total_orders=total_orders,
                         total_revenue=total_revenue,
                         pending_shipments=pending_shipments,
                         completed_orders=completed_orders,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/distributor_pricing')
@login_required
def distributor_pricing():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist_row = cursor.fetchone()
    if not dist_row:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    distributor_id = dist_row['distributor_id']
    
    cursor.execute("""SELECT di.*, p.product_name, p.category, p.sku,
                    ROUND((di.unit_price - di.cost_price) / di.cost_price * 100, 2) as current_markup,
                    ROUND(di.cost_price * 1.10, 2) as min_price
                    FROM distributor_inventory di
                    JOIN product p ON di.product_id = p.product_id
                    WHERE di.distributor_id = %s
                    ORDER BY p.product_name""", (distributor_id,))
    products = cursor.fetchall()
    
    cursor.execute("""SELECT * FROM price_change_history
                    WHERE distributor_id = %s
                    ORDER BY changed_at DESC LIMIT 10""", (distributor_id,))
    price_history = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_pricing.html',
                         products=products,
                         price_history=price_history,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/distributor_analytics')
@login_required
def distributor_analytics():
    if session.get('user_type') != 'distributor':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT distributor_id FROM distributor WHERE user_id = %s", (session['user_id'],))
    dist_row = cursor.fetchone()
    if not dist_row:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    distributor_id = dist_row['distributor_id']
    
    cursor.execute("""SELECT COALESCE(SUM(co.total_amount), 0) as value FROM customer_order co
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s""", (distributor_id,))
    total_revenue = cursor.fetchone()['value']
    
    cursor.execute("""SELECT p.product_name, p.category, SUM(oi.quantity) as units_sold, SUM(oi.subtotal) as revenue,
                    AVG(p.rating) as rating
                    FROM order_item oi
                    JOIN product p ON oi.product_id = p.product_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s
                    GROUP BY p.product_id
                    ORDER BY units_sold DESC LIMIT 5""", (distributor_id,))
    top_products = cursor.fetchall()
    
    cursor.execute("""SELECT c.first_name, c.last_name, c.email,
                    COUNT(co.order_id) as order_count, SUM(co.total_amount) as total_spent
                    FROM customer_order co
                    JOIN customer c ON co.customer_id = c.customer_id
                    JOIN order_item oi ON co.order_id = oi.order_id
                    WHERE oi.seller_type = 'distributor' AND oi.seller_id = %s
                    GROUP BY c.customer_id
                    ORDER BY total_spent DESC LIMIT 5""", (distributor_id,))
    top_customers = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('distributor_analytics.html',
                         total_revenue=total_revenue,
                         top_products=top_products,
                         top_customers=top_customers,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

# ===========================
# CUSTOMER ROUTES
# ===========================

@app.route('/customer/dashboard')
@login_required
def customer_dashboard():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
    cust = cursor.fetchone()
    if not cust:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    customer_id = cust['customer_id']
    
    cursor.execute("SELECT COUNT(*) as total FROM customer_order WHERE customer_id = %s", (customer_id,))
    total_orders = cursor.fetchone()['total']
    
    cursor.execute("SELECT COALESCE(SUM(total_amount), 0) as value FROM customer_order WHERE customer_id = %s", (customer_id,))
    total_spent = cursor.fetchone()['value']
    
    cursor.execute("SELECT loyalty_points FROM customer WHERE customer_id = %s", (customer_id,))
    loyalty_points = cursor.fetchone()['loyalty_points']
    
    cursor.close()
    conn.close()
    
    return render_template('customer_dashboard.html',
                         total_orders=total_orders,
                         total_spent=total_spent,
                         loyalty_points=loyalty_points,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/customer_browse_products')
@login_required
def customer_browse_products():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("""SELECT DISTINCT p.*, di.unit_price, di.quantity_available,
                    CASE WHEN di.quantity_available > 0 THEN 'Available' ELSE 'Out of Stock' END as availability
                    FROM product p
                    LEFT JOIN distributor_inventory di ON p.product_id = di.product_id
                    WHERE di.quantity_available > 0
                    ORDER BY p.product_name""")
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('customer_browse_products.html',
                         products=products,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

@app.route('/customer_orders')
@login_required
def customer_orders():
    if session.get('user_type') != 'customer':
        return redirect(url_for('home'))
    
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT customer_id FROM customer WHERE user_id = %s", (session['user_id'],))
    cust = cursor.fetchone()
    if not cust:
        cursor.close()
        conn.close()
        return redirect(url_for('login'))
    
    customer_id = cust['customer_id']
    
    cursor.execute("SELECT * FROM customer_order WHERE customer_id = %s ORDER BY order_date DESC", (customer_id,))
    orders = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('customer_orders.html',
                         orders=orders,
                         username=session.get('username'),
                         user_type=session.get('user_type'),
                         last_login=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

if __name__ == '__main__':
    app.run(debug=True, host='127.0.0.1', port=5000)