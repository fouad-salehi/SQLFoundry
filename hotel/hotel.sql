-- ============================================================

-- SQLFoundry - Hotel Management System

-- Database: MySQL 8.0+

-- File: hotel.sql

-- ============================================================

DROP DATABASE IF EXISTS hotel_db;

CREATE DATABASE hotel_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE hotel_db;


-- ============================================================
-- Table: room_types
-- ============================================================

CREATE TABLE room_types (
    room_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    capacity TINYINT UNSIGNED NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_room_type_capacity
        CHECK (capacity > 0),

    CONSTRAINT chk_room_type_price
        CHECK (base_price >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- Table: rooms
-- ============================================================

CREATE TABLE rooms (
    room_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    room_type_id INT UNSIGNED NOT NULL,
    floor SMALLINT NOT NULL,
    status ENUM(
        'available',
        'occupied',
        'maintenance',
        'out_of_service'
    ) NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_rooms_room_type
        FOREIGN KEY (room_type_id)
        REFERENCES room_types(room_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_room_floor
        CHECK (floor >= 0),

    INDEX idx_rooms_room_type (room_type_id),
    INDEX idx_rooms_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: guests
-- ============================================================

CREATE TABLE guests (
    guest_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    nationality VARCHAR(100),
    id_number VARCHAR(100) UNIQUE,
    date_of_birth DATE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_guests_name (last_name, first_name),
    INDEX idx_guests_phone (phone)
) ENGINE=InnoDB;


-- ============================================================
-- Table: employees
-- ============================================================

CREATE TABLE employees (
    employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role ENUM(
        'manager',
        'receptionist',
        'housekeeping',
        'maintenance',
        'chef',
        'security'
    ) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    salary DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_employee_salary
        CHECK (salary >= 0),

    INDEX idx_employees_role (role),
    INDEX idx_employees_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: reservations
-- ============================================================

CREATE TABLE reservations (
    reservation_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    guest_id INT UNSIGNED NOT NULL,
    room_id INT UNSIGNED NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    adults TINYINT UNSIGNED NOT NULL DEFAULT 1,
    children TINYINT UNSIGNED NOT NULL DEFAULT 0,
    status ENUM(
        'pending',
        'confirmed',
        'checked_in',
        'checked_out',
        'cancelled',
        'no_show'
    ) NOT NULL DEFAULT 'pending',
    special_requests TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservations_guest
        FOREIGN KEY (guest_id)
        REFERENCES guests(guest_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(room_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_reservation_dates
        CHECK (check_out > check_in),

    CONSTRAINT chk_reservation_guests
        CHECK (adults + children > 0),

    INDEX idx_reservations_guest (guest_id),
    INDEX idx_reservations_room (room_id),
    INDEX idx_reservations_dates (check_in, check_out),
    INDEX idx_reservations_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: reservation_guests
-- ============================================================

CREATE TABLE reservation_guests (
    reservation_id INT UNSIGNED NOT NULL,
    guest_id INT UNSIGNED NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY (reservation_id, guest_id),

    CONSTRAINT fk_reservation_guests_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_reservation_guests_guest
        FOREIGN KEY (guest_id)
        REFERENCES guests(guest_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_reservation_guests_guest (guest_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: services
-- ============================================================

CREATE TABLE services (
    service_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    status ENUM(
        'available',
        'unavailable'
    ) NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_service_price
        CHECK (price >= 0),

    INDEX idx_services_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: service_orders
-- ============================================================

CREATE TABLE service_orders (
    service_order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL,
    service_id INT UNSIGNED NOT NULL,
    employee_id INT UNSIGNED,
    quantity INT UNSIGNED NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    ordered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'requested',
        'in_progress',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'requested',

    CONSTRAINT fk_service_orders_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_service_orders_service
        FOREIGN KEY (service_id)
        REFERENCES services(service_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_service_orders_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_service_order_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_service_order_price
        CHECK (unit_price >= 0),

    INDEX idx_service_orders_reservation (reservation_id),
    INDEX idx_service_orders_service (service_id),
    INDEX idx_service_orders_employee (employee_id),
    INDEX idx_service_orders_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: invoices
-- ============================================================

CREATE TABLE invoices (
    invoice_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT UNSIGNED NOT NULL UNIQUE,
    issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM(
        'unpaid',
        'partially_paid',
        'paid',
        'cancelled'
    ) NOT NULL DEFAULT 'unpaid',

    CONSTRAINT fk_invoices_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_invoice_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_invoice_tax
        CHECK (tax >= 0),

    CONSTRAINT chk_invoice_discount
        CHECK (discount >= 0),

    CONSTRAINT chk_invoice_total
        CHECK (total >= 0),

    INDEX idx_invoices_status (status),
    INDEX idx_invoices_issued_at (issued_at)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT UNSIGNED NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM(
        'cash',
        'card',
        'bank_transfer',
        'online'
    ) NOT NULL,
    transaction_reference VARCHAR(150) UNIQUE,
    paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'pending',
        'completed',
        'refunded',
        'failed'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_payments_invoice
        FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_invoice (invoice_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_paid_at (paid_at)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO room_types
    (name, description, capacity, base_price)
VALUES
    ('Single', 'Comfortable room for one guest.', 1, 80.00),
    ('Double', 'Room with a double bed for two guests.', 2, 120.00),
    ('Twin', 'Room with two separate beds.', 2, 125.00),
    ('Deluxe', 'Spacious room with premium facilities.', 3, 180.00),
    ('Suite', 'Luxury suite with separate living area.', 4, 300.00);


INSERT INTO rooms
    (room_number, room_type_id, floor, status)
VALUES
    ('101', 1, 1, 'available'),
    ('102', 2, 1, 'occupied'),
    ('103', 3, 1, 'available'),
    ('201', 2, 2, 'available'),
    ('202', 4, 2, 'maintenance'),
    ('203', 4, 2, 'available'),
    ('301', 5, 3, 'available'),
    ('302', 5, 3, 'occupied');


INSERT INTO guests
    (first_name, last_name, email, phone, nationality, id_number, date_of_birth)
VALUES
    ('John', 'Smith', 'john.smith@example.com', '+1-555-1001', 'American', 'US100001', '1992-04-15'),
    ('Emma', 'Wilson', 'emma.wilson@example.com', '+1-555-1002', 'British', 'UK100002', '1990-08-22'),
    ('Daniel', 'Miller', 'daniel.miller@example.com', '+1-555-1003', 'Canadian', 'CA100003', '1988-12-10'),
    ('Sofia', 'Garcia', 'sofia.garcia@example.com', '+34-555-1004', 'Spanish', 'ES100004', '1995-02-18');


INSERT INTO employees
    (first_name, last_name, role, email, phone, hire_date, salary)
VALUES
    ('Michael', 'Brown', 'manager', 'michael.brown@hotel.example', '+1-555-2001', '2022-01-10', 4200.00),
    ('Olivia', 'Davis', 'receptionist', 'olivia.davis@hotel.example', '+1-555-2002', '2023-05-14', 2600.00),
    ('James', 'Taylor', 'housekeeping', 'james.taylor@hotel.example', '+1-555-2003', '2024-02-01', 2200.00),
    ('Sophia', 'Anderson', 'maintenance', 'sophia.anderson@hotel.example', '+1-555-2004', '2023-09-20', 2400.00);


INSERT INTO services
    (name, description, price, status)
VALUES
    ('Breakfast', 'Daily breakfast service.', 18.00, 'available'),
    ('Airport Transfer', 'One-way airport transportation.', 45.00, 'available'),
    ('Laundry', 'Laundry and garment cleaning service.', 25.00, 'available'),
    ('Room Service', 'Food and beverage room service.', 15.00, 'available'),
    ('Spa', 'One standard spa session.', 70.00, 'available');


INSERT INTO reservations
    (guest_id, room_id, check_in, check_out, adults, children, status, special_requests)
VALUES
    (1, 2, '2026-09-07', '2026-09-12', 1, 0, 'checked_in', 'Late check-in requested.'),
    (2, 8, '2026-09-08', '2026-09-15', 2, 0, 'checked_in', NULL),
    (3, 4, '2026-09-18', '2026-09-21', 2, 1, 'confirmed', 'Extra bed requested.'),
    (4, 7, '2026-10-02', '2026-10-06', 2, 0, 'confirmed', 'Quiet room preferred.');


INSERT INTO reservation_guests
    (reservation_id, guest_id, is_primary)
VALUES
    (1, 1, TRUE),
    (2, 2, TRUE),
    (3, 3, TRUE),
    (4, 4, TRUE);


INSERT INTO service_orders
    (reservation_id, service_id, employee_id, quantity, unit_price, status)
VALUES
    (1, 1, 2, 2, 18.00, 'completed'),
    (1, 4, 2, 1, 15.00, 'completed'),
    (2, 3, 3, 2, 25.00, 'completed'),
    (3, 2, 2, 1, 45.00, 'requested'),
    (4, 5, 2, 1, 70.00, 'requested');


INSERT INTO invoices
    (reservation_id, subtotal, tax, discount, total, status)
VALUES
    (1, 450.00, 45.00, 0.00, 495.00, 'partially_paid'),
    (2, 875.00, 87.50, 50.00, 912.50, 'paid'),
    (3, 420.00, 42.00, 0.00, 462.00, 'unpaid'),
    (4, 1200.00, 120.00, 100.00, 1220.00, 'unpaid');


INSERT INTO payments
    (invoice_id, amount, payment_method, transaction_reference, status)
VALUES
    (1, 200.00, 'card', 'TXN-100001', 'completed'),
    (2, 912.50, 'bank_transfer', 'TXN-100002', 'completed');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW available_rooms AS
SELECT
    r.room_id,
    r.room_number,
    r.floor,
    rt.name AS room_type,
    rt.capacity,
    rt.base_price
FROM rooms r
JOIN room_types rt
    ON r.room_type_id = rt.room_type_id
WHERE r.status = 'available';


CREATE VIEW active_reservations AS
SELECT
    r.reservation_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    r.room_id,
    rm.room_number,
    rt.name AS room_type,
    r.check_in,
    r.check_out,
    r.adults,
    r.children,
    r.status
FROM reservations r
JOIN guests g
    ON r.guest_id = g.guest_id
JOIN rooms rm
    ON r.room_id = rm.room_id
JOIN room_types rt
    ON rm.room_type_id = rt.room_type_id
WHERE r.status IN ('confirmed', 'checked_in');


CREATE VIEW service_order_details AS
SELECT
    so.service_order_id,
    so.reservation_id,
    CONCAT(g.first_name, ' ', g.last_name) AS guest_name,
    s.name AS service_name,
    so.quantity,
    so.unit_price,
    so.quantity * so.unit_price AS total_price,
    so.status,
    so.ordered_at
FROM service_orders so
JOIN reservations r
    ON so.reservation_id = r.reservation_id
JOIN guests g
    ON r.guest_id = g.guest_id
JOIN services s
    ON so.service_id = s.service_id;


CREATE VIEW invoice_payment_summary AS
SELECT
    i.invoice_id,
    i.reservation_id,
    i.total AS invoice_total,
    COALESCE(
        SUM(
            CASE
                WHEN p.status = 'completed' THEN p.amount
                ELSE 0
            END
        ),
        0
    ) AS paid_amount,
    i.total -
    COALESCE(
        SUM(
            CASE
                WHEN p.status = 'completed' THEN p.amount
                ELSE 0
            END
        ),
        0
    ) AS remaining_amount,
    i.status
FROM invoices i
LEFT JOIN payments p
    ON i.invoice_id = p.invoice_id
GROUP BY
    i.invoice_id,
    i.reservation_id,
    i.total,
    i.status;


CREATE VIEW room_occupancy AS
SELECT
    r.room_id,
    r.room_number,
    rt.name AS room_type,
    r.status AS room_status,
    COUNT(
        CASE
            WHEN res.status IN ('confirmed', 'checked_in')
            THEN res.reservation_id
        END
    ) AS active_reservations
FROM rooms r
JOIN room_types rt
    ON r.room_type_id = rt.room_type_id
LEFT JOIN reservations res
    ON r.room_id = res.room_id
GROUP BY
    r.room_id,
    r.room_number,
    rt.name,
    r.status;


-- ============================================================
-- Example Queries
-- ============================================================

-- Available rooms
SELECT *
FROM available_rooms;


-- Current and upcoming reservations
SELECT *
FROM active_reservations
ORDER BY check_in;


-- Guest reservation history
SELECT
    g.first_name,
    g.last_name,
    r.reservation_id,
    rm.room_number,
    r.check_in,
    r.check_out,
    r.status
FROM guests g
JOIN reservations r
    ON g.guest_id = r.guest_id
JOIN rooms rm
    ON r.room_id = rm.room_id
WHERE g.guest_id = 1
ORDER BY r.check_in DESC;


-- Calculate reservation stay length
SELECT
    reservation_id,
    DATEDIFF(check_out, check_in) AS nights
FROM reservations;


-- Service revenue
SELECT
    s.name AS service,
    SUM(so.quantity) AS units_sold,
    SUM(so.quantity * so.unit_price) AS revenue
FROM service_orders so
JOIN services s
    ON so.service_id = s.service_id
WHERE so.status = 'completed'
GROUP BY s.service_id, s.name
ORDER BY revenue DESC;


-- Invoice payment status
SELECT *
FROM invoice_payment_summary
ORDER BY invoice_id;


-- Unpaid invoices
SELECT
    invoice_id,
    reservation_id,
    total,
    status
FROM invoices
WHERE status IN ('unpaid', 'partially_paid')
ORDER BY issued_at;


-- Hotel revenue from completed payments
SELECT
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'completed';


-- Employees by role
SELECT
    role,
    COUNT(*) AS employee_count
FROM employees
WHERE status = 'active'
GROUP BY role
ORDER BY employee_count DESC;


-- Room occupancy overview
SELECT *
FROM room_occupancy
ORDER BY room_number;