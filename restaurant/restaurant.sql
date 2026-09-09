-- ============================================================

-- SQLFoundry - Restaurant Management System

-- Database: MySQL 8.0+

-- File: restaurant.sql

-- ============================================================

DROP DATABASE IF EXISTS restaurant_db;

CREATE DATABASE restaurant_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE restaurant_db;

-- ============================================================
-- CUSTOMERS
-- ============================================================

CREATE TABLE customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- EMPLOYEES
-- ============================================================

CREATE TABLE employees (
    employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) UNIQUE,
    role ENUM(
        'manager',
        'chef',
        'waiter',
        'cashier',
        'host',
        'cleaner'
    ) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2),
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_employee_salary
        CHECK (salary IS NULL OR salary >= 0)
);

-- ============================================================
-- RESTAURANT TABLES
-- ============================================================

CREATE TABLE restaurant_tables (
    table_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_number INT UNSIGNED NOT NULL UNIQUE,
    capacity INT UNSIGNED NOT NULL,
    location VARCHAR(100),
    status ENUM(
        'available',
        'occupied',
        'reserved',
        'maintenance'
    ) NOT NULL DEFAULT 'available',

    CONSTRAINT chk_table_capacity
        CHECK (capacity > 0)
);

-- ============================================================
-- MENU CATEGORIES
-- ============================================================

CREATE TABLE menu_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active'
);

-- ============================================================
-- MENU ITEMS
-- ============================================================

CREATE TABLE menu_items (
    item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    preparation_time_minutes INT UNSIGNED,
    status ENUM('available', 'unavailable') NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_menu_items_category
        FOREIGN KEY (category_id)
        REFERENCES menu_categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_menu_item_price
        CHECK (price >= 0),

    CONSTRAINT chk_preparation_time
        CHECK (
            preparation_time_minutes IS NULL
            OR preparation_time_minutes > 0
        ),

    INDEX idx_menu_items_category (category_id),
    INDEX idx_menu_items_status (status)
);

-- ============================================================
-- ORDERS
-- ============================================================

CREATE TABLE orders (
    order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED,
    employee_id INT UNSIGNED,
    table_id INT UNSIGNED,
    order_type ENUM(
        'dine_in',
        'takeaway',
        'delivery'
    ) NOT NULL DEFAULT 'dine_in',
    order_status ENUM(
        'pending',
        'preparing',
        'ready',
        'served',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_orders_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_orders_table
        FOREIGN KEY (table_id)
        REFERENCES restaurant_tables(table_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_employee (employee_id),
    INDEX idx_orders_table (table_id),
    INDEX idx_orders_date (order_date),
    INDEX idx_orders_status (order_status)
);

-- ============================================================
-- ORDER ITEMS
-- ============================================================

CREATE TABLE order_items (
    order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    item_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    notes TEXT,

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_item
        FOREIGN KEY (item_id)
        REFERENCES menu_items(item_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_order_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_item_price
        CHECK (unit_price >= 0),

    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_item (item_id)
);

-- ============================================================
-- RESERVATIONS
-- ============================================================

CREATE TABLE reservations (
    reservation_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    table_id INT UNSIGNED NOT NULL,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    guest_count INT UNSIGNED NOT NULL,
    status ENUM(
        'pending',
        'confirmed',
        'completed',
        'cancelled',
        'no_show'
    ) NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservations_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_reservations_table
        FOREIGN KEY (table_id)
        REFERENCES restaurant_tables(table_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_reservation_guests
        CHECK (guest_count > 0),

    INDEX idx_reservations_customer (customer_id),
    INDEX idx_reservations_table (table_id),
    INDEX idx_reservations_datetime (
        reservation_date,
        reservation_time
    ),
    INDEX idx_reservations_status (status)
);

-- ============================================================
-- PAYMENTS
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method ENUM(
        'cash',
        'card',
        'bank_transfer',
        'online'
    ) NOT NULL,
    payment_status ENUM(
        'pending',
        'completed',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'completed',
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transaction_reference VARCHAR(100) UNIQUE,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    INDEX idx_payments_order (order_id),
    INDEX idx_payments_date (payment_date),
    INDEX idx_payments_status (payment_status)
);

-- ============================================================
-- SUPPLIERS
-- ============================================================

CREATE TABLE suppliers (
    supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_name VARCHAR(150),
    email VARCHAR(255),
    phone VARCHAR(30),
    address VARCHAR(255),
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- INGREDIENTS
-- ============================================================

CREATE TABLE ingredients (
    ingredient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT UNSIGNED,
    name VARCHAR(150) NOT NULL UNIQUE,
    unit VARCHAR(30) NOT NULL,
    stock_quantity DECIMAL(10, 2) NOT NULL DEFAULT 0,
    minimum_stock DECIMAL(10, 2) NOT NULL DEFAULT 0,
    unit_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status ENUM('available', 'unavailable') NOT NULL DEFAULT 'available',

    CONSTRAINT fk_ingredients_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_ingredient_stock
        CHECK (stock_quantity >= 0),

    CONSTRAINT chk_ingredient_minimum_stock
        CHECK (minimum_stock >= 0),

    CONSTRAINT chk_ingredient_cost
        CHECK (unit_cost >= 0),

    INDEX idx_ingredients_supplier (supplier_id),
    INDEX idx_ingredients_stock (stock_quantity)
);

-- ============================================================
-- MENU ITEM INGREDIENTS
-- ============================================================

CREATE TABLE menu_item_ingredients (
    item_id INT UNSIGNED NOT NULL,
    ingredient_id INT UNSIGNED NOT NULL,
    quantity_required DECIMAL(10, 3) NOT NULL,

    PRIMARY KEY (item_id, ingredient_id),

    CONSTRAINT fk_menu_item_ingredients_item
        FOREIGN KEY (item_id)
        REFERENCES menu_items(item_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_menu_item_ingredients_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES ingredients(ingredient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_quantity_required
        CHECK (quantity_required > 0)
);

-- ============================================================
-- SAMPLE CUSTOMERS
-- ============================================================

INSERT INTO customers
    (first_name, last_name, email, phone)
VALUES
    ('James', 'Carter', 'james.carter@example.com', '+15551000001'),
    ('Emma', 'Wilson', 'emma.wilson@example.com', '+15551000002'),
    ('Michael', 'Brown', 'michael.brown@example.com', '+15551000003'),
    ('Sophia', 'Taylor', 'sophia.taylor@example.com', '+15551000004'),
    ('Daniel', 'Miller', 'daniel.miller@example.com', '+15551000005'),
    ('Olivia', 'Davis', 'olivia.davis@example.com', '+15551000006');

-- ============================================================
-- SAMPLE EMPLOYEES
-- ============================================================

INSERT INTO employees
    (first_name, last_name, email, phone, role, hire_date, salary, status)
VALUES
    ('Robert', 'Johnson', 'robert.johnson@example.com', '+15552000001', 'manager', '2023-03-15', 4200.00, 'active'),
    ('William', 'Anderson', 'william.anderson@example.com', '+15552000002', 'chef', '2024-01-10', 3500.00, 'active'),
    ('David', 'Thomas', 'david.thomas@example.com', '+15552000003', 'chef', '2024-07-01', 3200.00, 'active'),
    ('Sarah', 'Martinez', 'sarah.martinez@example.com', '+15552000004', 'waiter', '2025-02-12', 2200.00, 'active'),
    ('Laura', 'Wilson', 'laura.wilson@example.com', '+15552000005', 'waiter', '2025-05-20', 2200.00, 'active'),
    ('Daniel', 'Moore', 'daniel.moore@example.com', '+15552000006', 'cashier', '2025-08-05', 2400.00, 'active'),
    ('Chris', 'Taylor', 'chris.taylor@example.com', '+15552000007', 'host', '2026-01-15', 2100.00, 'active');

-- ============================================================
-- SAMPLE TABLES
-- ============================================================

INSERT INTO restaurant_tables
    (table_number, capacity, location, status)
VALUES
    (1, 2, 'Main Hall', 'available'),
    (2, 2, 'Main Hall', 'available'),
    (3, 4, 'Main Hall', 'occupied'),
    (4, 4, 'Main Hall', 'reserved'),
    (5, 6, 'Window Area', 'available'),
    (6, 6, 'Window Area', 'available'),
    (7, 8, 'Private Area', 'available'),
    (8, 4, 'Terrace', 'available'),
    (9, 4, 'Terrace', 'maintenance'),
    (10, 10, 'Private Area', 'available');

-- ============================================================
-- SAMPLE MENU CATEGORIES
-- ============================================================

INSERT INTO menu_categories
    (name, description, status)
VALUES
    ('Appetizers', 'Starters and small dishes.', 'active'),
    ('Main Courses', 'Main dishes and signature meals.', 'active'),
    ('Pizza', 'Freshly prepared pizzas.', 'active'),
    ('Burgers', 'Burgers and sandwiches.', 'active'),
    ('Salads', 'Fresh salads and vegetables.', 'active'),
    ('Desserts', 'Sweet dishes and desserts.', 'active'),
    ('Beverages', 'Hot and cold beverages.', 'active');

-- ============================================================
-- SAMPLE MENU ITEMS
-- ============================================================

INSERT INTO menu_items
    (category_id, name, description, price, preparation_time_minutes, status)
VALUES
    (1, 'Garlic Bread', 'Fresh bread with garlic and herbs.', 5.50, 10, 'available'),
    (1, 'Chicken Wings', 'Crispy chicken wings with house sauce.', 9.90, 18, 'available'),
    (2, 'Grilled Chicken', 'Grilled chicken breast with vegetables.', 16.50, 25, 'available'),
    (2, 'Beef Steak', 'Grilled beef steak with roasted vegetables.', 24.90, 30, 'available'),
    (3, 'Margherita Pizza', 'Classic pizza with tomato, mozzarella, and basil.', 12.50, 20, 'available'),
    (3, 'Pepperoni Pizza', 'Pizza with mozzarella and pepperoni.', 14.50, 22, 'available'),
    (4, 'Classic Burger', 'Beef burger with lettuce, tomato, and cheese.', 11.90, 18, 'available'),
    (4, 'Chicken Burger', 'Crispy chicken burger with house sauce.', 10.90, 18, 'available'),
    (5, 'Caesar Salad', 'Romaine lettuce, chicken, parmesan, and dressing.', 9.50, 12, 'available'),
    (6, 'Chocolate Cake', 'Chocolate cake served with cream.', 6.50, 8, 'available'),
    (6, 'Cheesecake', 'Classic cheesecake with berry sauce.', 6.90, 8, 'available'),
    (7, 'Fresh Lemonade', 'Freshly prepared lemonade.', 4.50, 5, 'available'),
    (7, 'Espresso', 'Freshly brewed espresso.', 3.00, 5, 'available'),
    (7, 'Mineral Water', 'Bottled mineral water.', 2.00, 2, 'available');

-- ============================================================
-- SAMPLE SUPPLIERS
-- ============================================================

INSERT INTO suppliers
    (name, contact_name, email, phone, address, status)
VALUES
    ('Fresh Foods Supply', 'John Smith', 'john@freshfoods.example', '+15553000001', '12 Market Street', 'active'),
    ('Premium Meat Co.', 'Mark Brown', 'mark@premiummeat.example', '+15553000002', '45 Industrial Road', 'active'),
    ('Daily Dairy Supply', 'Anna Wilson', 'anna@dailydairy.example', '+15553000003', '78 Farm Avenue', 'active'),
    ('Beverage Distribution', 'Peter Davis', 'peter@beverages.example', '+15553000004', '21 Warehouse Road', 'active');

-- ============================================================
-- SAMPLE INGREDIENTS
-- ============================================================

INSERT INTO ingredients
    (supplier_id, name, unit, stock_quantity, minimum_stock, unit_cost, status)
VALUES
    (1, 'Chicken Breast', 'kg', 35.00, 10.00, 7.50, 'available'),
    (2, 'Beef', 'kg', 25.00, 8.00, 12.00, 'available'),
    (3, 'Mozzarella', 'kg', 20.00, 5.00, 8.00, 'available'),
    (1, 'Tomatoes', 'kg', 30.00, 8.00, 3.00, 'available'),
    (1, 'Lettuce', 'kg', 15.00, 4.00, 2.50, 'available'),
    (1, 'Bread', 'kg', 20.00, 5.00, 2.00, 'available'),
    (1, 'Potatoes', 'kg', 40.00, 10.00, 2.20, 'available'),
    (1, 'Onions', 'kg', 25.00, 6.00, 1.80, 'available'),
    (1, 'Basil', 'kg', 5.00, 1.00, 9.00, 'available'),
    (3, 'Cream', 'liter', 15.00, 4.00, 4.50, 'available'),
    (3, 'Butter', 'kg', 12.00, 3.00, 6.00, 'available'),
    (3, 'Parmesan', 'kg', 8.00, 2.00, 14.00, 'available'),
    (1, 'Chocolate', 'kg', 10.00, 2.00, 10.00, 'available'),
    (1, 'Flour', 'kg', 50.00, 15.00, 1.50, 'available'),
    (1, 'Pepperoni', 'kg', 12.00, 3.00, 9.50, 'available'),
    (4, 'Lemon', 'kg', 20.00, 5.00, 2.80, 'available'),
    (4, 'Coffee Beans', 'kg', 8.00, 2.00, 15.00, 'available'),
    (4, 'Mineral Water', 'liter', 100.00, 25.00, 0.50, 'available');

-- ============================================================
-- MENU ITEM INGREDIENTS
-- ============================================================

INSERT INTO menu_item_ingredients
    (item_id, ingredient_id, quantity_required)
VALUES
    (1, 6, 0.150),
    (1, 11, 0.020),

    (2, 1, 0.300),

    (3, 1, 0.250),
    (3, 5, 0.100),
    (3, 4, 0.100),
    (3, 7, 0.150),

    (4, 2, 0.300),
    (4, 7, 0.200),
    (4, 8, 0.050),

    (5, 14, 0.180),
    (5, 3, 0.100),
    (5, 4, 0.100),
    (5, 9, 0.010),

    (6, 14, 0.180),
    (6, 3, 0.100),
    (6, 4, 0.100),
    (6, 15, 0.070),

    (7, 2, 0.150),
    (7, 6, 0.100),
    (7, 5, 0.030),
    (7, 4, 0.050),

    (8, 1, 0.180),
    (8, 6, 0.100),
    (8, 5, 0.030),

    (9, 1, 0.120),
    (9, 5, 0.080),
    (9, 12, 0.020),

    (10, 13, 0.100),
    (10, 10, 0.030),

    (11, 10, 0.040),

    (12, 16, 0.100),

    (13, 17, 0.018),

    (14, 18, 0.500);

-- ============================================================
-- SAMPLE ORDERS
-- ============================================================

INSERT INTO orders
    (customer_id, employee_id, table_id, order_type, order_status, order_date, notes)
VALUES
    (1, 4, 3, 'dine_in', 'completed', '2026-05-01 12:15:00', NULL),
    (2, 5, 4, 'dine_in', 'completed', '2026-05-01 13:20:00', 'Birthday reservation.'),
    (3, 4, 5, 'dine_in', 'completed', '2026-05-02 18:10:00', NULL),
    (4, 5, NULL, 'takeaway', 'completed', '2026-05-03 19:00:00', 'Takeaway order.'),
    (5, 4, 7, 'dine_in', 'served', '2026-05-04 20:15:00', NULL),
    (6, 5, NULL, 'delivery', 'preparing', '2026-05-05 19:30:00', 'Delivery order.');

-- ============================================================
-- SAMPLE ORDER ITEMS
-- ============================================================

INSERT INTO order_items
    (order_id, item_id, quantity, unit_price, notes)
VALUES
    (1, 1, 1, 5.50, NULL),
    (1, 3, 2, 16.50, NULL),
    (1, 12, 2, 4.50, NULL),

    (2, 5, 1, 12.50, NULL),
    (2, 7, 2, 11.90, 'No onions.'),
    (2, 10, 1, 6.50, NULL),

    (3, 2, 1, 9.90, NULL),
    (3, 4, 1, 24.90, NULL),
    (3, 9, 1, 9.50, NULL),

    (4, 6, 1, 14.50, NULL),
    (4, 8, 1, 10.90, NULL),

    (5, 4, 2, 24.90, NULL),
    (5, 11, 2, 6.90, NULL),

    (6, 3, 1, 16.50, NULL),
    (6, 5, 1, 12.50, NULL),
    (6, 12, 2, 4.50, NULL);

-- ============================================================
-- SAMPLE RESERVATIONS
-- ============================================================

INSERT INTO reservations
    (customer_id, table_id, reservation_date, reservation_time, guest_count, status, notes)
VALUES
    (1, 3, '2026-05-10', '19:00:00', 4, 'confirmed', NULL),
    (2, 5, '2026-05-10', '20:00:00', 5, 'confirmed', 'Window table requested.'),
    (3, 7, '2026-05-11', '18:30:00', 8, 'pending', 'Private area requested.'),
    (4, 8, '2026-05-12', '19:30:00', 3, 'confirmed', 'Terrace requested.'),
    (5, 10, '2026-05-13', '20:00:00', 9, 'pending', 'Large group.');

-- ============================================================
-- SAMPLE PAYMENTS
-- ============================================================

INSERT INTO payments
    (order_id, amount, payment_method, payment_status, payment_date, transaction_reference)
VALUES
    (1, 50.00, 'card', 'completed', '2026-05-01 13:00:00', 'TXN-100001'),
    (2, 42.80, 'cash', 'completed', '2026-05-01 14:10:00', 'TXN-100002'),
    (3, 43.40, 'card', 'completed', '2026-05-02 19:15:00', 'TXN-100003'),
    (4, 25.40, 'online', 'completed', '2026-05-03 19:05:00', 'TXN-100004'),
    (5, 63.60, 'card', 'completed', '2026-05-04 21:30:00', 'TXN-100005'),
    (6, 38.00, 'online', 'pending', '2026-05-05 19:35:00', 'TXN-100006');

-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW menu_catalog AS
SELECT
    mi.item_id,
    mi.name AS item_name,
    mc.name AS category,
    mi.description,
    mi.price,
    mi.preparation_time_minutes,
    mi.status
FROM menu_items mi
JOIN menu_categories mc
    ON mc.category_id = mi.category_id;

CREATE VIEW order_details AS
SELECT
    o.order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_type,
    o.order_status,
    mi.name AS item_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total
FROM orders o
LEFT JOIN customers c
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON oi.order_id = o.order_id
JOIN menu_items mi
    ON mi.item_id = oi.item_id;

CREATE VIEW order_totals AS
SELECT
    o.order_id,
    o.order_date,
    o.order_status,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS order_total
FROM orders o
LEFT JOIN order_items oi
    ON oi.order_id = o.order_id
GROUP BY
    o.order_id,
    o.order_date,
    o.order_status;

CREATE VIEW low_stock_ingredients AS
SELECT
    ingredient_id,
    name,
    unit,
    stock_quantity,
    minimum_stock,
    unit_cost
FROM ingredients
WHERE stock_quantity <= minimum_stock;

CREATE VIEW reservation_schedule AS
SELECT
    r.reservation_id,
    r.reservation_date,
    r.reservation_time,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    rt.table_number,
    rt.capacity,
    r.guest_count,
    r.status
FROM reservations r
JOIN customers c
    ON c.customer_id = r.customer_id
JOIN restaurant_tables rt
    ON rt.table_id = r.table_id;

-- ============================================================
-- EXAMPLE QUERIES
-- ============================================================

-- Available menu items
SELECT *
FROM menu_catalog
WHERE status = 'available';

-- Orders with their totals
SELECT *
FROM order_totals
ORDER BY order_date DESC;

-- Most popular menu items
SELECT
    mi.item_id,
    mi.name,
    SUM(oi.quantity) AS total_quantity_sold
FROM menu_items mi
JOIN order_items oi
    ON oi.item_id = mi.item_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status <> 'cancelled'
GROUP BY
    mi.item_id,
    mi.name
ORDER BY total_quantity_sold DESC;

-- Revenue by menu category
SELECT
    mc.name AS category,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM menu_categories mc
JOIN menu_items mi
    ON mi.category_id = mc.category_id
JOIN order_items oi
    ON oi.item_id = mi.item_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status <> 'cancelled'
GROUP BY mc.category_id, mc.name
ORDER BY revenue DESC;

-- Total restaurant revenue
SELECT
    SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'completed';

-- Revenue by payment method
SELECT
    payment_method,
    SUM(amount) AS total_revenue
FROM payments
WHERE payment_status = 'completed'
GROUP BY payment_method
ORDER BY total_revenue DESC;

-- Current reservations
SELECT *
FROM reservation_schedule
WHERE status IN ('pending', 'confirmed')
ORDER BY reservation_date, reservation_time;

-- Tables that are currently available
SELECT *
FROM restaurant_tables
WHERE status = 'available'
ORDER BY table_number;

-- Ingredients that need restocking
SELECT *
FROM low_stock_ingredients
ORDER BY stock_quantity ASC;

-- Employees grouped by role
SELECT
    role,
    COUNT(*) AS employee_count
FROM employees
WHERE status = 'active'
GROUP BY role
ORDER BY employee_count DESC;

-- Customers and their total spending
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COALESCE(SUM(p.amount), 0) AS total_spending
FROM customers c
LEFT JOIN orders o
    ON o.customer_id = c.customer_id
LEFT JOIN payments p
    ON p.order_id = o.order_id
   AND p.payment_status = 'completed'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spending DESC;

-- Orders handled by each waiter
SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    COUNT(o.order_id) AS handled_orders
FROM employees e
LEFT JOIN orders o
    ON o.employee_id = e.employee_id
WHERE e.role = 'waiter'
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
ORDER BY handled_orders DESC;