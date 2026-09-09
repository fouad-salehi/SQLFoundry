-- ============================================================

-- SQLFoundry - Airport Management System

-- Database: MySQL 8.0+

-- File: airport.sql

-- ============================================================

DROP DATABASE IF EXISTS airport_db;

CREATE DATABASE airport_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE airport_db;

-- ============================================================
-- AIRPORTS
-- ============================================================

CREATE TABLE airports (
    airport_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airport_code CHAR(3) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    timezone VARCHAR(50) NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TERMINALS
-- ============================================================

CREATE TABLE terminals (
    terminal_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airport_id INT UNSIGNED NOT NULL,
    terminal_code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',

    CONSTRAINT fk_terminals_airport
        FOREIGN KEY (airport_id)
        REFERENCES airports(airport_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    UNIQUE KEY uq_terminal_code (airport_id, terminal_code)
);

-- ============================================================
-- GATES
-- ============================================================

CREATE TABLE gates (
    gate_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    terminal_id INT UNSIGNED NOT NULL,
    gate_code VARCHAR(10) NOT NULL,
    gate_type ENUM('standard', 'wide_body', 'bus') NOT NULL DEFAULT 'standard',
    status ENUM('available', 'occupied', 'maintenance', 'closed')
        NOT NULL DEFAULT 'available',

    CONSTRAINT fk_gates_terminal
        FOREIGN KEY (terminal_id)
        REFERENCES terminals(terminal_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    UNIQUE KEY uq_gate_code (terminal_id, gate_code)
);

-- ============================================================
-- AIRLINES
-- ============================================================

CREATE TABLE airlines (
    airline_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airline_code CHAR(2) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    country VARCHAR(100) NOT NULL,
    contact_email VARCHAR(150),
    phone VARCHAR(30),
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- AIRCRAFTS
-- ============================================================

CREATE TABLE aircrafts (
    aircraft_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airline_id INT UNSIGNED NOT NULL,
    registration_number VARCHAR(20) NOT NULL UNIQUE,
    model VARCHAR(100) NOT NULL,
    manufacturer VARCHAR(100) NOT NULL,
    seat_capacity SMALLINT UNSIGNED NOT NULL,
    manufacture_year YEAR,
    status ENUM('active', 'maintenance', 'retired')
        NOT NULL DEFAULT 'active',

    CONSTRAINT fk_aircrafts_airline
        FOREIGN KEY (airline_id)
        REFERENCES airlines(airline_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_aircraft_seats
        CHECK (seat_capacity > 0)
);

-- ============================================================
-- ROUTES
-- ============================================================

CREATE TABLE routes (
    route_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    origin_airport_id INT UNSIGNED NOT NULL,
    destination_airport_id INT UNSIGNED NOT NULL,
    distance_km DECIMAL(8,2) NOT NULL,

    CONSTRAINT fk_routes_origin
        FOREIGN KEY (origin_airport_id)
        REFERENCES airports(airport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_routes_destination
        FOREIGN KEY (destination_airport_id)
        REFERENCES airports(airport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_route_airports
        CHECK (origin_airport_id <> destination_airport_id),

    CONSTRAINT chk_route_distance
        CHECK (distance_km > 0),

    UNIQUE KEY uq_route (origin_airport_id, destination_airport_id)
);

-- ============================================================
-- FLIGHTS
-- ============================================================

CREATE TABLE flights (
    flight_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airline_id INT UNSIGNED NOT NULL,
    aircraft_id INT UNSIGNED NOT NULL,
    route_id INT UNSIGNED NOT NULL,
    flight_number VARCHAR(20) NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    gate_id INT UNSIGNED,
    terminal_id INT UNSIGNED,
    base_fare DECIMAL(10,2) NOT NULL,
    status ENUM(
        'scheduled',
        'boarding',
        'departed',
        'arrived',
        'delayed',
        'cancelled'
    ) NOT NULL DEFAULT 'scheduled',

    CONSTRAINT fk_flights_airline
        FOREIGN KEY (airline_id)
        REFERENCES airlines(airline_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_flights_aircraft
        FOREIGN KEY (aircraft_id)
        REFERENCES aircrafts(aircraft_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_flights_route
        FOREIGN KEY (route_id)
        REFERENCES routes(route_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_flights_gate
        FOREIGN KEY (gate_id)
        REFERENCES gates(gate_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_flights_terminal
        FOREIGN KEY (terminal_id)
        REFERENCES terminals(terminal_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_flight_times
        CHECK (arrival_time > departure_time),

    CONSTRAINT chk_flight_fare
        CHECK (base_fare >= 0),

    INDEX idx_flights_departure (departure_time),
    INDEX idx_flights_status (status),
    INDEX idx_flights_number (flight_number)
);

-- ============================================================
-- PASSENGERS
-- ============================================================

CREATE TABLE passengers (
    passenger_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    passport_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    date_of_birth DATE NOT NULL,
    nationality VARCHAR(80) NOT NULL,
    email VARCHAR(150),
    phone VARCHAR(30),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_passengers_name (last_name, first_name),
    INDEX idx_passengers_email (email)
);

-- ============================================================
-- BOOKINGS
-- ============================================================

CREATE TABLE bookings (
    booking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_reference VARCHAR(20) NOT NULL UNIQUE,
    passenger_id BIGINT UNSIGNED NOT NULL,
    flight_id BIGINT UNSIGNED NOT NULL,
    booking_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM(
        'reserved',
        'confirmed',
        'checked_in',
        'cancelled',
        'completed'
    ) NOT NULL DEFAULT 'reserved',
    total_amount DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_bookings_passenger
        FOREIGN KEY (passenger_id)
        REFERENCES passengers(passenger_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_bookings_flight
        FOREIGN KEY (flight_id)
        REFERENCES flights(flight_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_booking_amount
        CHECK (total_amount >= 0),

    INDEX idx_bookings_passenger (passenger_id),
    INDEX idx_bookings_flight (flight_id),
    INDEX idx_bookings_status (booking_status)
);

-- ============================================================
-- TICKETS
-- ============================================================

CREATE TABLE tickets (
    ticket_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    ticket_number VARCHAR(30) NOT NULL UNIQUE,
    seat_number VARCHAR(10) NOT NULL,
    cabin_class ENUM('economy', 'premium_economy', 'business', 'first')
        NOT NULL DEFAULT 'economy',
    ticket_price DECIMAL(10,2) NOT NULL,
    ticket_status ENUM('issued', 'used', 'cancelled', 'refunded')
        NOT NULL DEFAULT 'issued',

    CONSTRAINT fk_tickets_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_ticket_price
        CHECK (ticket_price >= 0),

    UNIQUE KEY uq_booking_seat (booking_id, seat_number)
);

-- ============================================================
-- BAGGAGE
-- ============================================================

CREATE TABLE baggage (
    baggage_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    baggage_tag VARCHAR(30) NOT NULL UNIQUE,
    weight_kg DECIMAL(6,2) NOT NULL,
    baggage_type ENUM('checked', 'carry_on', 'special')
        NOT NULL DEFAULT 'checked',
    status ENUM(
        'registered',
        'loaded',
        'in_transit',
        'delivered',
        'lost'
    ) NOT NULL DEFAULT 'registered',

    CONSTRAINT fk_baggage_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_baggage_weight
        CHECK (weight_kg > 0)
);

-- ============================================================
-- EMPLOYEES
-- ============================================================

CREATE TABLE employees (
    employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    airport_id INT UNSIGNED NOT NULL,
    employee_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(80) NOT NULL,
    last_name VARCHAR(80) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',

    CONSTRAINT fk_employees_airport
        FOREIGN KEY (airport_id)
        REFERENCES airports(airport_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- CHECK-INS
-- ============================================================

CREATE TABLE check_ins (
    check_in_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL UNIQUE,
    employee_id INT UNSIGNED,
    check_in_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    boarding_pass_number VARCHAR(30) NOT NULL UNIQUE,
    check_in_status ENUM('checked_in', 'cancelled')
        NOT NULL DEFAULT 'checked_in',

    CONSTRAINT fk_checkins_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_checkins_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

-- ============================================================
-- PAYMENTS
-- ============================================================

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    payment_reference VARCHAR(40) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('cash', 'card', 'bank_transfer', 'online')
        NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'failed', 'refunded')
        NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0)
);

-- ============================================================
-- SAMPLE AIRPORTS
-- ============================================================

INSERT INTO airports
    (airport_code, name, city, country, timezone)
VALUES
    ('IKA', 'Imam Khomeini International Airport', 'Tehran', 'Iran', 'Asia/Tehran'),
    ('GYD', 'Heydar Aliyev International Airport', 'Baku', 'Azerbaijan', 'Asia/Baku'),
    ('IST', 'Istanbul Airport', 'Istanbul', 'Turkey', 'Europe/Istanbul');

-- ============================================================
-- SAMPLE TERMINALS
-- ============================================================

INSERT INTO terminals
    (airport_id, terminal_code, name)
VALUES
    (1, 'T1', 'International Terminal'),
    (1, 'T2', 'Main Terminal'),
    (2, 'T1', 'Main Terminal'),
    (3, 'T1', 'International Terminal');

-- ============================================================
-- SAMPLE GATES
-- ============================================================

INSERT INTO gates
    (terminal_id, gate_code, gate_type)
VALUES
    (1, 'A01', 'standard'),
    (1, 'A02', 'wide_body'),
    (2, 'B01', 'standard'),
    (3, 'C01', 'wide_body'),
    (3, 'C02', 'standard'),
    (4, 'D01', 'wide_body');

-- ============================================================
-- SAMPLE AIRLINES
-- ============================================================

INSERT INTO airlines
    (airline_code, name, country, contact_email, phone)
VALUES
    ('IR', 'Iran Air', 'Iran', 'contact@iranair.example', '+98-21-00000000'),
    ('J2', 'Azerbaijan Airlines', 'Azerbaijan', 'contact@azal.example', '+994-12-0000000'),
    ('TK', 'Turkish Airlines', 'Turkey', 'contact@thy.example', '+90-212-0000000');

-- ============================================================
-- SAMPLE AIRCRAFTS
-- ============================================================

INSERT INTO aircrafts
    (airline_id, registration_number, model, manufacturer, seat_capacity, manufacture_year)
VALUES
    (1, 'EP-ABC', 'Airbus A330-200', 'Airbus', 238, 2012),
    (2, '4K-AZ01', 'Airbus A320-200', 'Airbus', 180, 2018),
    (3, 'TC-JFA', 'Boeing 737-800', 'Boeing', 162, 2019);

-- ============================================================
-- SAMPLE ROUTES
-- ============================================================

INSERT INTO routes
    (origin_airport_id, destination_airport_id, distance_km)
VALUES
    (1, 2, 558.00),
    (2, 1, 558.00),
    (2, 3, 1760.00),
    (3, 2, 1760.00),
    (1, 3, 2040.00);

-- ============================================================
-- SAMPLE FLIGHTS
-- ============================================================

INSERT INTO flights
    (
        airline_id,
        aircraft_id,
        route_id,
        flight_number,
        departure_time,
        arrival_time,
        gate_id,
        terminal_id,
        base_fare,
        status
    )
VALUES
    (
        1,
        1,
        1,
        'IR750',
        '2026-09-15 08:00:00',
        '2026-09-15 09:30:00',
        1,
        1,
        180.00,
        'scheduled'
    ),
    (
        2,
        2,
        3,
        'J2201',
        '2026-09-15 12:00:00',
        '2026-09-15 14:45:00',
        4,
        3,
        240.00,
        'scheduled'
    ),
    (
        3,
        3,
        4,
        'TK330',
        '2026-09-16 16:30:00',
        '2026-09-16 20:00:00',
        6,
        4,
        265.00,
        'scheduled'
    ),
    (
        2,
        2,
        2,
        'J2202',
        '2026-09-17 10:00:00',
        '2026-09-17 11:30:00',
        5,
        3,
        175.00,
        'scheduled'
    ),
    (
        3,
        3,
        5,
        'TK331',
        '2026-09-18 07:30:00',
        '2026-09-18 10:45:00',
        2,
        1,
        290.00,
        'scheduled'
    );

-- ============================================================
-- SAMPLE PASSENGERS
-- ============================================================

INSERT INTO passengers
    (
        passport_number,
        first_name,
        last_name,
        date_of_birth,
        nationality,
        email,
        phone
    )
VALUES
    (
        'P12345678',
        'Ali',
        'Karimi',
        '1998-04-12',
        'Iranian',
        'ali.karimi@example.com',
        '+989120000001'
    ),
    (
        'P23456789',
        'Sara',
        'Ahmadi',
        '2000-08-21',
        'Iranian',
        'sara.ahmadi@example.com',
        '+989120000002'
    ),
    (
        'AZ3456789',
        'Leyla',
        'Mammadova',
        '1995-02-15',
        'Azerbaijani',
        'leyla.m@example.com',
        '+994500000003'
    ),
    (
        'TR4567890',
        'Mehmet',
        'Demir',
        '1992-11-03',
        'Turkish',
        'mehmet.demir@example.com',
        '+905300000004'
    ),
    (
        'P56789012',
        'Reza',
        'Hosseini',
        '1988-06-29',
        'Iranian',
        'reza.h@example.com',
        '+989120000005'
    );

-- ============================================================
-- SAMPLE EMPLOYEES
-- ============================================================

INSERT INTO employees
    (
        airport_id,
        employee_number,
        first_name,
        last_name,
        job_title,
        department,
        email,
        phone,
        hire_date
    )
VALUES
    (
        1,
        'EMP-1001',
        'Nima',
        'Rahimi',
        'Check-in Agent',
        'Passenger Services',
        'nima.rahimi@example.com',
        '+989120001001',
        '2023-05-10'
    ),
    (
        2,
        'EMP-2001',
        'Aysel',
        'Aliyeva',
        'Check-in Agent',
        'Passenger Services',
        'aysel.aliyeva@example.com',
        '+994500001002',
        '2022-09-15'
    ),
    (
        3,
        'EMP-3001',
        'Emre',
        'Kaya',
        'Ground Operations Officer',
        'Ground Operations',
        'emre.kaya@example.com',
        '+905300001003',
        '2021-03-20'
    );

-- ============================================================
-- SAMPLE BOOKINGS
-- ============================================================

INSERT INTO bookings
    (
        booking_reference,
        passenger_id,
        flight_id,
        booking_date,
        booking_status,
        total_amount
    )
VALUES
    (
        'BK100001',
        1,
        1,
        '2026-09-01 10:15:00',
        'confirmed',
        200.00
    ),
    (
        'BK100002',
        2,
        1,
        '2026-09-02 13:20:00',
        'checked_in',
        200.00
    ),
    (
        'BK100003',
        3,
        2,
        '2026-09-03 09:45:00',
        'confirmed',
        260.00
    ),
    (
        'BK100004',
        4,
        3,
        '2026-09-04 16:00:00',
        'reserved',
        285.00
    ),
    (
        'BK100005',
        5,
        5,
        '2026-09-05 18:30:00',
        'confirmed',
        310.00
    );

-- ============================================================
-- SAMPLE TICKETS
-- ============================================================

INSERT INTO tickets
    (
        booking_id,
        ticket_number,
        seat_number,
        cabin_class,
        ticket_price
    )
VALUES
    (1, 'TKT-100001', '12A', 'economy', 200.00),
    (2, 'TKT-100002', '12B', 'economy', 200.00),
    (3, 'TKT-100003', '08C', 'economy', 260.00),
    (4, 'TKT-100004', '05A', 'business', 285.00),
    (5, 'TKT-100005', '18D', 'economy', 310.00);

-- ============================================================
-- SAMPLE BAGGAGE
-- ============================================================

INSERT INTO baggage
    (
        booking_id,
        baggage_tag,
        weight_kg,
        baggage_type,
        status
    )
VALUES
    (1, 'BG100001', 18.50, 'checked', 'registered'),
    (2, 'BG100002', 21.20, 'checked', 'loaded'),
    (3, 'BG100003', 15.00, 'checked', 'registered'),
    (4, 'BG100004', 12.40, 'checked', 'registered'),
    (5, 'BG100005', 19.80, 'checked', 'registered');

-- ============================================================
-- SAMPLE CHECK-INS
-- ============================================================

INSERT INTO check_ins
    (
        booking_id,
        employee_id,
        check_in_time,
        boarding_pass_number
    )
VALUES
    (
        2,
        1,
        '2026-09-15 05:50:00',
        'BP100002'
    );

-- ============================================================
-- SAMPLE PAYMENTS
-- ============================================================

INSERT INTO payments
    (
        booking_id,
        payment_reference,
        amount,
        payment_method,
        payment_date,
        status
    )
VALUES
    (
        1,
        'PAY100001',
        200.00,
        'card',
        '2026-09-01 10:16:00',
        'completed'
    ),
    (
        2,
        'PAY100002',
        200.00,
        'online',
        '2026-09-02 13:21:00',
        'completed'
    ),
    (
        3,
        'PAY100003',
        260.00,
        'card',
        '2026-09-03 09:46:00',
        'completed'
    ),
    (
        5,
        'PAY100005',
        310.00,
        'bank_transfer',
        '2026-09-05 18:31:00',
        'completed'
    );

-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW airport_directory AS
SELECT
    airport_id,
    airport_code,
    name,
    city,
    country,
    timezone,
    status
FROM airports
WHERE status = 'active';

CREATE VIEW flight_schedule AS
SELECT
    f.flight_id,
    f.flight_number,
    al.name AS airline,
    ao.airport_code AS origin_code,
    ao.city AS origin_city,
    ad.airport_code AS destination_code,
    ad.city AS destination_city,
    f.departure_time,
    f.arrival_time,
    t.terminal_code,
    g.gate_code,
    f.base_fare,
    f.status
FROM flights f
JOIN airlines al
    ON al.airline_id = f.airline_id
JOIN routes r
    ON r.route_id = f.route_id
JOIN airports ao
    ON ao.airport_id = r.origin_airport_id
JOIN airports ad
    ON ad.airport_id = r.destination_airport_id
LEFT JOIN terminals t
    ON t.terminal_id = f.terminal_id
LEFT JOIN gates g
    ON g.gate_id = f.gate_id;

CREATE VIEW booking_details AS
SELECT
    b.booking_id,
    b.booking_reference,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    p.passport_number,
    f.flight_number,
    al.name AS airline,
    ao.airport_code AS origin,
    ad.airport_code AS destination,
    f.departure_time,
    f.arrival_time,
    b.booking_status,
    b.total_amount
FROM bookings b
JOIN passengers p
    ON p.passenger_id = b.passenger_id
JOIN flights f
    ON f.flight_id = b.flight_id
JOIN airlines al
    ON al.airline_id = f.airline_id
JOIN routes r
    ON r.route_id = f.route_id
JOIN airports ao
    ON ao.airport_id = r.origin_airport_id
JOIN airports ad
    ON ad.airport_id = r.destination_airport_id;

CREATE VIEW ticket_sales_summary AS
SELECT
    f.flight_id,
    f.flight_number,
    al.name AS airline,
    COUNT(t.ticket_id) AS tickets_sold,
    COALESCE(SUM(t.ticket_price), 0) AS ticket_revenue
FROM flights f
JOIN airlines al
    ON al.airline_id = f.airline_id
LEFT JOIN bookings b
    ON b.flight_id = f.flight_id
LEFT JOIN tickets t
    ON t.booking_id = b.booking_id
   AND t.ticket_status <> 'cancelled'
GROUP BY
    f.flight_id,
    f.flight_number,
    al.name;

CREATE VIEW baggage_tracking AS
SELECT
    bg.baggage_id,
    bg.baggage_tag,
    bg.weight_kg,
    bg.baggage_type,
    bg.status,
    b.booking_reference,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    f.flight_number
FROM baggage bg
JOIN bookings b
    ON b.booking_id = bg.booking_id
JOIN passengers p
    ON p.passenger_id = b.passenger_id
JOIN flights f
    ON f.flight_id = b.flight_id;

CREATE VIEW payment_summary AS
SELECT
    b.booking_reference,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    b.total_amount AS booking_amount,
    COALESCE(SUM(
        CASE
            WHEN py.status = 'completed'
            THEN py.amount
            ELSE 0
        END
    ), 0) AS paid_amount,
    b.total_amount - COALESCE(SUM(
        CASE
            WHEN py.status = 'completed'
            THEN py.amount
            ELSE 0
        END
    ), 0) AS remaining_amount
FROM bookings b
JOIN passengers p
    ON p.passenger_id = b.passenger_id
LEFT JOIN payments py
    ON py.booking_id = b.booking_id
GROUP BY
    b.booking_id,
    b.booking_reference,
    p.first_name,
    p.last_name,
    b.total_amount;

-- ============================================================
-- EXAMPLE QUERIES
-- ============================================================

-- Active airport directory
SELECT *
FROM airport_directory;

-- Upcoming flight schedule
SELECT *
FROM flight_schedule
WHERE departure_time >= NOW()
ORDER BY departure_time;

-- Confirmed passenger bookings
SELECT *
FROM booking_details
WHERE booking_status IN ('confirmed', 'checked_in')
ORDER BY departure_time;

-- Flight ticket sales
SELECT *
FROM ticket_sales_summary
ORDER BY ticket_revenue DESC;

-- Baggage tracking
SELECT *
FROM baggage_tracking
ORDER BY baggage_id;

-- Payment balances
SELECT *
FROM payment_summary
ORDER BY remaining_amount DESC;

-- Flights departing from a specific airport
SELECT
    f.flight_number,
    al.name AS airline,
    f.departure_time,
    ad.airport_code AS destination
FROM flights f
JOIN airlines al
    ON al.airline_id = f.airline_id
JOIN routes r
    ON r.route_id = f.route_id
JOIN airports ao
    ON ao.airport_id = r.origin_airport_id
JOIN airports ad
    ON ad.airport_id = r.destination_airport_id
WHERE ao.airport_code = 'IKA'
ORDER BY f.departure_time;

-- Total revenue by airline
SELECT
    al.name AS airline,
    COALESCE(SUM(t.ticket_price), 0) AS total_revenue
FROM airlines al
LEFT JOIN flights f
    ON f.airline_id = al.airline_id
LEFT JOIN bookings b
    ON b.flight_id = f.flight_id
LEFT JOIN tickets t
    ON t.booking_id = b.booking_id
   AND t.ticket_status <> 'cancelled'
GROUP BY
    al.airline_id,
    al.name
ORDER BY total_revenue DESC;