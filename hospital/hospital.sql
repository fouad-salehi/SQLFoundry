-- ============================================================

-- SQLFoundry - Hospital Management System

-- Database: MySQL 8.0+

-- File: hospital.sql

-- ============================================================

DROP DATABASE IF EXISTS hospital_db;

CREATE DATABASE hospital_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE hospital_db;


-- ============================================================
-- Table: departments
-- ============================================================

CREATE TABLE departments (
    department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    phone VARCHAR(30),
    location VARCHAR(150),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;


-- ============================================================
-- Table: doctors
-- ============================================================

CREATE TABLE doctors (
    doctor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    department_id INT UNSIGNED NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(150) NOT NULL,
    license_number VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'on_leave'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_doctors_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_doctors_department (department_id),
    INDEX idx_doctors_specialization (specialization),
    INDEX idx_doctors_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: patients
-- ============================================================

CREATE TABLE patients (
    patient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM(
        'male',
        'female',
        'other'
    ) NOT NULL,
    blood_type ENUM(
        'A+',
        'A-',
        'B+',
        'B-',
        'AB+',
        'AB-',
        'O+',
        'O-',
        'unknown'
    ) NOT NULL DEFAULT 'unknown',
    phone VARCHAR(30),
    email VARCHAR(255) UNIQUE,
    address VARCHAR(255),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(30),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_patients_name (last_name, first_name),
    INDEX idx_patients_dob (date_of_birth),
    INDEX idx_patients_blood_type (blood_type)
) ENGINE=InnoDB;


-- ============================================================
-- Table: appointments
-- ============================================================

CREATE TABLE appointments (
    appointment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    appointment_date DATETIME NOT NULL,
    reason VARCHAR(255),
    notes TEXT,
    status ENUM(
        'scheduled',
        'confirmed',
        'completed',
        'cancelled',
        'no_show'
    ) NOT NULL DEFAULT 'scheduled',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointments_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_appointments_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_appointments_patient (patient_id),
    INDEX idx_appointments_doctor (doctor_id),
    INDEX idx_appointments_date (appointment_date),
    INDEX idx_appointments_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: medical_records
-- ============================================================

CREATE TABLE medical_records (
    record_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    appointment_id INT UNSIGNED,
    diagnosis VARCHAR(255) NOT NULL,
    symptoms TEXT,
    treatment TEXT,
    notes TEXT,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_medical_records_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_medical_records_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_medical_records_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_medical_records_patient (patient_id),
    INDEX idx_medical_records_doctor (doctor_id),
    INDEX idx_medical_records_date (recorded_at)
) ENGINE=InnoDB;


-- ============================================================
-- Table: medications
-- ============================================================

CREATE TABLE medications (
    medication_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    dosage_form VARCHAR(100),
    manufacturer VARCHAR(150),
    stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    unit_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM(
        'available',
        'unavailable'
    ) NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_medication_price
        CHECK (unit_price >= 0),

    INDEX idx_medications_status (status),
    INDEX idx_medications_stock (stock_quantity)
) ENGINE=InnoDB;


-- ============================================================
-- Table: prescriptions
-- ============================================================

CREATE TABLE prescriptions (
    prescription_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    medical_record_id INT UNSIGNED,
    prescribed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT,
    status ENUM(
        'active',
        'completed',
        'cancelled'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_prescriptions_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_prescriptions_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_prescriptions_record
        FOREIGN KEY (medical_record_id)
        REFERENCES medical_records(record_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    INDEX idx_prescriptions_patient (patient_id),
    INDEX idx_prescriptions_doctor (doctor_id),
    INDEX idx_prescriptions_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: prescription_items
-- ============================================================

CREATE TABLE prescription_items (
    prescription_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT UNSIGNED NOT NULL,
    medication_id INT UNSIGNED NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT UNSIGNED NOT NULL,
    instructions TEXT,

    CONSTRAINT fk_prescription_items_prescription
        FOREIGN KEY (prescription_id)
        REFERENCES prescriptions(prescription_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_prescription_items_medication
        FOREIGN KEY (medication_id)
        REFERENCES medications(medication_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_prescription_duration
        CHECK (duration_days > 0),

    INDEX idx_prescription_items_prescription (prescription_id),
    INDEX idx_prescription_items_medication (medication_id)
) ENGINE=InnoDB;


-- ============================================================
-- Table: rooms
-- ============================================================

CREATE TABLE rooms (
    room_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    room_type ENUM(
        'general',
        'private',
        'icu',
        'emergency',
        'operating_room'
    ) NOT NULL,
    floor SMALLINT NOT NULL,
    status ENUM(
        'available',
        'occupied',
        'maintenance',
        'reserved'
    ) NOT NULL DEFAULT 'available',
    daily_rate DECIMAL(10,2) NOT NULL DEFAULT 0,

    CONSTRAINT chk_room_floor
        CHECK (floor >= 0),

    CONSTRAINT chk_room_rate
        CHECK (daily_rate >= 0),

    INDEX idx_rooms_type (room_type),
    INDEX idx_rooms_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: admissions
-- ============================================================

CREATE TABLE admissions (
    admission_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    room_id INT UNSIGNED NOT NULL,
    doctor_id INT UNSIGNED NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    reason TEXT,
    status ENUM(
        'admitted',
        'discharged',
        'transferred',
        'cancelled'
    ) NOT NULL DEFAULT 'admitted',

    CONSTRAINT fk_admissions_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_admissions_room
        FOREIGN KEY (room_id)
        REFERENCES rooms(room_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_admissions_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES doctors(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_admission_dates
        CHECK (
            discharge_date IS NULL
            OR discharge_date > admission_date
        ),

    INDEX idx_admissions_patient (patient_id),
    INDEX idx_admissions_room (room_id),
    INDEX idx_admissions_doctor (doctor_id),
    INDEX idx_admissions_status (status),
    INDEX idx_admissions_dates (admission_date, discharge_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: bills
-- ============================================================

CREATE TABLE bills (
    bill_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    admission_id INT UNSIGNED,
    bill_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    room_charges DECIMAL(12,2) NOT NULL DEFAULT 0,
    medication_charges DECIMAL(12,2) NOT NULL DEFAULT 0,
    consultation_charges DECIMAL(12,2) NOT NULL DEFAULT 0,
    other_charges DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount DECIMAL(12,2) NOT NULL DEFAULT 0,
    tax DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    status ENUM(
        'unpaid',
        'partially_paid',
        'paid',
        'cancelled'
    ) NOT NULL DEFAULT 'unpaid',

    CONSTRAINT fk_bills_patient
        FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_bills_admission
        FOREIGN KEY (admission_id)
        REFERENCES admissions(admission_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_bill_room
        CHECK (room_charges >= 0),

    CONSTRAINT chk_bill_medication
        CHECK (medication_charges >= 0),

    CONSTRAINT chk_bill_consultation
        CHECK (consultation_charges >= 0),

    CONSTRAINT chk_bill_other
        CHECK (other_charges >= 0),

    CONSTRAINT chk_bill_discount
        CHECK (discount >= 0),

    CONSTRAINT chk_bill_tax
        CHECK (tax >= 0),

    CONSTRAINT chk_bill_total
        CHECK (total_amount >= 0),

    INDEX idx_bills_patient (patient_id),
    INDEX idx_bills_admission (admission_id),
    INDEX idx_bills_status (status),
    INDEX idx_bills_date (bill_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: payments
-- ============================================================

CREATE TABLE payments (
    payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bill_id INT UNSIGNED NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method ENUM(
        'cash',
        'credit_card',
        'debit_card',
        'bank_transfer',
        'insurance'
    ) NOT NULL,
    transaction_reference VARCHAR(150) UNIQUE,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'refunded'
    ) NOT NULL DEFAULT 'completed',
    paid_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_bill
        FOREIGN KEY (bill_id)
        REFERENCES bills(bill_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_payment_amount
        CHECK (amount > 0),

    INDEX idx_payments_bill (bill_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_date (paid_at)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO departments
    (name, description, phone, location)
VALUES
    ('Cardiology', 'Diagnosis and treatment of heart conditions.',
     '+1-555-4001', 'Building A - Floor 2'),

    ('Neurology', 'Diagnosis and treatment of neurological disorders.',
     '+1-555-4002', 'Building A - Floor 3'),

    ('Orthopedics', 'Musculoskeletal system treatment.',
     '+1-555-4003', 'Building B - Floor 1'),

    ('Emergency', 'Emergency medical care.',
     '+1-555-4004', 'Building A - Ground Floor');


INSERT INTO doctors
    (department_id, first_name, last_name, specialization,
     license_number, email, phone, hire_date, status)
VALUES
    (1, 'Michael', 'Brown', 'Cardiologist',
     'LIC-10001', 'michael.brown@hospital.example',
     '+1-555-4101', '2021-03-15', 'active'),

    (2, 'Emily', 'Davis', 'Neurologist',
     'LIC-10002', 'emily.davis@hospital.example',
     '+1-555-4102', '2022-06-20', 'active'),

    (3, 'Daniel', 'Wilson', 'Orthopedic Surgeon',
     'LIC-10003', 'daniel.wilson@hospital.example',
     '+1-555-4103', '2020-11-05', 'active'),

    (4, 'Sophia', 'Taylor', 'Emergency Physician',
     'LIC-10004', 'sophia.taylor@hospital.example',
     '+1-555-4104', '2023-01-10', 'active');


INSERT INTO patients
    (first_name, last_name, date_of_birth, gender, blood_type,
     phone, email, address, emergency_contact_name,
     emergency_contact_phone)
VALUES
    ('John', 'Smith', '1985-04-12', 'male', 'O+',
     '+1-555-5001', 'john.smith@example.com',
     '100 Main Street, New York',
     'Anna Smith', '+1-555-5101'),

    ('Emma', 'Wilson', '1992-08-25', 'female', 'A+',
     '+1-555-5002', 'emma.wilson@example.com',
     '25 Oxford Road, London',
     'James Wilson', '+1-555-5102'),

    ('Daniel', 'Miller', '1978-12-03', 'male', 'B+',
     '+1-555-5003', 'daniel.miller@example.com',
     '50 King Street, Toronto',
     'Laura Miller', '+1-555-5103'),

    ('Sofia', 'Garcia', '2000-02-18', 'female', 'AB+',
     '+1-555-5004', 'sofia.garcia@example.com',
     '10 Gran Via, Madrid',
     'Carlos Garcia', '+1-555-5104');


INSERT INTO rooms
    (room_number, room_type, floor, status, daily_rate)
VALUES
    ('101', 'general', 1, 'available', 150.00),
    ('102', 'general', 1, 'occupied', 150.00),
    ('201', 'private', 2, 'available', 300.00),
    ('202', 'private', 2, 'occupied', 300.00),
    ('301', 'icu', 3, 'occupied', 750.00),
    ('302', 'icu', 3, 'available', 750.00),
    ('401', 'emergency', 4, 'available', 250.00),
    ('501', 'operating_room', 5, 'reserved', 1000.00);


INSERT INTO medications
    (name, description, dosage_form, manufacturer,
     stock_quantity, unit_price, status)
VALUES
    ('Amoxicillin', 'Broad-spectrum antibiotic.',
     'Capsule', 'PharmaCorp', 500, 2.50, 'available'),

    ('Ibuprofen', 'Non-steroidal anti-inflammatory medication.',
     'Tablet', 'HealthLabs', 1000, 0.50, 'available'),

    ('Paracetamol', 'Pain reliever and fever reducer.',
     'Tablet', 'MediCare', 1500, 0.30, 'available'),

    ('Atorvastatin', 'Medication used to lower cholesterol.',
     'Tablet', 'PharmaCorp', 300, 1.80, 'available'),

    ('Metformin', 'Medication used to manage blood glucose.',
     'Tablet', 'HealthLabs', 450, 0.90, 'available');


INSERT INTO appointments
    (patient_id, doctor_id, appointment_date, reason, notes, status)
VALUES
    (1, 1, '2026-09-10 09:30:00',
     'Routine cardiac examination',
     'Patient reports occasional chest discomfort.',
     'confirmed'),

    (2, 2, '2026-09-10 11:00:00',
     'Headache evaluation',
     NULL,
     'scheduled'),

    (3, 3, '2026-09-11 14:00:00',
     'Knee pain',
     'Persistent pain after physical activity.',
     'confirmed'),

    (4, 4, '2026-09-09 18:30:00',
     'Acute abdominal pain',
     'Emergency evaluation.',
     'completed');


INSERT INTO medical_records
    (patient_id, doctor_id, appointment_id, diagnosis,
     symptoms, treatment, notes)
VALUES
    (1, 1, 1,
     'Mild hypertension',
     'Occasional chest discomfort and elevated blood pressure.',
     'Lifestyle modification and regular monitoring.',
     'Follow-up recommended in four weeks.'),

    (2, 2, 2,
     'Tension headache',
     'Recurring headache and neck tension.',
     'Rest, hydration, and medication if required.',
     NULL),

    (3, 3, 3,
     'Knee inflammation',
     'Knee pain and mild swelling.',
     'Physical therapy and anti-inflammatory medication.',
     'Avoid high-impact activity temporarily.'),

    (4, 4, 4,
     'Acute gastritis',
     'Abdominal pain and nausea.',
     'Medication and dietary management.',
     'Return if symptoms worsen.');


INSERT INTO prescriptions
    (patient_id, doctor_id, medical_record_id, notes, status)
VALUES
    (1, 1, 1,
     'Take medication according to instructions.',
     'active'),

    (2, 2, 2,
     'Use medication only when necessary.',
     'active'),

    (3, 3, 3,
     'Complete the prescribed course.',
     'active');


INSERT INTO prescription_items
    (prescription_id, medication_id, dosage, frequency,
     duration_days, instructions)
VALUES
    (1, 4, '20 mg', 'Once daily', 30,
     'Take after breakfast.'),

    (2, 3, '500 mg', 'Every 8 hours', 5,
     'Take with water.'),

    (3, 2, '400 mg', 'Every 8 hours', 7,
     'Take after meals.');


INSERT INTO admissions
    (patient_id, room_id, doctor_id, admission_date,
     discharge_date, reason, status)
VALUES
    (1, 2, 1,
     '2026-09-07 10:00:00',
     NULL,
     'Cardiac observation.',
     'admitted'),

    (3, 5, 3,
     '2026-09-01 15:30:00',
     '2026-09-05 11:00:00',
     'Post-surgical observation.',
     'discharged');


INSERT INTO bills
    (patient_id, admission_id, bill_date,
     room_charges, medication_charges, consultation_charges,
     other_charges, discount, tax, total_amount, status)
VALUES
    (1, 1, '2026-09-09 16:00:00',
     450.00, 54.00, 150.00,
     25.00, 0.00, 67.90, 746.90, 'partially_paid'),

    (3, 2, '2026-09-05 12:00:00',
     600.00, 85.00, 300.00,
     50.00, 35.00, 100.00, 1100.00, 'paid'),

    (2, NULL, '2026-09-08 17:00:00',
     0.00, 0.00, 120.00,
     0.00, 0.00, 12.00, 132.00, 'unpaid');


INSERT INTO payments
    (bill_id, amount, payment_method,
     transaction_reference, status, paid_at)
VALUES
    (1, 400.00, 'credit_card',
     'HOSP-PAY-10001', 'completed',
     '2026-09-09 17:00:00'),

    (2, 1100.00, 'insurance',
     'HOSP-PAY-10002', 'completed',
     '2026-09-05 13:00:00');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW doctor_directory AS
SELECT
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dep.name AS department,
    d.email,
    d.phone,
    d.status
FROM doctors d
JOIN departments dep
    ON d.department_id = dep.department_id;


CREATE VIEW upcoming_appointments AS
SELECT
    a.appointment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    dep.name AS department,
    a.appointment_date,
    a.reason,
    a.status
FROM appointments a
JOIN patients p
    ON a.patient_id = p.patient_id
JOIN doctors d
    ON a.doctor_id = d.doctor_id
JOIN departments dep
    ON d.department_id = dep.department_id
WHERE a.status IN ('scheduled', 'confirmed')
ORDER BY a.appointment_date;


CREATE VIEW active_admissions AS
SELECT
    ad.admission_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    r.room_number,
    r.room_type,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    ad.admission_date,
    ad.reason,
    ad.status
FROM admissions ad
JOIN patients p
    ON ad.patient_id = p.patient_id
JOIN rooms r
    ON ad.room_id = r.room_id
JOIN doctors d
    ON ad.doctor_id = d.doctor_id
WHERE ad.status = 'admitted';


CREATE VIEW patient_medical_history AS
SELECT
    mr.record_id,
    mr.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    d.specialization,
    mr.diagnosis,
    mr.symptoms,
    mr.treatment,
    mr.recorded_at
FROM medical_records mr
JOIN patients p
    ON mr.patient_id = p.patient_id
JOIN doctors d
    ON mr.doctor_id = d.doctor_id;


CREATE VIEW bill_payment_summary AS
SELECT
    b.bill_id,
    b.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    b.total_amount AS bill_total,
    COALESCE(
        SUM(
            CASE
                WHEN pay.status = 'completed'
                THEN pay.amount
                ELSE 0
            END
        ),
        0
    ) AS paid_amount,
    b.total_amount -
    COALESCE(
        SUM(
            CASE
                WHEN pay.status = 'completed'
                THEN pay.amount
                ELSE 0
            END
        ),
        0
    ) AS remaining_amount,
    b.status
FROM bills b
JOIN patients p
    ON b.patient_id = p.patient_id
LEFT JOIN payments pay
    ON b.bill_id = pay.bill_id
GROUP BY
    b.bill_id,
    b.patient_id,
    p.first_name,
    p.last_name,
    b.total_amount,
    b.status;


CREATE VIEW available_rooms AS
SELECT
    room_id,
    room_number,
    room_type,
    floor,
    daily_rate
FROM rooms
WHERE status = 'available';


-- ============================================================
-- Example Queries
-- ============================================================

-- List all doctors
SELECT *
FROM doctor_directory
ORDER BY department, doctor_name;


-- Upcoming appointments
SELECT *
FROM upcoming_appointments;


-- Currently admitted patients
SELECT *
FROM active_admissions
ORDER BY admission_date;


-- Patient medical history
SELECT *
FROM patient_medical_history
WHERE patient_id = 1
ORDER BY recorded_at DESC;


-- Available hospital rooms
SELECT *
FROM available_rooms
ORDER BY floor, room_number;


-- Low-stock medications
SELECT
    medication_id,
    name,
    stock_quantity,
    unit_price
FROM medications
WHERE stock_quantity <= 500
ORDER BY stock_quantity;


-- Prescription details
SELECT
    pr.prescription_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    m.name AS medication,
    pi.dosage,
    pi.frequency,
    pi.duration_days,
    pi.instructions
FROM prescription_items pi
JOIN prescriptions pr
    ON pi.prescription_id = pr.prescription_id
JOIN patients p
    ON pr.patient_id = p.patient_id
JOIN medications m
    ON pi.medication_id = m.medication_id
ORDER BY pr.prescription_id;


-- Billing and payment status
SELECT *
FROM bill_payment_summary
ORDER BY bill_id;


-- Outstanding bills
SELECT
    bill_id,
    patient_name,
    bill_total,
    paid_amount,
    remaining_amount
FROM bill_payment_summary
WHERE remaining_amount > 0
ORDER BY remaining_amount DESC;


-- Revenue by payment method
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'completed'
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- Doctors by department
SELECT
    dep.name AS department,
    COUNT(d.doctor_id) AS doctor_count
FROM departments dep
LEFT JOIN doctors d
    ON dep.department_id = d.department_id
    AND d.status = 'active'
GROUP BY dep.department_id, dep.name
ORDER BY doctor_count DESC;


-- Number of appointments per doctor
SELECT
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    COUNT(a.appointment_id) AS appointment_count
FROM doctors d
LEFT JOIN appointments a
    ON d.doctor_id = a.doctor_id
GROUP BY
    d.doctor_id,
    d.first_name,
    d.last_name
ORDER BY appointment_count DESC;