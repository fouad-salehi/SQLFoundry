-- ============================================================

-- SQLFoundry - Gym Management System

-- Database: MySQL 8.0+

-- File: gym.sql

-- ============================================================

DROP DATABASE IF EXISTS gym_db;

CREATE DATABASE gym_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE gym_db;

-- ============================================================
-- MEMBERS
-- ============================================================

CREATE TABLE members (
    member_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) UNIQUE,
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other'),
    join_date DATE NOT NULL,
    status ENUM('active', 'inactive', 'suspended') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TRAINERS
-- ============================================================

CREATE TABLE trainers (
    trainer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30) UNIQUE,
    specialization VARCHAR(150),
    hire_date DATE NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- MEMBERSHIP PLANS
-- ============================================================

CREATE TABLE membership_plans (
    plan_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    duration_days INT UNSIGNED NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',

    CONSTRAINT chk_plan_duration
        CHECK (duration_days > 0),

    CONSTRAINT chk_plan_price
        CHECK (price >= 0)
);

-- ============================================================
-- MEMBERSHIPS
-- ============================================================

CREATE TABLE memberships (
    membership_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNSIGNED NOT NULL,
    plan_id INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'expired', 'cancelled', 'pending')
        NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_memberships_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_memberships_plan
        FOREIGN KEY (plan_id)
        REFERENCES membership_plans(plan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_membership_dates
        CHECK (end_date >= start_date),

    INDEX idx_memberships_member (member_id),
    INDEX idx_memberships_dates (start_date, end_date),
    INDEX idx_memberships_status (status)
);

-- ============================================================
-- PAYMENTS
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNSIGNED NOT NULL,
    membership_id INT UNSIGNED,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_method ENUM('cash', 'card', 'bank_transfer', 'online')
        NOT NULL,
    status ENUM('completed', 'pending', 'failed', 'refunded')
        NOT NULL DEFAULT 'completed',
    reference_number VARCHAR(100) UNIQUE,
    notes TEXT,

    CONSTRAINT fk_payments_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_payments_membership
        FOREIGN KEY (membership_id)
        REFERENCES memberships(membership_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    INDEX idx_payments_member (member_id),
    INDEX idx_payments_date (payment_date),
    INDEX idx_payments_status (status)
);

-- ============================================================
-- CLASSES
-- ============================================================

CREATE TABLE classes (
    class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    trainer_id INT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    capacity INT UNSIGNED NOT NULL DEFAULT 20,
    duration_minutes INT UNSIGNED NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',

    CONSTRAINT fk_classes_trainer
        FOREIGN KEY (trainer_id)
        REFERENCES trainers(trainer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_class_capacity
        CHECK (capacity > 0),

    CONSTRAINT chk_class_duration
        CHECK (duration_minutes > 0),

    INDEX idx_classes_trainer (trainer_id),
    INDEX idx_classes_status (status)
);

-- ============================================================
-- CLASS SCHEDULES
-- ============================================================

CREATE TABLE class_schedules (
    schedule_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id INT UNSIGNED NOT NULL,
    day_of_week ENUM(
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
        'sunday'
    ) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room VARCHAR(100),

    CONSTRAINT fk_class_schedules_class
        FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_schedule_time
        CHECK (end_time > start_time),

    INDEX idx_class_schedules_class (class_id),
    INDEX idx_class_schedules_day (day_of_week)
);

-- ============================================================
-- CLASS ENROLLMENTS
-- ============================================================

CREATE TABLE class_enrollments (
    enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id INT UNSIGNED NOT NULL,
    member_id INT UNSIGNED NOT NULL,
    enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('enrolled', 'cancelled', 'completed')
        NOT NULL DEFAULT 'enrolled',

    CONSTRAINT fk_class_enrollments_class
        FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_class_enrollments_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT uq_class_member
        UNIQUE (class_id, member_id),

    INDEX idx_class_enrollments_member (member_id),
    INDEX idx_class_enrollments_status (status)
);

-- ============================================================
-- ATTENDANCE
-- ============================================================

CREATE TABLE attendance (
    attendance_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNSIGNED NOT NULL,
    class_id INT UNSIGNED,
    attendance_date DATE NOT NULL,
    check_in_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_time DATETIME,
    status ENUM('present', 'late', 'absent') NOT NULL DEFAULT 'present',
    notes TEXT,

    CONSTRAINT fk_attendance_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_attendance_class
        FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_attendance_checkout
        CHECK (
            check_out_time IS NULL
            OR check_out_time >= check_in_time
        ),

    INDEX idx_attendance_member (member_id),
    INDEX idx_attendance_date (attendance_date),
    INDEX idx_attendance_class (class_id)
);

-- ============================================================
-- EXERCISES
-- ============================================================

CREATE TABLE exercises (
    exercise_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    muscle_group VARCHAR(100) NOT NULL,
    equipment VARCHAR(100),
    difficulty ENUM('beginner', 'intermediate', 'advanced')
        NOT NULL DEFAULT 'beginner',
    instructions TEXT
);

-- ============================================================
-- WORKOUT PLANS
-- ============================================================

CREATE TABLE workout_plans (
    workout_plan_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    member_id INT UNSIGNED NOT NULL,
    trainer_id INT UNSIGNED,
    name VARCHAR(150) NOT NULL,
    goal VARCHAR(150),
    start_date DATE NOT NULL,
    end_date DATE,
    status ENUM('active', 'completed', 'cancelled')
        NOT NULL DEFAULT 'active',
    notes TEXT,

    CONSTRAINT fk_workout_plans_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_workout_plans_trainer
        FOREIGN KEY (trainer_id)
        REFERENCES trainers(trainer_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_workout_plan_dates
        CHECK (
            end_date IS NULL
            OR end_date >= start_date
        ),

    INDEX idx_workout_plans_member (member_id),
    INDEX idx_workout_plans_trainer (trainer_id),
    INDEX idx_workout_plans_status (status)
);

-- ============================================================
-- WORKOUT PLAN EXERCISES
-- ============================================================

CREATE TABLE workout_plan_exercises (
    workout_plan_exercise_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    workout_plan_id INT UNSIGNED NOT NULL,
    exercise_id INT UNSIGNED NOT NULL,
    sets INT UNSIGNED NOT NULL,
    repetitions INT UNSIGNED,
    duration_seconds INT UNSIGNED,
    rest_seconds INT UNSIGNED DEFAULT 60,
    weight_kg DECIMAL(6, 2),
    notes TEXT,

    CONSTRAINT fk_workout_plan_exercises_plan
        FOREIGN KEY (workout_plan_id)
        REFERENCES workout_plans(workout_plan_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_workout_plan_exercises_exercise
        FOREIGN KEY (exercise_id)
        REFERENCES exercises(exercise_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_workout_sets
        CHECK (sets > 0),

    CONSTRAINT chk_workout_repetitions
        CHECK (
            repetitions IS NULL
            OR repetitions > 0
        ),

    CONSTRAINT chk_workout_duration
        CHECK (
            duration_seconds IS NULL
            OR duration_seconds > 0
        ),

    CONSTRAINT chk_workout_weight
        CHECK (
            weight_kg IS NULL
            OR weight_kg >= 0
        ),

    INDEX idx_workout_plan_exercises_plan (workout_plan_id),
    INDEX idx_workout_plan_exercises_exercise (exercise_id)
);

-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO members
    (first_name, last_name, email, phone, date_of_birth, gender, join_date, status)
VALUES
    ('James', 'Carter', 'james.carter@example.com', '+15550010001', '1998-04-12', 'male', '2026-01-10', 'active'),
    ('Emma', 'Wilson', 'emma.wilson@example.com', '+15550010002', '2001-08-23', 'female', '2026-02-15', 'active'),
    ('Michael', 'Brown', 'michael.brown@example.com', '+15550010003', '1995-11-05', 'male', '2026-03-01', 'active'),
    ('Sophia', 'Taylor', 'sophia.taylor@example.com', '+15550010004', '2000-06-17', 'female', '2026-03-20', 'active'),
    ('Daniel', 'Miller', 'daniel.miller@example.com', '+15550010005', '1992-02-28', 'male', '2026-04-05', 'suspended'),
    ('Olivia', 'Davis', 'olivia.davis@example.com', '+15550010006', '1999-09-14', 'female', '2026-04-22', 'active');

INSERT INTO trainers
    (first_name, last_name, email, phone, specialization, hire_date, status)
VALUES
    ('Alex', 'Johnson', 'alex.johnson@example.com', '+15550020001', 'Strength Training', '2024-01-15', 'active'),
    ('Sarah', 'Anderson', 'sarah.anderson@example.com', '+15550020002', 'Yoga and Mobility', '2024-06-10', 'active'),
    ('David', 'Thomas', 'david.thomas@example.com', '+15550020003', 'Boxing and Conditioning', '2025-02-01', 'active'),
    ('Laura', 'Martinez', 'laura.martinez@example.com', '+15550020004', 'Weight Loss', '2025-05-18', 'active');

INSERT INTO membership_plans
    (name, duration_days, price, description, status)
VALUES
    ('Monthly', 30, 49.99, 'Standard one-month gym membership.', 'active'),
    ('Quarterly', 90, 129.99, 'Three-month membership with discounted pricing.', 'active'),
    ('Semi-Annual', 180, 229.99, 'Six-month gym membership.', 'active'),
    ('Annual', 365, 399.99, 'Full-year gym membership.', 'active'),
    ('Day Pass', 1, 10.00, 'Single-day gym access.', 'active');

INSERT INTO memberships
    (member_id, plan_id, start_date, end_date, status)
VALUES
    (1, 4, '2026-01-10', '2027-01-09', 'active'),
    (2, 2, '2026-02-15', '2026-05-15', 'expired'),
    (3, 3, '2026-03-01', '2026-08-27', 'expired'),
    (4, 1, '2026-03-20', '2026-04-18', 'expired'),
    (5, 2, '2026-04-05', '2026-07-03', 'expired'),
    (6, 4, '2026-04-22', '2027-04-21', 'active');

INSERT INTO payments
    (member_id, membership_id, amount, payment_date, payment_method, status, reference_number, notes)
VALUES
    (1, 1, 399.99, '2026-01-10 10:30:00', 'card', 'completed', 'PAY-100001', 'Annual membership payment.'),
    (2, 2, 129.99, '2026-02-15 11:15:00', 'cash', 'completed', 'PAY-100002', 'Quarterly membership payment.'),
    (3, 3, 229.99, '2026-03-01 09:45:00', 'bank_transfer', 'completed', 'PAY-100003', 'Semi-annual membership payment.'),
    (4, 4, 49.99, '2026-03-20 18:20:00', 'card', 'completed', 'PAY-100004', 'Monthly membership payment.'),
    (5, 5, 129.99, '2026-04-05 12:10:00', 'cash', 'completed', 'PAY-100005', 'Quarterly membership payment.'),
    (6, 6, 399.99, '2026-04-22 14:35:00', 'online', 'completed', 'PAY-100006', 'Annual membership payment.');

INSERT INTO classes
    (trainer_id, name, description, capacity, duration_minutes, status)
VALUES
    (1, 'Strength Training', 'Full-body strength and resistance training.', 15, 60, 'active'),
    (2, 'Yoga', 'Mobility, flexibility, and controlled breathing.', 20, 60, 'active'),
    (3, 'Boxing Conditioning', 'Boxing drills combined with cardiovascular conditioning.', 12, 75, 'active'),
    (4, 'Fat Loss Circuit', 'High-intensity circuit training for general fitness.', 18, 45, 'active');

INSERT INTO class_schedules
    (class_id, day_of_week, start_time, end_time, room)
VALUES
    (1, 'monday', '18:00:00', '19:00:00', 'Room A'),
    (1, 'wednesday', '18:00:00', '19:00:00', 'Room A'),
    (2, 'tuesday', '17:30:00', '18:30:00', 'Room B'),
    (2, 'thursday', '17:30:00', '18:30:00', 'Room B'),
    (3, 'saturday', '16:00:00', '17:15:00', 'Combat Room'),
    (4, 'monday', '19:30:00', '20:15:00', 'Room C'),
    (4, 'friday', '18:30:00', '19:15:00', 'Room C');

INSERT INTO class_enrollments
    (class_id, member_id, enrolled_at, status)
VALUES
    (1, 1, '2026-05-01 10:00:00', 'enrolled'),
    (1, 3, '2026-05-02 11:30:00', 'enrolled'),
    (2, 2, '2026-05-03 09:15:00', 'enrolled'),
    (2, 4, '2026-05-04 13:20:00', 'enrolled'),
    (3, 1, '2026-05-05 15:40:00', 'enrolled'),
    (3, 3, '2026-05-06 12:00:00', 'enrolled'),
    (4, 6, '2026-05-07 17:10:00', 'enrolled'),
    (4, 2, '2026-05-08 14:25:00', 'completed');

INSERT INTO attendance
    (member_id, class_id, attendance_date, check_in_time, check_out_time, status, notes)
VALUES
    (1, 1, '2026-05-04', '2026-05-04 17:52:00', '2026-05-04 19:05:00', 'present', NULL),
    (3, 1, '2026-05-04', '2026-05-04 18:08:00', '2026-05-04 19:10:00', 'late', 'Arrived eight minutes late.'),
    (2, 2, '2026-05-05', '2026-05-05 17:25:00', '2026-05-05 18:35:00', 'present', NULL),
    (4, 2, '2026-05-05', '2026-05-05 17:35:00', '2026-05-05 18:40:00', 'present', NULL),
    (1, 3, '2026-05-09', '2026-05-09 15:55:00', '2026-05-09 17:20:00', 'present', NULL),
    (3, 3, '2026-05-09', '2026-05-09 16:12:00', '2026-05-09 17:25:00', 'late', 'Arrived after the scheduled start.'),
    (6, 4, '2026-05-11', '2026-05-11 19:20:00', '2026-05-11 20:20:00', 'present', NULL);

INSERT INTO exercises
    (name, muscle_group, equipment, difficulty, instructions)
VALUES
    ('Barbell Squat', 'Legs', 'Barbell', 'intermediate', 'Keep the spine neutral and descend under control.'),
    ('Bench Press', 'Chest', 'Barbell', 'intermediate', 'Lower the bar under control and press upward evenly.'),
    ('Deadlift', 'Back', 'Barbell', 'advanced', 'Maintain a neutral spine and drive through the floor.'),
    ('Pull-Up', 'Back', 'Pull-Up Bar', 'intermediate', 'Pull the body upward until the chin clears the bar.'),
    ('Push-Up', 'Chest', 'Bodyweight', 'beginner', 'Maintain a straight body line throughout the movement.'),
    ('Plank', 'Core', 'Bodyweight', 'beginner', 'Keep the body aligned while maintaining abdominal tension.'),
    ('Lunges', 'Legs', 'Dumbbells', 'beginner', 'Step forward and lower the body under control.'),
    ('Shoulder Press', 'Shoulders', 'Dumbbells', 'intermediate', 'Press the dumbbells overhead while keeping the core stable.'),
    ('Bicycle Crunch', 'Core', 'Bodyweight', 'beginner', 'Rotate the torso while alternating the legs.'),
    ('Burpees', 'Full Body', 'Bodyweight', 'advanced', 'Perform the movement continuously with controlled technique.');

INSERT INTO workout_plans
    (member_id, trainer_id, name, goal, start_date, end_date, status, notes)
VALUES
    (1, 1, 'Strength Foundation', 'Build strength and muscle', '2026-05-01', '2026-07-31', 'active', 'Three-day weekly strength program.'),
    (2, 2, 'Mobility Program', 'Improve mobility and flexibility', '2026-05-01', '2026-06-30', 'active', 'Focus on controlled movement and flexibility.'),
    (3, 3, 'Boxing Conditioning', 'Improve conditioning', '2026-05-05', '2026-08-05', 'active', 'Conditioning-focused training plan.'),
    (6, 4, 'Fat Loss Circuit', 'Improve cardiovascular fitness', '2026-05-10', NULL, 'active', 'Circuit-based general fitness plan.');

INSERT INTO workout_plan_exercises
    (workout_plan_id, exercise_id, sets, repetitions, duration_seconds, rest_seconds, weight_kg, notes)
VALUES
    (1, 1, 4, 8, NULL, 120, 80.00, 'Controlled repetitions.'),
    (1, 2, 4, 8, NULL, 120, 60.00, 'Maintain consistent technique.'),
    (1, 3, 3, 6, NULL, 150, 100.00, 'Focus on form.'),
    (1, 4, 3, 8, NULL, 90, NULL, 'Bodyweight pull-ups.'),
    (1, 6, 3, NULL, 60, 60, NULL, 'One-minute holds.'),
    (2, 5, 3, 12, NULL, 45, NULL, 'Slow and controlled.'),
    (2, 6, 3, NULL, 60, 45, NULL, 'Focus on breathing.'),
    (2, 9, 3, 15, NULL, 45, NULL, 'Controlled core movement.'),
    (3, 10, 5, 10, NULL, 60, NULL, 'Maintain high but sustainable intensity.'),
    (3, 5, 4, 15, NULL, 45, NULL, 'Conditioning circuit.'),
    (3, 6, 4, NULL, 60, 45, NULL, 'Core stability.'),
    (4, 7, 3, 12, NULL, 45, 12.00, 'Alternate legs.'),
    (4, 10, 3, 10, NULL, 60, NULL, 'Perform at controlled intensity.'),
    (4, 9, 3, 20, NULL, 45, NULL, 'Core finisher.');

-- ============================================================
-- VIEWS
-- ============================================================

CREATE VIEW active_memberships AS
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    mp.name AS membership_plan,
    ms.start_date,
    ms.end_date,
    ms.status
FROM memberships ms
JOIN members m
    ON m.member_id = ms.member_id
JOIN membership_plans mp
    ON mp.plan_id = ms.plan_id
WHERE ms.status = 'active';

CREATE VIEW member_payment_history AS
SELECT
    p.payment_id,
    p.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    p.amount,
    p.payment_date,
    p.payment_method,
    p.status,
    p.reference_number
FROM payments p
JOIN members m
    ON m.member_id = p.member_id;

CREATE VIEW class_roster AS
SELECT
    c.class_id,
    c.name AS class_name,
    CONCAT(t.first_name, ' ', t.last_name) AS trainer_name,
    ce.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    ce.enrolled_at,
    ce.status
FROM class_enrollments ce
JOIN classes c
    ON c.class_id = ce.class_id
JOIN trainers t
    ON t.trainer_id = c.trainer_id
JOIN members m
    ON m.member_id = ce.member_id
WHERE ce.status = 'enrolled';

CREATE VIEW member_attendance_summary AS
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    COUNT(a.attendance_id) AS total_visits,
    SUM(a.status = 'present') AS present_count,
    SUM(a.status = 'late') AS late_count,
    SUM(a.status = 'absent') AS absent_count
FROM members m
LEFT JOIN attendance a
    ON a.member_id = m.member_id
GROUP BY
    m.member_id,
    m.first_name,
    m.last_name;

-- ============================================================
-- EXAMPLE QUERIES
-- ============================================================

-- All members
SELECT *
FROM members;

-- Currently active memberships
SELECT *
FROM active_memberships;

-- Memberships that have expired
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    mp.name AS plan,
    ms.start_date,
    ms.end_date
FROM memberships ms
JOIN members m
    ON m.member_id = ms.member_id
JOIN membership_plans mp
    ON mp.plan_id = ms.plan_id
WHERE ms.end_date < CURDATE();

-- Members with memberships ending within 30 days
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    ms.end_date
FROM memberships ms
JOIN members m
    ON m.member_id = ms.member_id
WHERE ms.status = 'active'
  AND ms.end_date BETWEEN CURDATE()
                      AND DATE_ADD(CURDATE(), INTERVAL 30 DAY);

-- Total completed revenue
SELECT
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'completed';

-- Revenue grouped by payment method
SELECT
    payment_method,
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'completed'
GROUP BY payment_method;

-- Most active members
SELECT
    member_id,
    member_name,
    total_visits
FROM member_attendance_summary
ORDER BY total_visits DESC;

-- Class enrollment counts
SELECT
    c.class_id,
    c.name AS class_name,
    COUNT(ce.enrollment_id) AS enrolled_members
FROM classes c
LEFT JOIN class_enrollments ce
    ON ce.class_id = c.class_id
   AND ce.status = 'enrolled'
GROUP BY
    c.class_id,
    c.name
ORDER BY enrolled_members DESC;

-- Trainers and their classes
SELECT
    t.trainer_id,
    CONCAT(t.first_name, ' ', t.last_name) AS trainer_name,
    c.name AS class_name,
    c.capacity
FROM trainers t
LEFT JOIN classes c
    ON c.trainer_id = t.trainer_id
ORDER BY trainer_name, class_name;

-- Workout plans with trainers
SELECT
    wp.workout_plan_id,
    wp.name AS workout_plan,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    CONCAT(t.first_name, ' ', t.last_name) AS trainer_name,
    wp.goal,
    wp.status
FROM workout_plans wp
JOIN members m
    ON m.member_id = wp.member_id
LEFT JOIN trainers t
    ON t.trainer_id = wp.trainer_id
ORDER BY wp.workout_plan_id;

-- Exercises in each workout plan
SELECT
    wp.name AS workout_plan,
    e.name AS exercise,
    wpe.sets,
    wpe.repetitions,
    wpe.duration_seconds,
    wpe.rest_seconds,
    wpe.weight_kg
FROM workout_plan_exercises wpe
JOIN workout_plans wp
    ON wp.workout_plan_id = wpe.workout_plan_id
JOIN exercises e
    ON e.exercise_id = wpe.exercise_id
ORDER BY
    wp.workout_plan_id,
    wpe.workout_plan_exercise_id;

-- Members who have never attended a class
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name
FROM members m
LEFT JOIN attendance a
    ON a.member_id = m.member_id
WHERE a.attendance_id IS NULL;

-- Members with completed payments
SELECT
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    SUM(p.amount) AS total_paid
FROM members m
JOIN payments p
    ON p.member_id = m.member_id
WHERE p.status = 'completed'
GROUP BY
    m.member_id,
    m.first_name,
    m.last_name
ORDER BY total_paid DESC;