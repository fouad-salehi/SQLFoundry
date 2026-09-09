-- ============================================================

-- SQLFoundry - Inventory Management System

-- Database: MySQL 8.0+

-- File: inventory.sql

-- ============================================================

DROP DATABASE IF EXISTS inventory_db;

CREATE DATABASE inventory_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE inventory_db;


-- ============================================================
-- Table: categories
-- ============================================================

CREATE TABLE categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- ============================================================
-- Table: suppliers
-- ============================================================

CREATE TABLE suppliers (
    supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    supplier_code VARCHAR(50) NOT NULL UNIQUE,
    company_name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(150),
    email VARCHAR(255),
    phone VARCHAR(30),
    address VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_suppliers_company (company_name),
    INDEX idx_suppliers_city (city),
    INDEX idx_suppliers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: warehouses
-- ============================================================

CREATE TABLE warehouses (
    warehouse_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    warehouse_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    manager_name VARCHAR(150),
    phone VARCHAR(30),
    capacity INT UNSIGNED NOT NULL,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_warehouse_capacity
        CHECK (capacity > 0),

    INDEX idx_warehouses_city (city),
    INDEX idx_warehouses_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: products
-- ============================================================

CREATE TABLE products (
    product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    barcode VARCHAR(100) UNIQUE,
    name VARCHAR(150) NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    supplier_id INT UNSIGNED,
    description TEXT,
    unit VARCHAR(30) NOT NULL DEFAULT 'piece',
    purchase_price DECIMAL(12,2) NOT NULL,
    selling_price DECIMAL(12,2) NOT NULL,
    reorder_level INT UNSIGNED NOT NULL DEFAULT 0,
    reorder_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive',
        'discontinued'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_product_purchase_price
        CHECK (purchase_price >= 0),

    CONSTRAINT chk_product_selling_price
        CHECK (selling_price >= 0),

    CONSTRAINT chk_product_reorder_quantity
        CHECK (reorder_quantity >= reorder_level),

    INDEX idx_products_category (category_id),
    INDEX idx_products_supplier (supplier_id),
    INDEX idx_products_name (name),
    INDEX idx_products_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: inventory
-- ============================================================

CREATE TABLE inventory (
    inventory_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,
    minimum_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    maximum_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventory_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_inventory_quantity
        CHECK (quantity >= 0),

    CONSTRAINT chk_inventory_reserved
        CHECK (
            reserved_quantity >= 0
            AND reserved_quantity <= quantity
        ),

    CONSTRAINT chk_inventory_maximum
        CHECK (
            maximum_quantity = 0
            OR maximum_quantity >= minimum_quantity
        ),

    UNIQUE (
        warehouse_id,
        product_id
    ),

    INDEX idx_inventory_product (product_id),
    INDEX idx_inventory_warehouse (warehouse_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: purchase_orders
-- ============================================================

CREATE TABLE purchase_orders (
    purchase_order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_order_number VARCHAR(50) NOT NULL UNIQUE,
    supplier_id INT UNSIGNED NOT NULL,
    warehouse_id INT UNSIGNED NOT NULL,
    order_date DATE NOT NULL,
    expected_date DATE,
    received_date DATE,
    status ENUM(
        'draft',
        'ordered',
        'partial',
        'received',
        'cancelled'
    ) NOT NULL DEFAULT 'draft',
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_purchase_orders_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_purchase_orders_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_purchase_expected_date
        CHECK (
            expected_date IS NULL
            OR expected_date >= order_date
        ),

    CONSTRAINT chk_purchase_received_date
        CHECK (
            received_date IS NULL
            OR received_date >= order_date
        ),

    INDEX idx_purchase_orders_supplier (supplier_id),
    INDEX idx_purchase_orders_warehouse (warehouse_id),
    INDEX idx_purchase_orders_date (order_date),
    INDEX idx_purchase_orders_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: purchase_order_items
-- ============================================================

CREATE TABLE purchase_order_items (
    purchase_order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    purchase_order_id BIGINT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    ordered_quantity INT UNSIGNED NOT NULL,
    received_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    unit_cost DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_purchase_items_order
        FOREIGN KEY (purchase_order_id)
        REFERENCES purchase_orders(purchase_order_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_purchase_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_purchase_item_quantity
        CHECK (
            ordered_quantity > 0
            AND received_quantity <= ordered_quantity
        ),

    CONSTRAINT chk_purchase_item_cost
        CHECK (unit_cost >= 0),

    UNIQUE (
        purchase_order_id,
        product_id
    ),

    INDEX idx_purchase_items_product (product_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: stock_transfers
-- ============================================================

CREATE TABLE stock_transfers (
    transfer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transfer_number VARCHAR(50) NOT NULL UNIQUE,
    from_warehouse_id INT UNSIGNED NOT NULL,
    to_warehouse_id INT UNSIGNED NOT NULL,
    transfer_date DATETIME NOT NULL,
    received_date DATETIME,
    status ENUM(
        'pending',
        'in_transit',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',
    notes VARCHAR(255),

    CONSTRAINT fk_transfers_from_warehouse
        FOREIGN KEY (from_warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transfers_to_warehouse
        FOREIGN KEY (to_warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_transfer_warehouses
        CHECK (from_warehouse_id <> to_warehouse_id),

    CONSTRAINT chk_transfer_received_date
        CHECK (
            received_date IS NULL
            OR received_date >= transfer_date
        ),

    INDEX idx_transfers_from (from_warehouse_id),
    INDEX idx_transfers_to (to_warehouse_id),
    INDEX idx_transfers_date (transfer_date),
    INDEX idx_transfers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: stock_transfer_items
-- ============================================================

CREATE TABLE stock_transfer_items (
    transfer_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transfer_id BIGINT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    quantity INT UNSIGNED NOT NULL,

    CONSTRAINT fk_transfer_items_transfer
        FOREIGN KEY (transfer_id)
        REFERENCES stock_transfers(transfer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_transfer_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_transfer_item_quantity
        CHECK (quantity > 0),

    UNIQUE (
        transfer_id,
        product_id
    ),

    INDEX idx_transfer_items_product (product_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: stock_transactions
-- ============================================================

CREATE TABLE stock_transactions (
    transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    warehouse_id INT UNSIGNED NOT NULL,
    product_id INT UNSIGNED NOT NULL,
    transaction_type ENUM(
        'purchase',
        'sale',
        'transfer_in',
        'transfer_out',
        'adjustment_in',
        'adjustment_out',
        'return_in',
        'return_out'
    ) NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    reference_number VARCHAR(100),
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255),

    CONSTRAINT fk_stock_transactions_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_stock_transactions_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_stock_transaction_quantity
        CHECK (quantity > 0),

    INDEX idx_stock_transactions_warehouse (warehouse_id),
    INDEX idx_stock_transactions_product (product_id),
    INDEX idx_stock_transactions_date (transaction_date),
    INDEX idx_stock_transactions_type (transaction_type)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO categories
    (name, description, status)
VALUES
    ('Electronics',
     'Electronic devices and accessories.',
     'active'),

    ('Computer Accessories',
     'Accessories for computers and workstations.',
     'active'),

    ('Office Supplies',
     'General office and stationery products.',
     'active'),

    ('Networking',
     'Networking equipment and infrastructure.',
     'active');


INSERT INTO suppliers
    (supplier_code, company_name, contact_name,
     email, phone, address, city, country, status)
VALUES
    ('SUP-001', 'TechSource Ltd.',
     'Michael Brown',
     'contact@techsource.example',
     '+1-555-3001',
     '25 Industrial Avenue',
     'New York', 'USA', 'active'),

    ('SUP-002', 'OfficePro Supplies',
     'Sarah Johnson',
     'sales@officepro.example',
     '+1-555-3002',
     '88 Market Street',
     'Chicago', 'USA', 'active'),

    ('SUP-003', 'NetCore Distribution',
     'David Wilson',
     'sales@netcore.example',
     '+1-555-3003',
     '14 Network Drive',
     'Los Angeles', 'USA', 'active');


INSERT INTO warehouses
    (warehouse_code, name, address, city,
     manager_name, phone, capacity, status)
VALUES
    ('WH-001', 'Central Warehouse',
     '120 Commerce Road',
     'New York',
     'Robert Taylor',
     '+1-555-4001',
     10000, 'active'),

    ('WH-002', 'West Warehouse',
     '45 Industrial Park',
     'Chicago',
     'James Anderson',
     '+1-555-4002',
     7500, 'active'),

    ('WH-003', 'Pacific Warehouse',
     '300 Harbor Avenue',
     'Los Angeles',
     'William Davis',
     '+1-555-4003',
     8500, 'active');


INSERT INTO products
    (sku, barcode, name, category_id, supplier_id,
     description, unit, purchase_price, selling_price,
     reorder_level, reorder_quantity, status)
VALUES
    ('SKU-LAP-001', '100000000001',
     'Business Laptop',
     1, 1,
     '15-inch business laptop.',
     'piece', 650.00, 899.00,
     10, 25, 'active'),

    ('SKU-MON-002', '100000000002',
     '24-inch Monitor',
     1, 1,
     'Full HD office monitor.',
     'piece', 120.00, 179.00,
     15, 40, 'active'),

    ('SKU-MOU-003', '100000000003',
     'Wireless Mouse',
     2, 1,
     'Wireless optical mouse.',
     'piece', 12.00, 24.00,
     30, 100, 'active'),

    ('SKU-KBD-004', '100000000004',
     'Mechanical Keyboard',
     2, 1,
     'Mechanical keyboard for office and gaming use.',
     'piece', 45.00, 79.00,
     20, 60, 'active'),

    ('SKU-PEN-005', '100000000005',
     'Ballpoint Pen Pack',
     3, 2,
     'Pack of ten blue ballpoint pens.',
     'pack', 3.50, 7.50,
     50, 200, 'active'),

    ('SKU-ROU-006', '100000000006',
     'Wireless Router',
     4, 3,
     'Dual-band wireless router.',
     'piece', 55.00, 99.00,
     12, 30, 'active'),

    ('SKU-SWT-007', '100000000007',
     'Gigabit Network Switch',
     4, 3,
     '24-port gigabit Ethernet switch.',
     'piece', 95.00, 159.00,
     8, 20, 'active'),

    ('SKU-USB-008', '100000000008',
     'USB-C Hub',
     2, 1,
     'Multi-port USB-C connectivity hub.',
     'piece', 22.00, 39.00,
     25, 80, 'active');


INSERT INTO inventory
    (warehouse_id, product_id, quantity,
     reserved_quantity, minimum_quantity,
     maximum_quantity)
VALUES
    (1, 1, 35, 5, 10, 100),
    (1, 2, 52, 8, 15, 120),
    (1, 3, 110, 10, 30, 250),
    (1, 4, 48, 4, 20, 150),
    (1, 5, 180, 20, 50, 500),
    (1, 6, 24, 2, 12, 80),

    (2, 1, 18, 3, 10, 70),
    (2, 2, 31, 5, 15, 90),
    (2, 3, 65, 8, 30, 180),
    (2, 7, 14, 2, 8, 50),

    (3, 1, 12, 1, 10, 60),
    (3, 4, 22, 3, 20, 100),
    (3, 6, 7, 1, 12, 60),
    (3, 8, 29, 4, 25, 100);


INSERT INTO purchase_orders
    (purchase_order_number, supplier_id, warehouse_id,
     order_date, expected_date, received_date,
     status, notes)
VALUES
    ('PO-10001', 1, 1,
     '2026-08-20', '2026-08-25', '2026-08-25',
     'received',
     'Monthly electronics restock.'),

    ('PO-10002', 2, 1,
     '2026-09-02', '2026-09-10', NULL,
     'ordered',
     'Office supplies restock.'),

    ('PO-10003', 3, 3,
     '2026-09-01', '2026-09-08', NULL,
     'partial',
     'Networking equipment shipment.');


INSERT INTO purchase_order_items
    (purchase_order_id, product_id,
     ordered_quantity, received_quantity, unit_cost)
VALUES
    (1, 1, 20, 20, 650.00),
    (1, 2, 30, 30, 120.00),

    (2, 5, 200, 0, 3.50),

    (3, 6, 20, 20, 55.00),
    (3, 7, 15, 5, 95.00);


INSERT INTO stock_transfers
    (transfer_number, from_warehouse_id,
     to_warehouse_id, transfer_date,
     received_date, status, notes)
VALUES
    ('TR-10001', 1, 2,
     '2026-09-01 09:00:00',
     '2026-09-02 14:00:00',
     'completed',
     'Laptop stock redistribution.'),

    ('TR-10002', 2, 3,
     '2026-09-06 10:30:00',
     NULL,
     'in_transit',
     'Networking equipment transfer.');


INSERT INTO stock_transfer_items
    (transfer_id, product_id, quantity)
VALUES
    (1, 1, 5),
    (1, 3, 15),
    (2, 6, 4),
    (2, 7, 3);


INSERT INTO stock_transactions
    (warehouse_id, product_id, transaction_type,
     quantity, reference_number, transaction_date, notes)
VALUES
    (1, 1, 'purchase', 20,
     'PO-10001', '2026-08-25 11:00:00',
     'Received laptops.'),

    (1, 2, 'purchase', 30,
     'PO-10001', '2026-08-25 11:15:00',
     'Received monitors.'),

    (1, 1, 'transfer_out', 5,
     'TR-10001', '2026-09-01 09:15:00',
     'Transferred laptops to WH-002.'),

    (2, 1, 'transfer_in', 5,
     'TR-10001', '2026-09-02 14:00:00',
     'Received laptops from WH-001.'),

    (1, 3, 'transfer_out', 15,
     'TR-10001', '2026-09-01 09:20:00',
     'Transferred wireless mice.'),

    (2, 3, 'transfer_in', 15,
     'TR-10001', '2026-09-02 14:05:00',
     'Received wireless mice.'),

    (2, 6, 'transfer_out', 4,
     'TR-10002', '2026-09-06 10:45:00',
     'Transferred routers to WH-003.'),

    (3, 6, 'transfer_in', 4,
     'TR-10002', '2026-09-06 16:00:00',
     'Incoming router shipment.'),

    (1, 5, 'sale', 25,
     'SALE-20001', '2026-09-05 13:20:00',
     'Customer order fulfillment.'),

    (3, 6, 'sale', 2,
     'SALE-20002', '2026-09-07 15:10:00',
     'Customer order fulfillment.'),

    (1, 4, 'adjustment_in', 3,
     'ADJ-10001', '2026-09-03 10:00:00',
     'Inventory count adjustment.'),

    (3, 8, 'return_in', 2,
     'RET-10001', '2026-09-04 12:30:00',
     'Customer return.');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW inventory_overview AS
SELECT
    i.inventory_id,
    w.warehouse_code,
    w.name AS warehouse_name,
    w.city,
    p.sku,
    p.name AS product_name,
    c.name AS category,
    i.quantity,
    i.reserved_quantity,
    i.quantity - i.reserved_quantity AS available_quantity,
    i.minimum_quantity,
    i.maximum_quantity,
    p.purchase_price,
    p.selling_price,
    i.quantity * p.purchase_price AS inventory_value,
    i.last_updated
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id
JOIN categories c
    ON p.category_id = c.category_id;


CREATE VIEW low_stock_products AS
SELECT
    i.inventory_id,
    w.warehouse_code,
    w.name AS warehouse_name,
    p.sku,
    p.name AS product_name,
    i.quantity,
    i.reserved_quantity,
    i.quantity - i.reserved_quantity AS available_quantity,
    i.minimum_quantity,
    p.reorder_quantity
FROM inventory i
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
JOIN products p
    ON i.product_id = p.product_id
WHERE i.quantity - i.reserved_quantity <= i.minimum_quantity;


CREATE VIEW product_catalog AS
SELECT
    p.product_id,
    p.sku,
    p.barcode,
    p.name,
    c.name AS category,
    s.company_name AS supplier,
    p.unit,
    p.purchase_price,
    p.selling_price,
    p.reorder_level,
    p.reorder_quantity,
    p.status
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
LEFT JOIN suppliers s
    ON p.supplier_id = s.supplier_id;


CREATE VIEW purchase_order_summary AS
SELECT
    po.purchase_order_number,
    s.company_name AS supplier,
    w.name AS warehouse,
    po.order_date,
    po.expected_date,
    po.received_date,
    po.status,
    COUNT(poi.purchase_order_item_id) AS item_count,
    COALESCE(
        SUM(poi.ordered_quantity * poi.unit_cost),
        0
    ) AS order_value,
    COALESCE(
        SUM(poi.received_quantity * poi.unit_cost),
        0
    ) AS received_value
FROM purchase_orders po
JOIN suppliers s
    ON po.supplier_id = s.supplier_id
JOIN warehouses w
    ON po.warehouse_id = w.warehouse_id
LEFT JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY
    po.purchase_order_id,
    po.purchase_order_number,
    s.company_name,
    w.name,
    po.order_date,
    po.expected_date,
    po.received_date,
    po.status;


CREATE VIEW stock_transfer_summary AS
SELECT
    st.transfer_number,
    fw.name AS from_warehouse,
    tw.name AS to_warehouse,
    st.transfer_date,
    st.received_date,
    st.status,
    COUNT(sti.transfer_item_id) AS item_count,
    COALESCE(SUM(sti.quantity), 0) AS total_units
FROM stock_transfers st
JOIN warehouses fw
    ON st.from_warehouse_id = fw.warehouse_id
JOIN warehouses tw
    ON st.to_warehouse_id = tw.warehouse_id
LEFT JOIN stock_transfer_items sti
    ON st.transfer_id = sti.transfer_id
GROUP BY
    st.transfer_id,
    st.transfer_number,
    fw.name,
    tw.name,
    st.transfer_date,
    st.received_date,
    st.status;


CREATE VIEW stock_transaction_history AS
SELECT
    st.transaction_id,
    st.transaction_date,
    w.warehouse_code,
    w.name AS warehouse_name,
    p.sku,
    p.name AS product_name,
    st.transaction_type,
    st.quantity,
    st.reference_number,
    st.notes
FROM stock_transactions st
JOIN warehouses w
    ON st.warehouse_id = w.warehouse_id
JOIN products p
    ON st.product_id = p.product_id;


CREATE VIEW warehouse_stock_value AS
SELECT
    w.warehouse_id,
    w.warehouse_code,
    w.name AS warehouse_name,
    w.city,
    COUNT(i.product_id) AS product_count,
    COALESCE(SUM(i.quantity), 0) AS total_units,
    COALESCE(
        SUM(i.quantity * p.purchase_price),
        0
    ) AS total_inventory_value
FROM warehouses w
LEFT JOIN inventory i
    ON w.warehouse_id = i.warehouse_id
LEFT JOIN products p
    ON i.product_id = p.product_id
GROUP BY
    w.warehouse_id,
    w.warehouse_code,
    w.name,
    w.city;


-- ============================================================
-- Example Queries
-- ============================================================

-- Show complete inventory
SELECT *
FROM inventory_overview
ORDER BY warehouse_name, product_name;


-- Find low-stock products
SELECT *
FROM low_stock_products
ORDER BY available_quantity ASC;


-- Find products in a specific warehouse
SELECT
    sku,
    product_name,
    quantity,
    available_quantity,
    selling_price
FROM inventory_overview
WHERE warehouse_code = 'WH-001'
ORDER BY product_name;


-- Calculate total inventory value
SELECT
    SUM(inventory_value) AS total_inventory_value
FROM inventory_overview;


-- Inventory value by warehouse
SELECT *
FROM warehouse_stock_value
ORDER BY total_inventory_value DESC;


-- Show pending and in-transit transfers
SELECT *
FROM stock_transfer_summary
WHERE status IN ('pending', 'in_transit')
ORDER BY transfer_date;


-- Show purchase orders that have not been fully received
SELECT *
FROM purchase_order_summary
WHERE status IN ('ordered', 'partial')
ORDER BY expected_date;


-- Products with the highest selling price
SELECT
    sku,
    name,
    selling_price
FROM products
WHERE status = 'active'
ORDER BY selling_price DESC
LIMIT 10;


-- Stock movement for a specific product
SELECT *
FROM stock_transaction_history
WHERE sku = 'SKU-LAP-001'
ORDER BY transaction_date DESC;


-- Stock movement by transaction type
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(quantity) AS total_units
FROM stock_transactions
GROUP BY transaction_type
ORDER BY total_units DESC;


-- Supplier purchase volume
SELECT
    s.company_name AS supplier,
    COUNT(DISTINCT po.purchase_order_id) AS purchase_orders,
    COALESCE(
        SUM(poi.ordered_quantity * poi.unit_cost),
        0
    ) AS total_order_value
FROM suppliers s
LEFT JOIN purchase_orders po
    ON s.supplier_id = po.supplier_id
LEFT JOIN purchase_order_items poi
    ON po.purchase_order_id = poi.purchase_order_id
GROUP BY
    s.supplier_id,
    s.company_name
ORDER BY total_order_value DESC;


-- Products that need replenishment
SELECT
    p.sku,
    p.name,
    w.name AS warehouse,
    i.quantity,
    i.reserved_quantity,
    i.quantity - i.reserved_quantity AS available_quantity,
    i.reorder_quantity
FROM inventory i
JOIN products p
    ON i.product_id = p.product_id
JOIN warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE i.quantity - i.reserved_quantity <= i.minimum_quantity
ORDER BY available_quantity ASC;