-- ============================================================

-- SQLFoundry - E-Commerce Management System

-- Database: MySQL 8.0+

-- File: ecommerce.sql

-- ============================================================

DROP DATABASE IF EXISTS ecommerce_db;

CREATE DATABASE ecommerce_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE ecommerce_db;


-- ============================================================
-- Table: categories
-- ============================================================

CREATE TABLE categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT UNSIGNED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_categories_parent (parent_category_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: products
-- ============================================================

CREATE TABLE products (
    product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    name VARCHAR(200) NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    price DECIMAL(12,2) NOT NULL,
    cost_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive',
        'out_of_stock'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_product_price
        CHECK (price >= 0),

    CONSTRAINT chk_product_cost
        CHECK (cost_price >= 0),

    INDEX idx_products_category (category_id),
    INDEX idx_products_status (status),
    INDEX idx_products_name (name)
) ENGINE=InnoDB;


-- ============================================================
-- Table: customers
-- ============================================================

CREATE TABLE customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'blocked'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_customers_name (last_name, first_name),
    INDEX idx_customers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: addresses
-- ============================================================

CREATE TABLE addresses (
    address_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    address_type ENUM(
        'billing',
        'shipping'
    ) NOT NULL,
    recipient_name VARCHAR(200) NOT NULL,
    phone VARCHAR(30),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(30),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    INDEX idx_addresses_customer (customer_id),
    INDEX idx_addresses_type (address_type)
) ENGINE=InnoDB;


-- ============================================================
-- Table: inventory
-- ============================================================

CREATE TABLE inventory (
    inventory_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id INT UNSIGNED NOT NULL UNIQUE,
    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,
    reorder_level INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_inventory_quantity
        CHECK (quantity >= 0),

    CONSTRAINT chk_inventory_reserved
        CHECK (reserved_quantity >= 0),

    CONSTRAINT chk_inventory_reorder
        CHECK (reorder_level >= 0),

    CONSTRAINT chk_inventory_reserved_limit
        CHECK (reserved_quantity <= quantity),

    INDEX idx_inventory_quantity (quantity)
) ENGINE=InnoDB;


-- ============================================================
-- Table: coupons
-- ============================================================

CREATE TABLE coupons (
    coupon_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type ENUM(
        'percentage',
        'fixed'
    ) NOT NULL,
    discount_value DECIMAL(12,2) NOT NULL,
    minimum_order_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    usage_limit INT UNSIGNED,
    used_count INT UNSIGNED NOT NULL DEFAULT 0,
    starts_at DATETIME NOT NULL,
    expires_at DATETIME NOT NULL,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_coupon_discount
        CHECK (discount_value >= 0),

    CONSTRAINT chk_coupon_minimum
        CHECK (minimum_order_amount >= 0),

    CONSTRAINT chk_coupon_dates
        CHECK (expires_at > starts_at),

    CONSTRAINT chk_coupon_percentage
        CHECK (
            discount_type = 'fixed'
            OR discount_value <= 100
        ),

    CONSTRAINT chk_coupon_usage
        CHECK (
            usage_limit IS NULL
            OR used_count <= usage_limit
        ),

    INDEX idx_coupons_status (status),
    INDEX idx_coupons_dates (starts_at, expires_at)
) ENGINE=InnoDB;


-- ============================================================
-- Table: orders
-- ============================================================

CREATE TABLE orders (
    order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    shipping_address_id INT UNSIGNED,
    billing_address_id INT UNSIGNED,
    coupon_id INT UNSIGNED,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    shipping_cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM(
        'pending',
        'processing',
        'shipped',
        'delivered',
        'cancelled',
        'refunded'
    ) NOT NULL DEFAULT 'pending',
    ordered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_orders_shipping_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_orders_billing_address
        FOREIGN KEY (billing_address_id)
        REFERENCES addresses(address_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_orders_coupon
        FOREIGN KEY (coupon_id)
        REFERENCES coupons(coupon_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_order_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_order_shipping
        CHECK (shipping_cost >= 0),

    CONSTRAINT chk_order_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_order_tax
        CHECK (tax_amount >= 0),

    CONSTRAINT chk_order_total
        CHECK (total_amount >= 0),

    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_status (status),
    INDEX idx_orders_date (ordered_at)
) ENGINE=InnoDB;


-- ============================================================
-- Table: order_items
-- ============================================================

CREATE TABLE order_items (
    order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_order_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_order_item_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_order_item_discount
        CHECK (discount_amount >= 0),

    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_product (product_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNSIGNED NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM(
        'cash_on_delivery',
        'credit_card',
        'debit_card',
        'bank_transfer',
        'online_wallet'
    ) NOT NULL,
    transaction_reference VARCHAR(150) UNIQUE,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'pending',
    paid_at TIMESTAMP NULL,

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_order (order_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_paid_at (paid_at)
) ENGINE=InnoDB;


-- ============================================================
-- Table: reviews
-- ============================================================

CREATE TABLE reviews (
    review_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    order_id INT UNSIGNED,
    rating TINYINT UNSIGNED NOT NULL,
    title VARCHAR(200),
    review_text TEXT,
    status ENUM(
        'pending',
        'approved',
        'rejected'
    ) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_review_rating
        CHECK (rating BETWEEN 1 AND 5),

    UNIQUE KEY uq_customer_product_review (customer_id, product_id),

    INDEX idx_reviews_product (product_id),
    INDEX idx_reviews_rating (rating),
    INDEX idx_reviews_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO categories
    (name, description)
VALUES
    ('Electronics', 'Electronic devices and accessories.'),
    ('Computers', 'Computers and computer accessories.'),
    ('Smartphones', 'Mobile phones and smartphone accessories.'),
    ('Home & Kitchen', 'Products for home and kitchen.');


INSERT INTO categories
    (name, description, parent_category_id)
VALUES
    ('Laptops', 'Portable computers.', 2),
    ('Accessories', 'Computer and mobile accessories.', 2),
    ('Android Phones', 'Android smartphones.', 3),
    ('Kitchen Appliances', 'Appliances for kitchen use.', 4);


INSERT INTO products
    (category_id, name, sku, description, price, cost_price, status)
VALUES
    (5, 'Developer Laptop Pro', 'LAP-001',
     'High-performance laptop for development and professional workloads.',
     1499.00, 1100.00, 'active'),

    (5, 'Ultrabook Air', 'LAP-002',
     'Lightweight laptop for everyday productivity.',
     999.00, 720.00, 'active'),

    (6, 'Mechanical Keyboard', 'ACC-001',
     'Mechanical keyboard with programmable keys.',
     89.00, 52.00, 'active'),

    (6, 'Wireless Mouse', 'ACC-002',
     'Wireless ergonomic mouse.',
     39.00, 21.00, 'active'),

    (7, 'Android Pro X', 'PHN-001',
     'Modern Android smartphone.',
     799.00, 590.00, 'active'),

    (8, 'Smart Blender', 'KIT-001',
     'Multi-speed smart kitchen blender.',
     129.00, 80.00, 'active');


INSERT INTO customers
    (first_name, last_name, email, phone, password_hash, status)
VALUES
    ('John', 'Smith', 'john.smith@example.com', '+1-555-3001',
     '$2y$10$examplehash001', 'active'),

    ('Emma', 'Wilson', 'emma.wilson@example.com', '+1-555-3002',
     '$2y$10$examplehash002', 'active'),

    ('Daniel', 'Miller', 'daniel.miller@example.com', '+1-555-3003',
     '$2y$10$examplehash003', 'active'),

    ('Sofia', 'Garcia', 'sofia.garcia@example.com', '+1-555-3004',
     '$2y$10$examplehash004', 'active');


INSERT INTO addresses
    (customer_id, address_type, recipient_name, phone,
     address_line1, city, state, postal_code, country, is_default)
VALUES
    (1, 'shipping', 'John Smith', '+1-555-3001',
     '100 Main Street', 'New York', 'NY', '10001', 'USA', TRUE),

    (1, 'billing', 'John Smith', '+1-555-3001',
     '100 Main Street', 'New York', 'NY', '10001', 'USA', TRUE),

    (2, 'shipping', 'Emma Wilson', '+1-555-3002',
     '25 Oxford Road', 'London', NULL, 'W1A 1AA', 'UK', TRUE),

    (2, 'billing', 'Emma Wilson', '+1-555-3002',
     '25 Oxford Road', 'London', NULL, 'W1A 1AA', 'UK', TRUE),

    (3, 'shipping', 'Daniel Miller', '+1-555-3003',
     '50 King Street', 'Toronto', 'ON', 'M5V 2T6', 'Canada', TRUE),

    (4, 'shipping', 'Sofia Garcia', '+1-555-3004',
     '10 Gran Via', 'Madrid', NULL, '28013', 'Spain', TRUE);


INSERT INTO inventory
    (product_id, quantity, reserved_quantity, reorder_level)
VALUES
    (1, 15, 2, 5),
    (2, 22, 3, 5),
    (3, 50, 5, 10),
    (4, 80, 10, 15),
    (5, 12, 2, 4),
    (6, 30, 1, 5);


INSERT INTO coupons
    (code, description, discount_type, discount_value,
     minimum_order_amount, usage_limit, starts_at, expires_at, status)
VALUES
    ('WELCOME10', '10% discount for new customers.',
     'percentage', 10.00, 50.00, 1000,
     '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'active'),

    ('SAVE50', 'Fixed $50 discount.',
     'fixed', 50.00, 500.00, 500,
     '2026-01-01 00:00:00', '2026-12-31 23:59:59', 'active');


INSERT INTO orders
    (customer_id, shipping_address_id, billing_address_id, coupon_id,
     order_number, subtotal, shipping_cost, discount_amount,
     tax_amount, total_amount, status)
VALUES
    (1, 1, 2, 1,
     'ORD-2026-0001', 1588.00, 20.00, 10.00, 159.80, 1757.80,
     'delivered'),

    (2, 3, 4, NULL,
     'ORD-2026-0002', 838.00, 15.00, 0.00, 85.30, 938.30,
     'shipped'),

    (3, 5, NULL, 2,
     'ORD-2026-0003', 999.00, 0.00, 50.00, 94.90, 1043.90,
     'processing');


INSERT INTO order_items
    (order_id, product_id, quantity, unit_price, discount_amount)
VALUES
    (1, 1, 1, 1499.00, 0.00),
    (1, 3, 1, 89.00, 0.00),

    (2, 5, 1, 799.00, 0.00),
    (2, 4, 1, 39.00, 0.00),

    (3, 2, 1, 999.00, 0.00);


INSERT INTO payments
    (order_id, amount, payment_method, transaction_reference,
     status, paid_at)
VALUES
    (1, 1757.80, 'credit_card', 'PAY-100001',
     'completed', '2026-08-20 14:30:00'),

    (2, 938.30, 'bank_transfer', 'PAY-100002',
     'completed', '2026-08-25 10:15:00'),

    (3, 1043.90, 'online_wallet', 'PAY-100003',
     'completed', '2026-09-01 18:45:00');


INSERT INTO reviews
    (customer_id, product_id, order_id, rating, title,
     review_text, status)
VALUES
    (1, 1, 1, 5, 'Excellent laptop',
     'Fast and reliable for development work.', 'approved'),

    (2, 5, 2, 4, 'Good phone',
     'Great performance and battery life.', 'approved'),

    (3, 2, 3, 5, 'Great value',
     'Very good laptop for everyday work.', 'approved');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW product_catalog AS
SELECT
    p.product_id,
    p.name AS product_name,
    p.sku,
    c.name AS category,
    p.price,
    p.status,
    i.quantity AS stock_quantity,
    i.reserved_quantity,
    i.quantity - i.reserved_quantity AS available_quantity
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
JOIN inventory i
    ON p.product_id = i.product_id;


CREATE VIEW order_details AS
SELECT
    o.order_id,
    o.order_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.name AS product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_amount,
    (oi.quantity * oi.unit_price) - oi.discount_amount AS line_total,
    o.status,
    o.ordered_at
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id;


CREATE VIEW customer_order_summary AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name;


CREATE VIEW low_stock_products AS
SELECT
    p.product_id,
    p.name AS product_name,
    p.sku,
    i.quantity,
    i.reserved_quantity,
    i.reorder_level,
    i.quantity - i.reserved_quantity AS available_quantity
FROM products p
JOIN inventory i
    ON p.product_id = i.product_id
WHERE i.quantity - i.reserved_quantity <= i.reorder_level;


CREATE VIEW product_review_summary AS
SELECT
    p.product_id,
    p.name AS product_name,
    COUNT(r.review_id) AS review_count,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM products p
LEFT JOIN reviews r
    ON p.product_id = r.product_id
    AND r.status = 'approved'
GROUP BY
    p.product_id,
    p.name;


-- ============================================================
-- Example Queries
-- ============================================================

-- Browse products with stock information
SELECT *
FROM product_catalog
WHERE status = 'active'
ORDER BY category, product_name;


-- Products with low stock
SELECT *
FROM low_stock_products
ORDER BY available_quantity;


-- Customer order summary
SELECT *
FROM customer_order_summary
ORDER BY total_spent DESC;


-- Detailed order information
SELECT *
FROM order_details
WHERE order_number = 'ORD-2026-0001';


-- Top-selling products
SELECT
    p.product_id,
    p.name,
    SUM(oi.quantity) AS units_sold,
    SUM(
        (oi.quantity * oi.unit_price) - oi.discount_amount
    ) AS sales
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status NOT IN ('cancelled', 'refunded')
GROUP BY
    p.product_id,
    p.name
ORDER BY units_sold DESC, sales DESC;


-- Revenue by month
SELECT
    DATE_FORMAT(ordered_at, '%Y-%m') AS month,
    SUM(total_amount) AS revenue
FROM orders
WHERE status NOT IN ('cancelled', 'refunded')
GROUP BY DATE_FORMAT(ordered_at, '%Y-%m')
ORDER BY month;


-- Customer spending
SELECT *
FROM customer_order_summary
WHERE order_count > 0
ORDER BY total_spent DESC;


-- Product ratings
SELECT *
FROM product_review_summary
WHERE review_count > 0
ORDER BY average_rating DESC;


-- Active coupons
SELECT
    code,
    discount_type,
    discount_value,
    minimum_order_amount,
    expires_at
FROM coupons
WHERE status = 'active'
  AND NOW() BETWEEN starts_at AND expires_at;


-- Payment revenue
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payments
WHERE status = 'completed'
GROUP BY payment_method
ORDER BY total_amount DESC;