-- ============================================================

-- SQLFoundry - Car Rental Management System

-- Database: MySQL 8.0+

-- File: car-rental.sql

-- ============================================================

DROP DATABASE IF EXISTS car_rental_db;

CREATE DATABASE car_rental_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE car_rental_db;


-- ============================================================
-- Table: branches
-- ============================================================

CREATE TABLE branches (
    branch_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    branch_code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_branches_city (city),
    INDEX idx_branches_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: customers
-- ============================================================

CREATE TABLE customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) NOT NULL,
    address VARCHAR(255),
    city VARCHAR(100),
    driver_license_number VARCHAR(100) NOT NULL UNIQUE,
    driver_license_expiry DATE NOT NULL,
    registration_date DATE NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'blocked'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_customers_name (last_name, first_name),
    INDEX idx_customers_city (city),
    INDEX idx_customers_status (status),
    INDEX idx_customers_license_expiry (driver_license_expiry)
) ENGINE=InnoDB;


-- ============================================================
-- Table: vehicle_categories
-- ============================================================

CREATE TABLE vehicle_categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    daily_rate DECIMAL(10,2) NOT NULL,
    weekly_rate DECIMAL(10,2) NOT NULL,
    mileage_limit_per_day INT UNSIGNED NOT NULL DEFAULT 200,
    security_deposit DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT chk_category_daily_rate
        CHECK (daily_rate > 0),

    CONSTRAINT chk_category_weekly_rate
        CHECK (weekly_rate > 0),

    CONSTRAINT chk_category_mileage
        CHECK (mileage_limit_per_day > 0),

    CONSTRAINT chk_category_deposit
        CHECK (security_deposit >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- Table: vehicles
-- ============================================================

CREATE TABLE vehicles (
    vehicle_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    branch_id INT UNSIGNED NOT NULL,
    make VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    model_year YEAR NOT NULL,
    registration_number VARCHAR(50) NOT NULL UNIQUE,
    vin VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(50),
    transmission ENUM(
        'manual',
        'automatic'
    ) NOT NULL,
    fuel_type ENUM(
        'gasoline',
        'diesel',
        'hybrid',
        'electric'
    ) NOT NULL,
    mileage INT UNSIGNED NOT NULL DEFAULT 0,
    daily_rate DECIMAL(10,2),
    status ENUM(
        'available',
        'reserved',
        'rented',
        'maintenance',
        'retired'
    ) NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_vehicles_category
        FOREIGN KEY (category_id)
        REFERENCES vehicle_categories(category_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_vehicles_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_vehicle_mileage
        CHECK (mileage >= 0),

    CONSTRAINT chk_vehicle_daily_rate
        CHECK (daily_rate IS NULL OR daily_rate > 0),

    INDEX idx_vehicles_category (category_id),
    INDEX idx_vehicles_branch (branch_id),
    INDEX idx_vehicles_status (status),
    INDEX idx_vehicles_make_model (make, model)
) ENGINE=InnoDB;


-- ============================================================
-- Table: reservations
-- ============================================================

CREATE TABLE reservations (
    reservation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reservation_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT UNSIGNED NOT NULL,
    vehicle_id INT UNSIGNED NOT NULL,
    pickup_branch_id INT UNSIGNED NOT NULL,
    return_branch_id INT UNSIGNED NOT NULL,
    pickup_date DATETIME NOT NULL,
    return_date DATETIME NOT NULL,
    estimated_total DECIMAL(12,2) NOT NULL,
    status ENUM(
        'pending',
        'confirmed',
        'cancelled',
        'completed'
    ) NOT NULL DEFAULT 'pending',
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_reservations_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_pickup_branch
        FOREIGN KEY (pickup_branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_reservations_return_branch
        FOREIGN KEY (return_branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_reservation_dates
        CHECK (return_date > pickup_date),

    CONSTRAINT chk_reservation_total
        CHECK (estimated_total >= 0),

    INDEX idx_reservations_customer (customer_id),
    INDEX idx_reservations_vehicle (vehicle_id),
    INDEX idx_reservations_pickup_date (pickup_date),
    INDEX idx_reservations_return_date (return_date),
    INDEX idx_reservations_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: rentals
-- ============================================================

CREATE TABLE rentals (
    rental_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rental_number VARCHAR(50) NOT NULL UNIQUE,
    reservation_id BIGINT UNSIGNED,
    customer_id INT UNSIGNED NOT NULL,
    vehicle_id INT UNSIGNED NOT NULL,
    pickup_branch_id INT UNSIGNED NOT NULL,
    return_branch_id INT UNSIGNED NOT NULL,
    pickup_datetime DATETIME NOT NULL,
    expected_return_datetime DATETIME NOT NULL,
    actual_return_datetime DATETIME,
    pickup_mileage INT UNSIGNED NOT NULL,
    return_mileage INT UNSIGNED,
    daily_rate DECIMAL(10,2) NOT NULL,
    base_amount DECIMAL(12,2) NOT NULL,
    extra_charges DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL,
    status ENUM(
        'active',
        'completed',
        'overdue',
        'cancelled'
    ) NOT NULL DEFAULT 'active',
    notes VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_rentals_reservation
        FOREIGN KEY (reservation_id)
        REFERENCES reservations(reservation_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_rentals_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_rentals_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_rentals_pickup_branch
        FOREIGN KEY (pickup_branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_rentals_return_branch
        FOREIGN KEY (return_branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_rental_dates
        CHECK (expected_return_datetime > pickup_datetime),

    CONSTRAINT chk_rental_mileage
        CHECK (
            return_mileage IS NULL
            OR return_mileage >= pickup_mileage
        ),

    CONSTRAINT chk_rental_daily_rate
        CHECK (daily_rate > 0),

    CONSTRAINT chk_rental_base_amount
        CHECK (base_amount >= 0),

    CONSTRAINT chk_rental_extra_charges
        CHECK (extra_charges >= 0),

    CONSTRAINT chk_rental_discount
        CHECK (discount_amount >= 0),

    CONSTRAINT chk_rental_total
        CHECK (total_amount >= 0),

    INDEX idx_rentals_customer (customer_id),
    INDEX idx_rentals_vehicle (vehicle_id),
    INDEX idx_rentals_reservation (reservation_id),
    INDEX idx_rentals_pickup_datetime (pickup_datetime),
    INDEX idx_rentals_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: insurance_plans
-- ============================================================

CREATE TABLE insurance_plans (
    insurance_plan_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    daily_cost DECIMAL(10,2) NOT NULL,
    coverage_limit DECIMAL(15,2) NOT NULL,
    deductible DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT chk_insurance_daily_cost
        CHECK (daily_cost >= 0),

    CONSTRAINT chk_insurance_coverage
        CHECK (coverage_limit > 0),

    CONSTRAINT chk_insurance_deductible
        CHECK (deductible >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- Table: rental_insurance
-- ============================================================

CREATE TABLE rental_insurance (
    rental_insurance_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rental_id BIGINT UNSIGNED NOT NULL,
    insurance_plan_id INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_cost DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_rental_insurance_rental
        FOREIGN KEY (rental_id)
        REFERENCES rentals(rental_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_rental_insurance_plan
        FOREIGN KEY (insurance_plan_id)
        REFERENCES insurance_plans(insurance_plan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_rental_insurance_dates
        CHECK (end_date >= start_date),

    CONSTRAINT chk_rental_insurance_cost
        CHECK (total_cost >= 0),

    UNIQUE (
        rental_id,
        insurance_plan_id
    ),

    INDEX idx_rental_insurance_rental (rental_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rental_id BIGINT UNSIGNED NOT NULL,
    payment_reference VARCHAR(100) NOT NULL UNIQUE,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM(
        'cash',
        'credit_card',
        'debit_card',
        'bank_transfer',
        'online'
    ) NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_payments_rental
        FOREIGN KEY (rental_id)
        REFERENCES rentals(rental_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_rental (rental_id),
    INDEX idx_payments_date (payment_date),
    INDEX idx_payments_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: maintenance_records
-- ============================================================

CREATE TABLE maintenance_records (
    maintenance_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT UNSIGNED NOT NULL,
    maintenance_type ENUM(
        'routine',
        'repair',
        'inspection',
        'tire_service',
        'oil_change',
        'other'
    ) NOT NULL,
    description TEXT NOT NULL,
    maintenance_date DATE NOT NULL,
    mileage INT UNSIGNED NOT NULL,
    cost DECIMAL(12,2) NOT NULL DEFAULT 0,
    service_provider VARCHAR(150),
    status ENUM(
        'scheduled',
        'in_progress',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_maintenance_vehicle
        FOREIGN KEY (vehicle_id)
        REFERENCES vehicles(vehicle_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_maintenance_mileage
        CHECK (mileage >= 0),

    CONSTRAINT chk_maintenance_cost
        CHECK (cost >= 0),

    INDEX idx_maintenance_vehicle (vehicle_id),
    INDEX idx_maintenance_date (maintenance_date),
    INDEX idx_maintenance_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO branches
    (branch_code, name, address, city, phone, status)
VALUES
    ('BR-001', 'Downtown Rental Center',
     '100 Main Street', 'New York',
     '+1-555-1001', 'active'),

    ('BR-002', 'Airport Rental Center',
     '1 Airport Road', 'Chicago',
     '+1-555-1002', 'active'),

    ('BR-003', 'Westside Rental Center',
     '75 Sunset Boulevard', 'Los Angeles',
     '+1-555-1003', 'active');


INSERT INTO customers
    (customer_number, first_name, last_name, date_of_birth,
     email, phone, address, city,
     driver_license_number, driver_license_expiry,
     registration_date, status)
VALUES
    ('CUS-10001', 'John', 'Smith', '1988-04-15',
     'john.smith@example.com', '+1-555-2001',
     '12 Oak Street', 'New York',
     'DL-NY-10001', '2029-04-15',
     '2025-02-10', 'active'),

    ('CUS-10002', 'Emma', 'Wilson', '1992-09-21',
     'emma.wilson@example.com', '+1-555-2002',
     '44 Lake Road', 'Chicago',
     'DL-IL-10002', '2028-09-21',
     '2025-05-18', 'active'),

    ('CUS-10003', 'Daniel', 'Miller', '1985-12-03',
     'daniel.miller@example.com', '+1-555-2003',
     '78 Pine Avenue', 'Los Angeles',
     'DL-CA-10003', '2030-12-03',
     '2025-07-12', 'active'),

    ('CUS-10004', 'Sophia', 'Garcia', '1995-07-30',
     'sophia.garcia@example.com', '+1-555-2004',
     '91 River Street', 'New York',
     'DL-NY-10004', '2029-07-30',
     '2026-01-05', 'active');


INSERT INTO vehicle_categories
    (name, description, daily_rate, weekly_rate,
     mileage_limit_per_day, security_deposit, status)
VALUES
    ('Economy',
     'Fuel-efficient compact vehicles.',
     45.00, 270.00, 200, 300.00, 'active'),

    ('Compact',
     'Comfortable vehicles for city travel.',
     60.00, 360.00, 250, 400.00, 'active'),

    ('SUV',
     'Sport utility vehicles with additional space.',
     95.00, 570.00, 300, 600.00, 'active'),

    ('Luxury',
     'Premium vehicles with enhanced comfort.',
     180.00, 1080.00, 250, 1000.00, 'active'),

    ('Electric',
     'Electric vehicles for efficient transportation.',
     110.00, 660.00, 300, 700.00, 'active');


INSERT INTO vehicles
    (category_id, branch_id, make, model, model_year,
     registration_number, vin, color, transmission,
     fuel_type, mileage, daily_rate, status)
VALUES
    (1, 1, 'Toyota', 'Yaris', 2025,
     'NY-ECO-101', 'VIN000000000000001',
     'White', 'automatic', 'gasoline',
     12500, 45.00, 'available'),

    (2, 1, 'Honda', 'Civic', 2025,
     'NY-CMP-102', 'VIN000000000000002',
     'Black', 'automatic', 'gasoline',
     9800, 60.00, 'available'),

    (3, 2, 'Toyota', 'RAV4', 2024,
     'IL-SUV-201', 'VIN000000000000003',
     'Gray', 'automatic', 'hybrid',
     18500, 95.00, 'available'),

    (4, 2, 'BMW', '5 Series', 2025,
     'IL-LUX-202', 'VIN000000000000004',
     'Black', 'automatic', 'gasoline',
     7200, 180.00, 'rented'),

    (5, 3, 'Tesla', 'Model 3', 2025,
     'CA-EV-301', 'VIN000000000000005',
     'Blue', 'automatic', 'electric',
     5400, 110.00, 'reserved'),

    (3, 3, 'Ford', 'Explorer', 2023,
     'CA-SUV-302', 'VIN000000000000006',
     'Silver', 'automatic', 'gasoline',
     42000, 95.00, 'maintenance');


INSERT INTO reservations
    (reservation_number, customer_id, vehicle_id,
     pickup_branch_id, return_branch_id,
     pickup_date, return_date, estimated_total,
     status, notes)
VALUES
    ('RES-10001', 1, 1, 1, 1,
     '2026-09-12 09:00:00',
     '2026-09-15 09:00:00',
     135.00, 'confirmed',
     'City trip'),

    ('RES-10002', 2, 3, 2, 2,
     '2026-09-20 10:00:00',
     '2026-09-25 10:00:00',
     475.00, 'confirmed',
     'Family vacation'),

    ('RES-10003', 4, 5, 3, 3,
     '2026-09-18 08:00:00',
     '2026-09-21 08:00:00',
     330.00, 'confirmed',
     'Business trip');


INSERT INTO rentals
    (rental_number, reservation_id, customer_id, vehicle_id,
     pickup_branch_id, return_branch_id,
     pickup_datetime, expected_return_datetime,
     actual_return_datetime,
     pickup_mileage, return_mileage,
     daily_rate, base_amount, extra_charges,
     discount_amount, total_amount, status, notes)
VALUES
    ('RNT-10001', NULL, 1, 2,
     1, 1,
     '2026-09-01 09:00:00',
     '2026-09-05 09:00:00',
     '2026-09-05 08:40:00',
     9500, 10180,
     60.00, 240.00, 25.00,
     10.00, 255.00, 'completed',
     'Returned in good condition.'),

    ('RNT-10002', NULL, 2, 4,
     2, 2,
     '2026-09-07 10:00:00',
     '2026-09-12 10:00:00',
     NULL,
     7200, NULL,
     180.00, 900.00, 0.00,
     50.00, 850.00, 'active',
     'Vehicle currently rented.'),

    ('RNT-10003', NULL, 3, 3,
     2, 3,
     '2026-08-20 11:00:00',
     '2026-08-24 11:00:00',
     '2026-08-24 12:15:00',
     17800, 19050,
     95.00, 380.00, 70.00,
     0.00, 450.00, 'completed',
     'One-way rental.');


INSERT INTO insurance_plans
    (name, description, daily_cost,
     coverage_limit, deductible, status)
VALUES
    ('Basic Protection',
     'Basic damage protection.',
     10.00, 10000.00, 1000.00, 'active'),

    ('Standard Protection',
     'Extended protection with reduced deductible.',
     20.00, 25000.00, 500.00, 'active'),

    ('Premium Protection',
     'Comprehensive rental protection.',
     35.00, 50000.00, 100.00, 'active');


INSERT INTO rental_insurance
    (rental_id, insurance_plan_id,
     start_date, end_date, total_cost)
VALUES
    (1, 2, '2026-09-01', '2026-09-05', 80.00),
    (2, 3, '2026-09-07', '2026-09-12', 175.00),
    (3, 1, '2026-08-20', '2026-08-24', 40.00);


INSERT INTO payments
    (rental_id, payment_reference, amount,
     payment_method, payment_date, status)
VALUES
    (1, 'PAY-10001', 255.00,
     'credit_card', '2026-09-01 08:50:00', 'completed'),

    (2, 'PAY-10002', 850.00,
     'credit_card', '2026-09-07 09:45:00', 'completed'),

    (3, 'PAY-10003', 450.00,
     'bank_transfer', '2026-08-20 10:30:00', 'completed');


INSERT INTO maintenance_records
    (vehicle_id, maintenance_type, description,
     maintenance_date, mileage, cost,
     service_provider, status)
VALUES
    (1, 'oil_change',
     'Engine oil and filter replacement.',
     '2026-07-15', 11000, 85.00,
     'City Auto Service', 'completed'),

    (2, 'routine',
     'Scheduled 10,000 km service.',
     '2026-08-10', 9000, 150.00,
     'Downtown Motors', 'completed'),

    (6, 'repair',
     'Brake system inspection and repair.',
     '2026-09-06', 42000, 620.00,
     'Westside Auto Center', 'in_progress');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW vehicle_inventory AS
SELECT
    v.vehicle_id,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    v.model_year,
    vc.name AS category,
    v.color,
    v.transmission,
    v.fuel_type,
    v.mileage,
    COALESCE(v.daily_rate, vc.daily_rate) AS daily_rate,
    b.name AS branch_name,
    b.city,
    v.status
FROM vehicles v
JOIN vehicle_categories vc
    ON v.category_id = vc.category_id
JOIN branches b
    ON v.branch_id = b.branch_id;


CREATE VIEW available_vehicles AS
SELECT
    v.vehicle_id,
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    v.model_year,
    vc.name AS category,
    v.color,
    v.transmission,
    v.fuel_type,
    v.mileage,
    COALESCE(v.daily_rate, vc.daily_rate) AS daily_rate,
    b.name AS branch_name,
    b.city
FROM vehicles v
JOIN vehicle_categories vc
    ON v.category_id = vc.category_id
JOIN branches b
    ON v.branch_id = b.branch_id
WHERE v.status = 'available';


CREATE VIEW rental_details AS
SELECT
    r.rental_id,
    r.rental_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.customer_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    v.registration_number,
    r.pickup_datetime,
    r.expected_return_datetime,
    r.actual_return_datetime,
    r.pickup_mileage,
    r.return_mileage,
    r.daily_rate,
    r.base_amount,
    r.extra_charges,
    r.discount_amount,
    r.total_amount,
    r.status
FROM rentals r
JOIN customers c
    ON r.customer_id = c.customer_id
JOIN vehicles v
    ON r.vehicle_id = v.vehicle_id;


CREATE VIEW active_rentals AS
SELECT
    r.rental_id,
    r.rental_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    v.registration_number,
    r.pickup_datetime,
    r.expected_return_datetime,
    r.total_amount,
    r.status
FROM rentals r
JOIN customers c
    ON r.customer_id = c.customer_id
JOIN vehicles v
    ON r.vehicle_id = v.vehicle_id
WHERE r.status IN ('active', 'overdue');


CREATE VIEW payment_summary AS
SELECT
    r.rental_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    r.total_amount AS rental_total,
    COALESCE(
        SUM(
            CASE
                WHEN p.status = 'completed'
                THEN p.amount
                ELSE 0
            END
        ),
        0
    ) AS total_paid,
    r.total_amount -
    COALESCE(
        SUM(
            CASE
                WHEN p.status = 'completed'
                THEN p.amount
                ELSE 0
            END
        ),
        0
    ) AS remaining_amount
FROM rentals r
JOIN customers c
    ON r.customer_id = c.customer_id
LEFT JOIN payments p
    ON r.rental_id = p.rental_id
GROUP BY
    r.rental_id,
    r.rental_number,
    c.first_name,
    c.last_name,
    r.total_amount;


CREATE VIEW vehicle_maintenance_history AS
SELECT
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    m.maintenance_type,
    m.description,
    m.maintenance_date,
    m.mileage,
    m.cost,
    m.service_provider,
    m.status
FROM maintenance_records m
JOIN vehicles v
    ON m.vehicle_id = v.vehicle_id;


-- ============================================================
-- Example Queries
-- ============================================================

-- List all available vehicles
SELECT *
FROM available_vehicles
ORDER BY category, daily_rate;


-- Find available SUVs
SELECT *
FROM available_vehicles
WHERE category = 'SUV'
ORDER BY daily_rate;


-- Show all active rentals
SELECT *
FROM active_rentals
ORDER BY expected_return_datetime;


-- Rental payment status
SELECT *
FROM payment_summary
ORDER BY remaining_amount DESC;


-- Customers with active rentals
SELECT
    customer_name,
    COUNT(*) AS active_rental_count,
    SUM(total_amount) AS total_rental_value
FROM active_rentals
GROUP BY customer_name
ORDER BY active_rental_count DESC;


-- Revenue by payment method
SELECT
    p.payment_method,
    COUNT(*) AS payment_count,
    SUM(p.amount) AS total_revenue
FROM payments p
WHERE p.status = 'completed'
GROUP BY p.payment_method
ORDER BY total_revenue DESC;


-- Vehicle rental frequency
SELECT
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    COUNT(r.rental_id) AS rental_count,
    COALESCE(SUM(r.total_amount), 0) AS rental_revenue
FROM vehicles v
LEFT JOIN rentals r
    ON v.vehicle_id = r.vehicle_id
    AND r.status = 'completed'
GROUP BY
    v.vehicle_id,
    v.registration_number,
    v.make,
    v.model
ORDER BY rental_count DESC;


-- Total revenue from completed rentals
SELECT
    SUM(total_amount) AS total_rental_revenue
FROM rentals
WHERE status = 'completed';


-- Maintenance costs by vehicle
SELECT
    v.registration_number,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    COUNT(m.maintenance_id) AS maintenance_count,
    COALESCE(SUM(m.cost), 0) AS total_maintenance_cost
FROM vehicles v
LEFT JOIN maintenance_records m
    ON v.vehicle_id = m.vehicle_id
GROUP BY
    v.vehicle_id,
    v.registration_number,
    v.make,
    v.model
ORDER BY total_maintenance_cost DESC;


-- Vehicles currently under maintenance
SELECT *
FROM vehicle_maintenance_history
WHERE status IN ('scheduled', 'in_progress')
ORDER BY maintenance_date;


-- Upcoming reservations
SELECT
    r.reservation_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    CONCAT(v.make, ' ', v.model) AS vehicle_name,
    r.pickup_date,
    r.return_date,
    r.estimated_total,
    r.status
FROM reservations r
JOIN customers c
    ON r.customer_id = c.customer_id
JOIN vehicles v
    ON r.vehicle_id = v.vehicle_id
WHERE r.status IN ('pending', 'confirmed')
ORDER BY r.pickup_date;


-- Vehicle utilization by category
SELECT
    vc.name AS category,
    COUNT(DISTINCT v.vehicle_id) AS vehicle_count,
    COUNT(r.rental_id) AS completed_rentals,
    COALESCE(SUM(r.total_amount), 0) AS total_revenue
FROM vehicle_categories vc
LEFT JOIN vehicles v
    ON vc.category_id = v.category_id
LEFT JOIN rentals r
    ON v.vehicle_id = r.vehicle_id
    AND r.status = 'completed'
GROUP BY
    vc.category_id,
    vc.name
ORDER BY total_revenue DESC;