-- ============================================================

-- SQLFoundry - Cinema Management System

-- Database: MySQL 8.0+

-- File: cinema.sql

-- ============================================================

DROP DATABASE IF EXISTS cinema_db;

CREATE DATABASE cinema_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cinema_db;


-- ============================================================
-- Table: cinemas
-- ============================================================

CREATE TABLE cinemas (
    cinema_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cinema_code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_cinemas_city (city),
    INDEX idx_cinemas_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: halls
-- ============================================================

CREATE TABLE halls (
    hall_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cinema_id INT UNSIGNED NOT NULL,
    hall_number VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    capacity INT UNSIGNED NOT NULL,
    screen_type ENUM(
        'standard',
        'imax',
        '3d',
        '4dx'
    ) NOT NULL DEFAULT 'standard',
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_halls_cinema
        FOREIGN KEY (cinema_id)
        REFERENCES cinemas(cinema_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_hall_capacity
        CHECK (capacity > 0),

    UNIQUE (
        cinema_id,
        hall_number
    ),

    INDEX idx_halls_cinema (cinema_id),
    INDEX idx_halls_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: seats
-- ============================================================

CREATE TABLE seats (
    seat_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    hall_id INT UNSIGNED NOT NULL,
    row_label VARCHAR(10) NOT NULL,
    seat_number INT UNSIGNED NOT NULL,
    seat_type ENUM(
        'standard',
        'premium',
        'accessible'
    ) NOT NULL DEFAULT 'standard',
    status ENUM(
        'available',
        'maintenance',
        'disabled'
    ) NOT NULL DEFAULT 'available',

    CONSTRAINT fk_seats_hall
        FOREIGN KEY (hall_id)
        REFERENCES halls(hall_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_seat_number
        CHECK (seat_number > 0),

    UNIQUE (
        hall_id,
        row_label,
        seat_number
    ),

    INDEX idx_seats_hall (hall_id),
    INDEX idx_seats_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: genres
-- ============================================================

CREATE TABLE genres (
    genre_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;


-- ============================================================
-- Table: movies
-- ============================================================

CREATE TABLE movies (
    movie_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    original_title VARCHAR(200),
    description TEXT,
    release_date DATE,
    duration_minutes INT UNSIGNED NOT NULL,
    age_rating VARCHAR(20),
    language VARCHAR(50) NOT NULL,
    country VARCHAR(100),
    director VARCHAR(150),
    status ENUM(
        'upcoming',
        'now_showing',
        'ended'
    ) NOT NULL DEFAULT 'upcoming',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_movie_duration
        CHECK (duration_minutes > 0),

    INDEX idx_movies_title (title),
    INDEX idx_movies_release_date (release_date),
    INDEX idx_movies_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: movie_genres
-- ============================================================

CREATE TABLE movie_genres (
    movie_id INT UNSIGNED NOT NULL,
    genre_id INT UNSIGNED NOT NULL,

    PRIMARY KEY (
        movie_id,
        genre_id
    ),

    CONSTRAINT fk_movie_genres_movie
        FOREIGN KEY (movie_id)
        REFERENCES movies(movie_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_movie_genres_genre
        FOREIGN KEY (genre_id)
        REFERENCES genres(genre_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
-- Table: customers
-- ============================================================

CREATE TABLE customers (
    customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    date_of_birth DATE,
    registration_date DATE NOT NULL,
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
-- Table: showtimes
-- ============================================================

CREATE TABLE showtimes (
    showtime_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    movie_id INT UNSIGNED NOT NULL,
    hall_id INT UNSIGNED NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    ticket_price DECIMAL(10,2) NOT NULL,
    language VARCHAR(50),
    format ENUM(
        '2d',
        '3d',
        'imax',
        '4dx'
    ) NOT NULL DEFAULT '2d',
    status ENUM(
        'scheduled',
        'cancelled',
        'completed'
    ) NOT NULL DEFAULT 'scheduled',

    CONSTRAINT fk_showtimes_movie
        FOREIGN KEY (movie_id)
        REFERENCES movies(movie_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_showtimes_hall
        FOREIGN KEY (hall_id)
        REFERENCES halls(hall_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_showtime_dates
        CHECK (end_time > start_time),

    CONSTRAINT chk_showtime_price
        CHECK (ticket_price > 0),

    INDEX idx_showtimes_movie (movie_id),
    INDEX idx_showtimes_hall (hall_id),
    INDEX idx_showtimes_start (start_time),
    INDEX idx_showtimes_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: bookings
-- ============================================================

CREATE TABLE bookings (
    booking_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT UNSIGNED NOT NULL,
    showtime_id BIGINT UNSIGNED NOT NULL,
    booking_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(12,2) NOT NULL,
    status ENUM(
        'pending',
        'confirmed',
        'cancelled',
        'completed'
    ) NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_bookings_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_bookings_showtime
        FOREIGN KEY (showtime_id)
        REFERENCES showtimes(showtime_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_booking_total
        CHECK (total_amount >= 0),

    INDEX idx_bookings_customer (customer_id),
    INDEX idx_bookings_showtime (showtime_id),
    INDEX idx_bookings_date (booking_date),
    INDEX idx_bookings_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: tickets
-- ============================================================

CREATE TABLE tickets (
    ticket_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
    seat_id INT UNSIGNED NOT NULL,
    ticket_number VARCHAR(50) NOT NULL UNIQUE,
    ticket_type ENUM(
        'adult',
        'child',
        'student',
        'senior'
    ) NOT NULL DEFAULT 'adult',
    price DECIMAL(10,2) NOT NULL,
    status ENUM(
        'reserved',
        'paid',
        'used',
        'cancelled'
    ) NOT NULL DEFAULT 'reserved',

    CONSTRAINT fk_tickets_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_tickets_seat
        FOREIGN KEY (seat_id)
        REFERENCES seats(seat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_ticket_price
        CHECK (price >= 0),

    UNIQUE (
        booking_id,
        seat_id
    ),

    INDEX idx_tickets_booking (booking_id),
    INDEX idx_tickets_seat (seat_id),
    INDEX idx_tickets_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    booking_id BIGINT UNSIGNED NOT NULL,
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

    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id)
        REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_booking (booking_id),
    INDEX idx_payments_date (payment_date),
    INDEX idx_payments_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO cinemas
    (cinema_code, name, address, city, phone, status)
VALUES
    ('CIN-001', 'Grand Cinema', '100 Central Avenue',
     'New York', '+1-555-5001', 'active'),

    ('CIN-002', 'Metro Cinema', '25 Market Street',
     'Chicago', '+1-555-5002', 'active');


INSERT INTO halls
    (cinema_id, hall_number, name, capacity, screen_type, status)
VALUES
    (1, 'H1', 'Main Hall', 120, 'standard', 'active'),
    (1, 'H2', 'IMAX Hall', 180, 'imax', 'active'),
    (2, 'H1', 'Premium Hall', 100, 'standard', 'active');


INSERT INTO seats
    (hall_id, row_label, seat_number, seat_type, status)
VALUES
    (1, 'A', 1, 'premium', 'available'),
    (1, 'A', 2, 'premium', 'available'),
    (1, 'A', 3, 'standard', 'available'),
    (1, 'A', 4, 'standard', 'available'),
    (1, 'B', 1, 'standard', 'available'),
    (1, 'B', 2, 'standard', 'available'),
    (1, 'B', 3, 'standard', 'available'),
    (1, 'B', 4, 'accessible', 'available'),

    (2, 'A', 1, 'premium', 'available'),
    (2, 'A', 2, 'premium', 'available'),
    (2, 'A', 3, 'premium', 'available'),
    (2, 'A', 4, 'standard', 'available'),

    (3, 'A', 1, 'premium', 'available'),
    (3, 'A', 2, 'premium', 'available'),
    (3, 'A', 3, 'standard', 'available'),
    (3, 'A', 4, 'standard', 'available');


INSERT INTO genres
    (name, description)
VALUES
    ('Action', 'Action and adventure films.'),
    ('Drama', 'Drama and character-driven films.'),
    ('Science Fiction', 'Science fiction and futuristic films.'),
    ('Comedy', 'Comedy and humorous films.'),
    ('Thriller', 'Suspense and thriller films.');


INSERT INTO movies
    (title, original_title, description, release_date,
     duration_minutes, age_rating, language, country,
     director, status)
VALUES
    ('The Last Horizon',
     'The Last Horizon',
     'A crew searches for a new home beyond the solar system.',
     '2026-08-15', 138, 'PG-13', 'English',
     'USA', 'Daniel Carter', 'now_showing'),

    ('Silent City',
     'Silent City',
     'A detective investigates a mysterious disappearance.',
     '2026-08-22', 121, 'PG-13', 'English',
     'USA', 'Michael Stone', 'now_showing'),

    ('Second Chance',
     'Second Chance',
     'A dramatic story about rebuilding a broken life.',
     '2026-09-20', 112, 'PG', 'English',
     'USA', 'Sarah Mitchell', 'upcoming'),

    ('Weekend Trouble',
     'Weekend Trouble',
     'Four friends experience an unforgettable weekend.',
     '2026-07-10', 105, 'PG-13', 'English',
     'USA', 'James Cooper', 'ended');


INSERT INTO movie_genres
    (movie_id, genre_id)
VALUES
    (1, 1),
    (1, 3),
    (2, 2),
    (2, 5),
    (3, 2),
    (4, 4);


INSERT INTO customers
    (customer_number, first_name, last_name,
     email, phone, date_of_birth,
     registration_date, status)
VALUES
    ('CUS-50001', 'Alex', 'Morgan',
     'alex.morgan@example.com',
     '+1-555-6001', '1994-05-12',
     '2026-01-15', 'active'),

    ('CUS-50002', 'Emily', 'Clark',
     'emily.clark@example.com',
     '+1-555-6002', '1998-08-24',
     '2026-02-10', 'active'),

    ('CUS-50003', 'David', 'Walker',
     'david.walker@example.com',
     '+1-555-6003', '1989-11-05',
     '2026-03-20', 'active'),

    ('CUS-50004', 'Olivia', 'Harris',
     'olivia.harris@example.com',
     '+1-555-6004', '1996-02-18',
     '2026-04-01', 'active');


INSERT INTO showtimes
    (movie_id, hall_id, start_time, end_time,
     ticket_price, language, format, status)
VALUES
    (1, 1,
     '2026-09-10 18:00:00',
     '2026-09-10 20:18:00',
     14.00, 'English', '2d', 'scheduled'),

    (1, 2,
     '2026-09-10 21:00:00',
     '2026-09-10 23:18:00',
     24.00, 'English', 'imax', 'scheduled'),

    (2, 1,
     '2026-09-10 20:45:00',
     '2026-09-10 22:46:00',
     13.00, 'English', '2d', 'scheduled'),

    (3, 3,
     '2026-09-21 19:00:00',
     '2026-09-21 20:52:00',
     12.00, 'English', '2d', 'scheduled'),

    (4, 3,
     '2026-08-01 17:30:00',
     '2026-08-01 19:15:00',
     10.00, 'English', '2d', 'completed');


INSERT INTO bookings
    (booking_number, customer_id, showtime_id,
     booking_date, total_amount, status)
VALUES
    ('BKG-10001', 1, 1,
     '2026-09-09 10:15:00',
     28.00, 'confirmed'),

    ('BKG-10002', 2, 2,
     '2026-09-09 11:20:00',
     48.00, 'confirmed'),

    ('BKG-10003', 3, 3,
     '2026-09-09 12:05:00',
     13.00, 'confirmed'),

    ('BKG-10004', 4, 5,
     '2026-07-31 16:00:00',
     20.00, 'completed');


INSERT INTO tickets
    (booking_id, seat_id, ticket_number,
     ticket_type, price, status)
VALUES
    (1, 1, 'TKT-10001', 'adult', 14.00, 'paid'),
    (1, 2, 'TKT-10002', 'adult', 14.00, 'paid'),

    (2, 9, 'TKT-10003', 'adult', 24.00, 'paid'),
    (2, 10, 'TKT-10004', 'adult', 24.00, 'paid'),

    (3, 3, 'TKT-10005', 'adult', 13.00, 'paid'),

    (4, 13, 'TKT-10006', 'adult', 10.00, 'used'),
    (4, 14, 'TKT-10007', 'adult', 10.00, 'used');


INSERT INTO payments
    (booking_id, payment_reference, amount,
     payment_method, payment_date, status)
VALUES
    (1, 'PAY-50001', 28.00,
     'credit_card', '2026-09-09 10:16:00', 'completed'),

    (2, 'PAY-50002', 48.00,
     'online', '2026-09-09 11:21:00', 'completed'),

    (3, 'PAY-50003', 13.00,
     'debit_card', '2026-09-09 12:06:00', 'completed'),

    (4, 'PAY-50004', 20.00,
     'credit_card', '2026-07-31 16:01:00', 'completed');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW movie_catalog AS
SELECT
    m.movie_id,
    m.title,
    m.original_title,
    m.duration_minutes,
    m.age_rating,
    m.language,
    m.country,
    m.director,
    m.release_date,
    m.status,
    GROUP_CONCAT(
        g.name
        ORDER BY g.name
        SEPARATOR ', '
    ) AS genres
FROM movies m
LEFT JOIN movie_genres mg
    ON m.movie_id = mg.movie_id
LEFT JOIN genres g
    ON mg.genre_id = g.genre_id
GROUP BY
    m.movie_id,
    m.title,
    m.original_title,
    m.duration_minutes,
    m.age_rating,
    m.language,
    m.country,
    m.director,
    m.release_date,
    m.status;


CREATE VIEW showtime_schedule AS
SELECT
    s.showtime_id,
    c.name AS cinema_name,
    c.city,
    h.hall_number,
    h.name AS hall_name,
    h.screen_type,
    m.title AS movie_title,
    s.start_time,
    s.end_time,
    s.ticket_price,
    s.language,
    s.format,
    s.status
FROM showtimes s
JOIN movies m
    ON s.movie_id = m.movie_id
JOIN halls h
    ON s.hall_id = h.hall_id
JOIN cinemas c
    ON h.cinema_id = c.cinema_id;


CREATE VIEW booking_details AS
SELECT
    b.booking_id,
    b.booking_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    m.title AS movie_title,
    ci.name AS cinema_name,
    h.hall_number,
    s.start_time,
    COUNT(t.ticket_id) AS ticket_count,
    b.total_amount,
    b.status
FROM bookings b
JOIN customers c
    ON b.customer_id = c.customer_id
JOIN showtimes s
    ON b.showtime_id = s.showtime_id
JOIN movies m
    ON s.movie_id = m.movie_id
JOIN halls h
    ON s.hall_id = h.hall_id
JOIN cinemas ci
    ON h.cinema_id = ci.cinema_id
LEFT JOIN tickets t
    ON b.booking_id = t.booking_id
GROUP BY
    b.booking_id,
    b.booking_number,
    c.first_name,
    c.last_name,
    m.title,
    ci.name,
    h.hall_number,
    s.start_time,
    b.total_amount,
    b.status;


CREATE VIEW ticket_sales_summary AS
SELECT
    m.title AS movie_title,
    COUNT(t.ticket_id) AS tickets_sold,
    COALESCE(
        SUM(
            CASE
                WHEN t.status IN ('paid', 'used')
                THEN t.price
                ELSE 0
            END
        ),
        0
    ) AS ticket_revenue
FROM tickets t
JOIN bookings b
    ON t.booking_id = b.booking_id
JOIN showtimes s
    ON b.showtime_id = s.showtime_id
JOIN movies m
    ON s.movie_id = m.movie_id
GROUP BY
    m.movie_id,
    m.title;


CREATE VIEW payment_summary AS
SELECT
    b.booking_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    b.total_amount AS booking_total,
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
    b.total_amount -
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
FROM bookings b
JOIN customers c
    ON b.customer_id = c.customer_id
LEFT JOIN payments p
    ON b.booking_id = p.booking_id
GROUP BY
    b.booking_id,
    b.booking_number,
    c.first_name,
    c.last_name,
    b.total_amount;


CREATE VIEW cinema_revenue_summary AS
SELECT
    ci.cinema_id,
    ci.name AS cinema_name,
    ci.city,
    COUNT(DISTINCT s.showtime_id) AS showtime_count,
    COUNT(t.ticket_id) AS ticket_count,
    COALESCE(
        SUM(
            CASE
                WHEN t.status IN ('paid', 'used')
                THEN t.price
                ELSE 0
            END
        ),
        0
    ) AS ticket_revenue
FROM cinemas ci
JOIN halls h
    ON ci.cinema_id = h.cinema_id
LEFT JOIN showtimes s
    ON h.hall_id = s.hall_id
LEFT JOIN bookings b
    ON s.showtime_id = b.showtime_id
LEFT JOIN tickets t
    ON b.booking_id = t.booking_id
GROUP BY
    ci.cinema_id,
    ci.name,
    ci.city;


-- ============================================================
-- Example Queries
-- ============================================================

-- Show currently available movies
SELECT *
FROM movie_catalog
WHERE status = 'now_showing'
ORDER BY title;


-- Show upcoming movies
SELECT
    title,
    release_date,
    duration_minutes,
    director
FROM movies
WHERE status = 'upcoming'
ORDER BY release_date;


-- Show today's cinema schedule
SELECT *
FROM showtime_schedule
WHERE DATE(start_time) = '2026-09-10'
ORDER BY start_time;


-- Find IMAX showtimes
SELECT *
FROM showtime_schedule
WHERE format = 'imax'
ORDER BY start_time;


-- Show all confirmed bookings
SELECT *
FROM booking_details
WHERE status = 'confirmed'
ORDER BY start_time;


-- Show ticket sales by movie
SELECT *
FROM ticket_sales_summary
ORDER BY ticket_revenue DESC;


-- Show cinema revenue
SELECT *
FROM cinema_revenue_summary
ORDER BY ticket_revenue DESC;


-- Show payment status for every booking
SELECT *
FROM payment_summary
ORDER BY remaining_amount DESC;


-- Find customers with the highest number of bookings
SELECT
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(b.booking_id) AS booking_count,
    COALESCE(SUM(b.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN bookings b
    ON c.customer_id = b.customer_id
GROUP BY
    c.customer_id,
    c.customer_number,
    c.first_name,
    c.last_name
ORDER BY booking_count DESC, total_spent DESC;


-- Count tickets sold by ticket type
SELECT
    ticket_type,
    COUNT(*) AS ticket_count,
    SUM(price) AS total_revenue
FROM tickets
WHERE status IN ('paid', 'used')
GROUP BY ticket_type
ORDER BY total_revenue DESC;


-- Show seat availability for a specific hall
SELECT
    h.name AS hall_name,
    s.row_label,
    s.seat_number,
    s.seat_type,
    s.status
FROM seats s
JOIN halls h
    ON s.hall_id = h.hall_id
WHERE h.hall_id = 1
ORDER BY s.row_label, s.seat_number;


-- Most popular movies by ticket count
SELECT
    m.title,
    COUNT(t.ticket_id) AS tickets_sold
FROM movies m
JOIN showtimes s
    ON m.movie_id = s.movie_id
JOIN bookings b
    ON s.showtime_id = b.showtime_id
JOIN tickets t
    ON b.booking_id = t.booking_id
WHERE t.status IN ('paid', 'used')
GROUP BY
    m.movie_id,
    m.title
ORDER BY tickets_sold DESC;


-- Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'completed'
GROUP BY payment_method
ORDER BY total_revenue DESC;