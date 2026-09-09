-- ============================================================

-- SQLFoundry - School Management System

-- Database: MySQL 8.0+

-- File: school.sql

-- ============================================================

DROP DATABASE IF EXISTS school_db;

CREATE DATABASE school_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE school_db;


-- ============================================================
-- Table: academic_years
-- ============================================================

CREATE TABLE academic_years (
    academic_year_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM(
        'upcoming',
        'active',
        'completed'
    ) NOT NULL DEFAULT 'upcoming',

    CONSTRAINT chk_academic_year_dates
        CHECK (end_date > start_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: departments
-- ============================================================

CREATE TABLE departments (
    department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- ============================================================
-- Table: students
-- ============================================================

CREATE TABLE students (
    student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM(
        'male',
        'female',
        'other'
    ) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    address VARCHAR(255),
    admission_date DATE NOT NULL,
    status ENUM(
        'active',
        'graduated',
        'suspended',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_students_name (last_name, first_name),
    INDEX idx_students_status (status),
    INDEX idx_students_admission (admission_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: teachers
-- ============================================================

CREATE TABLE teachers (
    teacher_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id INT UNSIGNED NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    employee_number VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'on_leave'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_teachers_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_teachers_department (department_id),
    INDEX idx_teachers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: courses
-- ============================================================

CREATE TABLE courses (
    course_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id INT UNSIGNED NOT NULL,
    course_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    credits TINYINT UNSIGNED NOT NULL DEFAULT 1,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_courses_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_course_credits
        CHECK (credits > 0),

    INDEX idx_courses_department (department_id),
    INDEX idx_courses_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: classrooms
-- ============================================================

CREATE TABLE classrooms (
    classroom_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    building VARCHAR(100) NOT NULL,
    room_number VARCHAR(30) NOT NULL,
    capacity SMALLINT UNSIGNED NOT NULL,
    room_type ENUM(
        'classroom',
        'laboratory',
        'lecture_hall',
        'computer_lab'
    ) NOT NULL DEFAULT 'classroom',
    status ENUM(
        'available',
        'maintenance',
        'unavailable'
    ) NOT NULL DEFAULT 'available',

    CONSTRAINT uq_classroom_location
        UNIQUE (building, room_number),

    CONSTRAINT chk_classroom_capacity
        CHECK (capacity > 0),

    INDEX idx_classrooms_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: classes
-- ============================================================

CREATE TABLE classes (
    class_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    course_id INT UNSIGNED NOT NULL,
    teacher_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    classroom_id INT UNSIGNED,
    section VARCHAR(20) NOT NULL DEFAULT 'A',
    schedule_day ENUM(
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
    ) NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    capacity SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    status ENUM(
        'scheduled',
        'active',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'scheduled',

    CONSTRAINT fk_classes_course
        FOREIGN KEY (course_id)
        REFERENCES courses(course_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_classes_teacher
        FOREIGN KEY (teacher_id)
        REFERENCES teachers(teacher_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_classes_academic_year
        FOREIGN KEY (academic_year_id)
        REFERENCES academic_years(academic_year_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_classes_classroom
        FOREIGN KEY (classroom_id)
        REFERENCES classrooms(classroom_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_class_times
        CHECK (end_time > start_time),

    CONSTRAINT chk_class_capacity
        CHECK (capacity > 0),

    UNIQUE (
        course_id,
        academic_year_id,
        section
    ),

    INDEX idx_classes_course (course_id),
    INDEX idx_classes_teacher (teacher_id),
    INDEX idx_classes_year (academic_year_id),
    INDEX idx_classes_classroom (classroom_id),
    INDEX idx_classes_schedule (schedule_day, start_time)
) ENGINE=InnoDB;


-- ============================================================
-- Table: enrollments
-- ============================================================

CREATE TABLE enrollments (
    enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    class_id INT UNSIGNED NOT NULL,
    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'enrolled',
        'dropped',
        'completed'
    ) NOT NULL DEFAULT 'enrolled',

    CONSTRAINT fk_enrollments_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_enrollments_class
        FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    UNIQUE (
        student_id,
        class_id
    ),

    INDEX idx_enrollments_student (student_id),
    INDEX idx_enrollments_class (class_id),
    INDEX idx_enrollments_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: attendance
-- ============================================================

CREATE TABLE attendance (
    attendance_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enrollment_id INT UNSIGNED NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM(
        'present',
        'absent',
        'late',
        'excused'
    ) NOT NULL,
    notes VARCHAR(255),

    CONSTRAINT fk_attendance_enrollment
        FOREIGN KEY (enrollment_id)
        REFERENCES enrollments(enrollment_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    UNIQUE (
        enrollment_id,
        attendance_date
    ),

    INDEX idx_attendance_date (attendance_date),
    INDEX idx_attendance_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: exams
-- ============================================================

CREATE TABLE exams (
    exam_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    class_id INT UNSIGNED NOT NULL,
    title VARCHAR(150) NOT NULL,
    exam_date DATETIME NOT NULL,
    max_score DECIMAL(6,2) NOT NULL DEFAULT 100,
    exam_type ENUM(
        'quiz',
        'midterm',
        'final',
        'project'
    ) NOT NULL,
    status ENUM(
        'scheduled',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'scheduled',

    CONSTRAINT fk_exams_class
        FOREIGN KEY (class_id)
        REFERENCES classes(class_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_exam_max_score
        CHECK (max_score > 0),

    INDEX idx_exams_class (class_id),
    INDEX idx_exams_date (exam_date),
    INDEX idx_exams_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: grades
-- ============================================================

CREATE TABLE grades (
    grade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    exam_id INT UNSIGNED NOT NULL,
    student_id INT UNSIGNED NOT NULL,
    score DECIMAL(6,2) NOT NULL,
    graded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    feedback TEXT,

    CONSTRAINT fk_grades_exam
        FOREIGN KEY (exam_id)
        REFERENCES exams(exam_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_grades_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_grade_score
        CHECK (score >= 0),

    UNIQUE (
        exam_id,
        student_id
    ),

    INDEX idx_grades_exam (exam_id),
    INDEX idx_grades_student (student_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    student_id INT UNSIGNED NOT NULL,
    academic_year_id INT UNSIGNED NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_type ENUM(
        'tuition',
        'registration',
        'library',
        'laboratory',
        'other'
    ) NOT NULL,
    payment_method ENUM(
        'cash',
        'credit_card',
        'debit_card',
        'bank_transfer',
        'online'
    ) NOT NULL,
    transaction_reference VARCHAR(150) UNIQUE,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'completed',
    paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_student
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_payments_academic_year
        FOREIGN KEY (academic_year_id)
        REFERENCES academic_years(academic_year_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_student (student_id),
    INDEX idx_payments_year (academic_year_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_date (paid_at)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO academic_years
    (name, start_date, end_date, status)
VALUES
    ('2025-2026', '2025-09-01', '2026-06-30', 'completed'),
    ('2026-2027', '2026-09-01', '2027-06-30', 'active'),
    ('2027-2028', '2027-09-01', '2028-06-30', 'upcoming');


INSERT INTO departments
    (name, description)
VALUES
    ('Computer Science', 'Computer science and information technology.'),
    ('Mathematics', 'Mathematics and applied mathematics.'),
    ('Physics', 'Physics and experimental sciences.'),
    ('Languages', 'Language and communication studies.');


INSERT INTO students
    (student_number, first_name, last_name, date_of_birth,
     gender, email, phone, address, admission_date, status)
VALUES
    ('STU-2026-001', 'John', 'Smith', '2008-03-15',
     'male', 'john.smith@student.example',
     '+1-555-6001', '100 Main Street',
     '2026-09-01', 'active'),

    ('STU-2026-002', 'Emma', 'Wilson', '2008-07-22',
     'female', 'emma.wilson@student.example',
     '+1-555-6002', '25 Oxford Road',
     '2026-09-01', 'active'),

    ('STU-2026-003', 'Daniel', 'Miller', '2007-11-10',
     'male', 'daniel.miller@student.example',
     '+1-555-6003', '50 King Street',
     '2026-09-01', 'active'),

    ('STU-2026-004', 'Sofia', 'Garcia', '2009-01-18',
     'female', 'sofia.garcia@student.example',
     '+1-555-6004', '10 Gran Via',
     '2026-09-01', 'active');


INSERT INTO teachers
    (department_id, first_name, last_name, employee_number,
     email, phone, hire_date, status)
VALUES
    (1, 'Michael', 'Brown', 'EMP-1001',
     'michael.brown@school.example',
     '+1-555-6101', '2021-08-15', 'active'),

    (2, 'Emily', 'Davis', 'EMP-1002',
     'emily.davis@school.example',
     '+1-555-6102', '2022-01-10', 'active'),

    (3, 'James', 'Taylor', 'EMP-1003',
     'james.taylor@school.example',
     '+1-555-6103', '2020-09-01', 'active'),

    (4, 'Sophia', 'Anderson', 'EMP-1004',
     'sophia.anderson@school.example',
     '+1-555-6104', '2023-02-20', 'active');


INSERT INTO courses
    (department_id, course_code, name, description, credits, status)
VALUES
    (1, 'CS101', 'Introduction to Programming',
     'Fundamentals of programming and problem solving.', 4, 'active'),

    (1, 'CS201', 'Database Systems',
     'Relational databases, SQL, and database design.', 4, 'active'),

    (2, 'MATH101', 'Calculus I',
     'Limits, derivatives, and basic integration.', 4, 'active'),

    (3, 'PHY101', 'General Physics',
     'Fundamentals of mechanics, energy, and motion.', 3, 'active'),

    (4, 'ENG101', 'Academic English',
     'English communication and academic writing.', 3, 'active');


INSERT INTO classrooms
    (building, room_number, capacity, room_type, status)
VALUES
    ('Building A', '101', 30, 'classroom', 'available'),
    ('Building A', '202', 25, 'computer_lab', 'available'),
    ('Building B', '105', 40, 'lecture_hall', 'available'),
    ('Building B', '210', 24, 'laboratory', 'available');


INSERT INTO classes
    (course_id, teacher_id, academic_year_id, classroom_id,
     section, schedule_day, start_time, end_time, capacity, status)
VALUES
    (1, 1, 2, 2, 'A',
     'Monday', '09:00:00', '11:00:00', 25, 'active'),

    (2, 1, 2, 2, 'A',
     'Wednesday', '09:00:00', '11:00:00', 25, 'active'),

    (3, 2, 2, 3, 'A',
     'Tuesday', '10:00:00', '12:00:00', 35, 'active'),

    (4, 3, 2, 4, 'A',
     'Thursday', '13:00:00', '15:00:00', 24, 'active'),

    (5, 4, 2, 1, 'A',
     'Saturday', '10:00:00', '12:00:00', 30, 'active');


INSERT INTO enrollments
    (student_id, class_id, status)
VALUES
    (1, 1, 'enrolled'),
    (2, 1, 'enrolled'),
    (3, 1, 'enrolled'),
    (4, 1, 'enrolled'),

    (1, 2, 'enrolled'),
    (2, 2, 'enrolled'),
    (3, 2, 'enrolled'),

    (1, 3, 'enrolled'),
    (2, 3, 'enrolled'),
    (4, 3, 'enrolled'),

    (2, 4, 'enrolled'),
    (3, 4, 'enrolled'),

    (1, 5, 'enrolled'),
    (2, 5, 'enrolled'),
    (4, 5, 'enrolled');


INSERT INTO attendance
    (enrollment_id, attendance_date, status, notes)
VALUES
    (1, '2026-09-07', 'present', NULL),
    (2, '2026-09-07', 'present', NULL),
    (3, '2026-09-07', 'late', 'Arrived 10 minutes late.'),
    (4, '2026-09-07', 'absent', NULL),

    (5, '2026-09-09', 'present', NULL),
    (6, '2026-09-09', 'present', NULL),
    (7, '2026-09-09', 'excused', 'Medical appointment.'),

    (8, '2026-09-08', 'present', NULL),
    (9, '2026-09-08', 'present', NULL),
    (10, '2026-09-08', 'late', NULL);


INSERT INTO exams
    (class_id, title, exam_date, max_score, exam_type, status)
VALUES
    (1, 'Programming Quiz 1',
     '2026-09-21 09:00:00', 20, 'quiz', 'scheduled'),

    (2, 'Database Midterm',
     '2026-10-14 09:00:00', 100, 'midterm', 'scheduled'),

    (3, 'Calculus Midterm',
     '2026-10-13 10:00:00', 100, 'midterm', 'scheduled'),

    (4, 'Physics Project',
     '2026-11-05 13:00:00', 50, 'project', 'scheduled');


INSERT INTO grades
    (exam_id, student_id, score, feedback)
VALUES
    (1, 1, 18.00, 'Excellent understanding of the fundamentals.'),
    (1, 2, 16.50, 'Good work with minor mistakes.'),
    (1, 3, 14.00, 'Review conditional statements.'),
    (1, 4, 19.00, 'Excellent performance.');


INSERT INTO payments
    (student_id, academic_year_id, amount, payment_type,
     payment_method, transaction_reference, status)
VALUES
    (1, 2, 1200.00, 'tuition',
     'bank_transfer', 'SCH-PAY-10001', 'completed'),

    (2, 2, 1200.00, 'tuition',
     'credit_card', 'SCH-PAY-10002', 'completed'),

    (3, 2, 1000.00, 'tuition',
     'online', 'SCH-PAY-10003', 'completed'),

    (4, 2, 1200.00, 'tuition',
     'debit_card', 'SCH-PAY-10004', 'completed'),

    (1, 2, 75.00, 'laboratory',
     'cash', 'SCH-PAY-10005', 'completed');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW student_directory AS
SELECT
    student_id,
    student_number,
    CONCAT(first_name, ' ', last_name) AS student_name,
    date_of_birth,
    gender,
    email,
    phone,
    admission_date,
    status
FROM students;


CREATE VIEW class_schedule AS
SELECT
    cl.class_id,
    c.course_code,
    c.name AS course_name,
    cl.section,
    CONCAT(t.first_name, ' ', t.last_name) AS teacher_name,
    cl.schedule_day,
    cl.start_time,
    cl.end_time,
    CONCAT(cr.building, ' - ', cr.room_number) AS classroom,
    cl.capacity,
    cl.status
FROM classes cl
JOIN courses c
    ON cl.course_id = c.course_id
JOIN teachers t
    ON cl.teacher_id = t.teacher_id
LEFT JOIN classrooms cr
    ON cl.classroom_id = cr.classroom_id;


CREATE VIEW student_enrollments AS
SELECT
    e.enrollment_id,
    s.student_id,
    s.student_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.name AS course_name,
    cl.section,
    e.status AS enrollment_status
FROM enrollments e
JOIN students s
    ON e.student_id = s.student_id
JOIN classes cl
    ON e.class_id = cl.class_id
JOIN courses c
    ON cl.course_id = c.course_id;


CREATE VIEW attendance_summary AS
SELECT
    s.student_id,
    s.student_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    COUNT(a.attendance_id) AS total_records,
    SUM(a.status = 'present') AS present_count,
    SUM(a.status = 'absent') AS absent_count,
    SUM(a.status = 'late') AS late_count,
    SUM(a.status = 'excused') AS excused_count
FROM students s
JOIN enrollments e
    ON s.student_id = e.student_id
JOIN attendance a
    ON e.enrollment_id = a.enrollment_id
GROUP BY
    s.student_id,
    s.student_number,
    s.first_name,
    s.last_name;


CREATE VIEW grade_summary AS
SELECT
    s.student_id,
    s.student_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.course_code,
    c.name AS course_name,
    COUNT(g.grade_id) AS graded_exams,
    ROUND(AVG(
        (g.score / ex.max_score) * 100
    ), 2) AS average_percentage
FROM grades g
JOIN students s
    ON g.student_id = s.student_id
JOIN exams ex
    ON g.exam_id = ex.exam_id
JOIN classes cl
    ON ex.class_id = cl.class_id
JOIN courses c
    ON cl.course_id = c.course_id
GROUP BY
    s.student_id,
    s.student_number,
    s.first_name,
    s.last_name,
    c.course_id,
    c.course_code,
    c.name;


CREATE VIEW payment_summary AS
SELECT
    s.student_id,
    s.student_number,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    ay.name AS academic_year,
    COUNT(p.payment_id) AS payment_count,
    COALESCE(
        SUM(
            CASE
                WHEN p.status = 'completed'
                THEN p.amount
                ELSE 0
            END
        ),
        0
    ) AS total_paid
FROM students s
JOIN academic_years ay
    ON ay.academic_year_id = 2
LEFT JOIN payments p
    ON s.student_id = p.student_id
    AND p.academic_year_id = ay.academic_year_id
GROUP BY
    s.student_id,
    s.student_number,
    s.first_name,
    s.last_name,
    ay.name;


-- ============================================================
-- Example Queries
-- ============================================================

-- List all active students
SELECT *
FROM student_directory
WHERE status = 'active'
ORDER BY last_name, first_name;


-- Current class schedule
SELECT *
FROM class_schedule
WHERE status = 'active'
ORDER BY
    FIELD(
        schedule_day,
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
    ),
    start_time;


-- Students enrolled in a course
SELECT
    student_number,
    student_name,
    course_code,
    course_name,
    section
FROM student_enrollments
WHERE course_code = 'CS101'
ORDER BY student_name;


-- Attendance summary
SELECT *
FROM attendance_summary
ORDER BY absent_count DESC, student_name;


-- Students with absences
SELECT *
FROM attendance_summary
WHERE absent_count > 0
ORDER BY absent_count DESC;


-- Grade summary
SELECT *
FROM grade_summary
ORDER BY average_percentage DESC;


-- Students with average score above 80%
SELECT
    student_name,
    course_code,
    course_name,
    average_percentage
FROM grade_summary
WHERE average_percentage >= 80
ORDER BY average_percentage DESC;


-- Upcoming exams
SELECT
    ex.exam_id,
    c.course_code,
    c.name AS course_name,
    ex.title,
    ex.exam_date,
    ex.max_score,
    ex.exam_type
FROM exams ex
JOIN classes cl
    ON ex.class_id = cl.class_id
JOIN courses c
    ON cl.course_id = c.course_id
WHERE ex.status = 'scheduled'
ORDER BY ex.exam_date;


-- Teacher workload
SELECT
    CONCAT(t.first_name, ' ', t.last_name) AS teacher_name,
    COUNT(cl.class_id) AS class_count
FROM teachers t
LEFT JOIN classes cl
    ON t.teacher_id = cl.teacher_id
    AND cl.status IN ('scheduled', 'active')
GROUP BY
    t.teacher_id,
    t.first_name,
    t.last_name
ORDER BY class_count DESC;


-- Enrollment count per class
SELECT
    c.course_code,
    c.name AS course_name,
    cl.section,
    COUNT(e.enrollment_id) AS enrolled_students
FROM classes cl
JOIN courses c
    ON cl.course_id = c.course_id
LEFT JOIN enrollments e
    ON cl.class_id = e.class_id
    AND e.status = 'enrolled'
GROUP BY
    cl.class_id,
    c.course_code,
    c.name,
    cl.section
ORDER BY enrolled_students DESC;


-- Payment summary
SELECT *
FROM payment_summary
ORDER BY total_paid DESC;


-- Total tuition revenue
SELECT
    SUM(amount) AS total_tuition_revenue
FROM payments
WHERE payment_type = 'tuition'
  AND status = 'completed';


-- Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payments
WHERE status = 'completed'
GROUP BY payment_method
ORDER BY total_amount DESC;