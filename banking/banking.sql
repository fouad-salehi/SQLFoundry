-- ============================================================

-- SQLFoundry - Banking Management System

-- Database: MySQL 8.0+

-- File: banking.sql

-- ============================================================

DROP DATABASE IF EXISTS banking_db;

CREATE DATABASE banking_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE banking_db;


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
    registration_date DATE NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'blocked'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_customers_name (last_name, first_name),
    INDEX idx_customers_city (city),
    INDEX idx_customers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: employees
-- ============================================================

CREATE TABLE employees (
    employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    branch_id INT UNSIGNED NOT NULL,
    employee_number VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),
    hire_date DATE NOT NULL,
    status ENUM(
        'active',
        'inactive',
        'on_leave'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_employees_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    INDEX idx_employees_branch (branch_id),
    INDEX idx_employees_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: account_types
-- ============================================================

CREATE TABLE account_types (
    account_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    minimum_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    interest_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT chk_account_minimum_balance
        CHECK (minimum_balance >= 0),

    CONSTRAINT chk_account_interest_rate
        CHECK (interest_rate >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- Table: accounts
-- ============================================================

CREATE TABLE accounts (
    account_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_number VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT UNSIGNED NOT NULL,
    account_type_id INT UNSIGNED NOT NULL,
    branch_id INT UNSIGNED NOT NULL,
    balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at DATETIME,
    status ENUM(
        'active',
        'frozen',
        'closed'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_accounts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_accounts_type
        FOREIGN KEY (account_type_id)
        REFERENCES account_types(account_type_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_accounts_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_account_balance
        CHECK (balance >= 0),

    INDEX idx_accounts_customer (customer_id),
    INDEX idx_accounts_type (account_type_id),
    INDEX idx_accounts_branch (branch_id),
    INDEX idx_accounts_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: beneficiaries
-- ============================================================

CREATE TABLE beneficiaries (
    beneficiary_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    beneficiary_name VARCHAR(150) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    bank_name VARCHAR(150) NOT NULL,
    nickname VARCHAR(100),
    status ENUM(
        'active',
        'inactive'
    ) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_beneficiaries_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    INDEX idx_beneficiaries_customer (customer_id),
    INDEX idx_beneficiaries_account (account_number)
) ENGINE=InnoDB;


-- ============================================================
-- Table: cards
-- ============================================================

CREATE TABLE cards (
    card_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id BIGINT UNSIGNED NOT NULL,
    card_number VARCHAR(30) NOT NULL UNIQUE,
    card_type ENUM(
        'debit',
        'credit'
    ) NOT NULL,
    issue_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    daily_limit DECIMAL(15,2) NOT NULL DEFAULT 1000,
    status ENUM(
        'active',
        'blocked',
        'expired',
        'cancelled'
    ) NOT NULL DEFAULT 'active',

    CONSTRAINT fk_cards_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_card_dates
        CHECK (expiry_date > issue_date),

    CONSTRAINT chk_card_daily_limit
        CHECK (daily_limit >= 0),

    INDEX idx_cards_account (account_id),
    INDEX idx_cards_status (status),
    INDEX idx_cards_expiry (expiry_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: transactions
-- ============================================================

CREATE TABLE transactions (
    transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    account_id BIGINT UNSIGNED NOT NULL,
    related_account_id BIGINT UNSIGNED,
    transaction_reference VARCHAR(100) NOT NULL UNIQUE,
    transaction_type ENUM(
        'deposit',
        'withdrawal',
        'transfer',
        'payment',
        'fee',
        'interest'
    ) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    description VARCHAR(255),
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'reversed'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_transactions_account
        FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transactions_related_account
        FOREIGN KEY (related_account_id)
        REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_transaction_amount
        CHECK (amount > 0),

    INDEX idx_transactions_account (account_id),
    INDEX idx_transactions_related_account (related_account_id),
    INDEX idx_transactions_type (transaction_type),
    INDEX idx_transactions_date (transaction_date),
    INDEX idx_transactions_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: loans
-- ============================================================

CREATE TABLE loans (
    loan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id INT UNSIGNED NOT NULL,
    branch_id INT UNSIGNED NOT NULL,
    loan_number VARCHAR(50) NOT NULL UNIQUE,
    loan_type ENUM(
        'personal',
        'home',
        'auto',
        'education',
        'business'
    ) NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    term_months SMALLINT UNSIGNED NOT NULL,
    monthly_payment DECIMAL(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    outstanding_balance DECIMAL(15,2) NOT NULL,
    status ENUM(
        'pending',
        'active',
        'paid',
        'defaulted',
        'cancelled'
    ) NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_loans_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_loans_branch
        FOREIGN KEY (branch_id)
        REFERENCES branches(branch_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_loan_principal
        CHECK (principal_amount > 0),

    CONSTRAINT chk_loan_interest
        CHECK (interest_rate >= 0),

    CONSTRAINT chk_loan_term
        CHECK (term_months > 0),

    CONSTRAINT chk_loan_monthly_payment
        CHECK (monthly_payment > 0),

    CONSTRAINT chk_loan_dates
        CHECK (end_date > start_date),

    CONSTRAINT chk_loan_outstanding
        CHECK (outstanding_balance >= 0),

    INDEX idx_loans_customer (customer_id),
    INDEX idx_loans_branch (branch_id),
    INDEX idx_loans_status (status),
    INDEX idx_loans_end_date (end_date)
) ENGINE=InnoDB;


-- ============================================================
-- Table: loan_payments
-- ============================================================

CREATE TABLE loan_payments (
    loan_payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    loan_id BIGINT UNSIGNED NOT NULL,
    payment_reference VARCHAR(100) NOT NULL UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    principal_paid DECIMAL(15,2) NOT NULL,
    interest_paid DECIMAL(15,2) NOT NULL DEFAULT 0,
    payment_date DATE NOT NULL,
    payment_method ENUM(
        'cash',
        'bank_transfer',
        'card',
        'online'
    ) NOT NULL,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'reversed'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_loan_payments_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_loan_payment_amount
        CHECK (amount > 0),

    CONSTRAINT chk_loan_payment_principal
        CHECK (principal_paid >= 0),

    CONSTRAINT chk_loan_payment_interest
        CHECK (interest_paid >= 0),

    CONSTRAINT chk_loan_payment_split
        CHECK (principal_paid + interest_paid <= amount),

    INDEX idx_loan_payments_loan (loan_id),
    INDEX idx_loan_payments_date (payment_date),
    INDEX idx_loan_payments_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Table: transfers
-- ============================================================

CREATE TABLE transfers (
    transfer_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    from_account_id BIGINT UNSIGNED NOT NULL,
    to_account_id BIGINT UNSIGNED NOT NULL,
    transfer_reference VARCHAR(100) NOT NULL UNIQUE,
    amount DECIMAL(15,2) NOT NULL,
    description VARCHAR(255),
    transfer_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM(
        'pending',
        'completed',
        'failed',
        'reversed'
    ) NOT NULL DEFAULT 'completed',

    CONSTRAINT fk_transfers_from_account
        FOREIGN KEY (from_account_id)
        REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transfers_to_account
        FOREIGN KEY (to_account_id)
        REFERENCES accounts(account_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_transfer_accounts
        CHECK (from_account_id <> to_account_id),

    CONSTRAINT chk_transfer_amount
        CHECK (amount > 0),

    INDEX idx_transfers_from_account (from_account_id),
    INDEX idx_transfers_to_account (to_account_id),
    INDEX idx_transfers_date (transfer_date),
    INDEX idx_transfers_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- Sample Data
-- ============================================================

INSERT INTO branches
    (branch_code, name, address, city, phone, status)
VALUES
    ('BR-001', 'Central Branch',
     '100 Main Street', 'New York',
     '+1-555-1001', 'active'),

    ('BR-002', 'Downtown Branch',
     '250 Market Street', 'Chicago',
     '+1-555-1002', 'active'),

    ('BR-003', 'Westside Branch',
     '75 Sunset Boulevard', 'Los Angeles',
     '+1-555-1003', 'active');


INSERT INTO customers
    (customer_number, first_name, last_name, date_of_birth,
     email, phone, address, city, registration_date, status)
VALUES
    ('CUS-10001', 'John', 'Smith', '1988-04-15',
     'john.smith@example.com', '+1-555-2001',
     '12 Oak Street', 'New York',
     '2024-03-10', 'active'),

    ('CUS-10002', 'Emma', 'Wilson', '1992-09-21',
     'emma.wilson@example.com', '+1-555-2002',
     '44 Lake Road', 'Chicago',
     '2024-06-18', 'active'),

    ('CUS-10003', 'Daniel', 'Miller', '1985-12-03',
     'daniel.miller@example.com', '+1-555-2003',
     '78 Pine Avenue', 'Los Angeles',
     '2025-01-12', 'active'),

    ('CUS-10004', 'Sophia', 'Garcia', '1995-07-30',
     'sophia.garcia@example.com', '+1-555-2004',
     '91 River Street', 'New York',
     '2025-04-05', 'active');


INSERT INTO employees
    (branch_id, employee_number, first_name, last_name,
     job_title, email, phone, hire_date, status)
VALUES
    (1, 'EMP-001', 'Robert', 'Taylor',
     'Branch Manager', 'robert.taylor@bank.example',
     '+1-555-3001', '2020-01-15', 'active'),

    (1, 'EMP-002', 'Laura', 'Brown',
     'Banking Officer', 'laura.brown@bank.example',
     '+1-555-3002', '2022-05-10', 'active'),

    (2, 'EMP-003', 'James', 'Davis',
     'Loan Officer', 'james.davis@bank.example',
     '+1-555-3003', '2021-09-01', 'active'),

    (3, 'EMP-004', 'Olivia', 'Martin',
     'Banking Officer', 'olivia.martin@bank.example',
     '+1-555-3004', '2023-02-20', 'active');


INSERT INTO account_types
    (name, description, minimum_balance, interest_rate, status)
VALUES
    ('Checking',
     'Standard checking account for daily transactions.',
     0.00, 0.10, 'active'),

    ('Savings',
     'Interest-bearing savings account.',
     100.00, 2.50, 'active'),

    ('Business',
     'Account designed for business operations.',
     500.00, 0.50, 'active'),

    ('Student',
     'Low-fee account for students.',
     0.00, 0.25, 'active');


INSERT INTO accounts
    (account_number, customer_id, account_type_id, branch_id,
     balance, opened_at, status)
VALUES
    ('ACC-1000001', 1, 1, 1,
     5250.00, '2025-01-10 09:00:00', 'active'),

    ('ACC-1000002', 1, 2, 1,
     12800.00, '2025-01-10 09:30:00', 'active'),

    ('ACC-1000003', 2, 1, 2,
     7350.00, '2025-03-15 10:00:00', 'active'),

    ('ACC-1000004', 2, 2, 2,
     15400.00, '2025-03-15 10:30:00', 'active'),

    ('ACC-1000005', 3, 3, 3,
     22500.00, '2025-05-20 11:00:00', 'active'),

    ('ACC-1000006', 4, 1, 1,
     3150.00, '2025-06-01 09:15:00', 'active');


INSERT INTO beneficiaries
    (customer_id, beneficiary_name, account_number,
     bank_name, nickname, status)
VALUES
    (1, 'Emma Wilson', 'ACC-1000003',
     'SQLFoundry Bank', 'Emma', 'active'),

    (2, 'John Smith', 'ACC-1000001',
     'SQLFoundry Bank', 'John', 'active'),

    (4, 'Daniel Miller', 'ACC-1000005',
     'SQLFoundry Bank', 'Daniel', 'active');


INSERT INTO cards
    (account_id, card_number, card_type, issue_date,
     expiry_date, daily_limit, status)
VALUES
    (1, '4111111111111111', 'debit',
     '2025-01-15', '2030-01-31', 2500.00, 'active'),

    (2, '4222222222222222', 'debit',
     '2025-01-15', '2030-01-31', 3000.00, 'active'),

    (3, '4333333333333333', 'debit',
     '2025-03-20', '2030-03-31', 2500.00, 'active'),

    (4, '4444444444444444', 'debit',
     '2025-03-20', '2030-03-31', 3000.00, 'active'),

    (6, '4555555555555555', 'debit',
     '2025-06-05', '2030-06-30', 2000.00, 'active');


INSERT INTO transactions
    (account_id, related_account_id, transaction_reference,
     transaction_type, amount, description,
     transaction_date, status)
VALUES
    (1, NULL, 'TXN-10001',
     'deposit', 5000.00, 'Initial deposit',
     '2025-01-10 09:10:00', 'completed'),

    (1, NULL, 'TXN-10002',
     'withdrawal', 250.00, 'ATM withdrawal',
     '2026-09-01 14:20:00', 'completed'),

    (1, 3, 'TXN-10003',
     'transfer', 500.00, 'Transfer to Emma Wilson',
     '2026-09-03 11:30:00', 'completed'),

    (2, NULL, 'TXN-10004',
     'deposit', 12000.00, 'Savings deposit',
     '2025-01-10 09:40:00', 'completed'),

    (3, 1, 'TXN-10005',
     'transfer', 750.00, 'Transfer from John Smith',
     '2026-09-04 16:00:00', 'completed'),

    (4, NULL, 'TXN-10006',
     'interest', 120.00, 'Monthly interest',
     '2026-09-01 00:00:00', 'completed'),

    (6, NULL, 'TXN-10007',
     'payment', 180.00, 'Utility payment',
     '2026-09-05 10:15:00', 'completed');


INSERT INTO loans
    (customer_id, branch_id, loan_number, loan_type,
     principal_amount, interest_rate, term_months,
     monthly_payment, start_date, end_date,
     outstanding_balance, status)
VALUES
    (1, 1, 'LOAN-10001', 'auto',
     18000.00, 6.50, 36,
     551.00, '2026-01-15', '2029-01-15',
     16500.00, 'active'),

    (3, 3, 'LOAN-10002', 'business',
     50000.00, 7.25, 60,
     995.00, '2026-02-01', '2031-02-01',
     48500.00, 'active'),

    (4, 1, 'LOAN-10003', 'education',
     10000.00, 4.50, 24,
     436.00, '2026-03-01', '2028-03-01',
     8500.00, 'active');


INSERT INTO loan_payments
    (loan_id, payment_reference, amount,
     principal_paid, interest_paid,
     payment_date, payment_method, status)
VALUES
    (1, 'LP-10001', 551.00,
     450.00, 101.00,
     '2026-08-15', 'bank_transfer', 'completed'),

    (1, 'LP-10002', 551.00,
     453.00, 98.00,
     '2026-09-01', 'online', 'completed'),

    (2, 'LP-10003', 995.00,
     690.00, 305.00,
     '2026-09-01', 'bank_transfer', 'completed'),

    (3, 'LP-10004', 436.00,
     404.00, 32.00,
     '2026-09-01', 'card', 'completed');


INSERT INTO transfers
    (from_account_id, to_account_id, transfer_reference,
     amount, description, transfer_date, status)
VALUES
    (1, 3, 'TRF-10001',
     500.00, 'Personal transfer',
     '2026-09-03 11:30:00', 'completed'),

    (3, 1, 'TRF-10002',
     750.00, 'Personal transfer',
     '2026-09-04 16:00:00', 'completed'),

    (2, 4, 'TRF-10003',
     1000.00, 'Savings transfer',
     '2026-09-06 12:00:00', 'completed');


-- ============================================================
-- Views
-- ============================================================

CREATE VIEW customer_accounts AS
SELECT
    c.customer_id,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    a.account_id,
    a.account_number,
    at.name AS account_type,
    a.balance,
    b.name AS branch_name,
    b.city,
    a.status AS account_status
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN account_types at
    ON a.account_type_id = at.account_type_id
JOIN branches b
    ON a.branch_id = b.branch_id;


CREATE VIEW account_transaction_history AS
SELECT
    t.transaction_id,
    a.account_number,
    t.transaction_reference,
    t.transaction_type,
    t.amount,
    t.description,
    t.transaction_date,
    t.status,
    ra.account_number AS related_account_number
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
LEFT JOIN accounts ra
    ON t.related_account_id = ra.account_id;


CREATE VIEW active_loans AS
SELECT
    l.loan_id,
    l.loan_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    l.loan_type,
    l.principal_amount,
    l.interest_rate,
    l.term_months,
    l.monthly_payment,
    l.outstanding_balance,
    l.start_date,
    l.end_date,
    l.status
FROM loans l
JOIN customers c
    ON l.customer_id = c.customer_id
WHERE l.status = 'active';


CREATE VIEW loan_payment_history AS
SELECT
    lp.loan_payment_id,
    l.loan_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    lp.payment_reference,
    lp.amount,
    lp.principal_paid,
    lp.interest_paid,
    lp.payment_date,
    lp.payment_method,
    lp.status
FROM loan_payments lp
JOIN loans l
    ON lp.loan_id = l.loan_id
JOIN customers c
    ON l.customer_id = c.customer_id;


CREATE VIEW branch_summary AS
SELECT
    b.branch_id,
    b.branch_code,
    b.name AS branch_name,
    b.city,
    COUNT(DISTINCT a.account_id) AS account_count,
    COUNT(DISTINCT e.employee_id) AS employee_count,
    COALESCE(SUM(a.balance), 0) AS total_account_balance
FROM branches b
LEFT JOIN accounts a
    ON b.branch_id = a.branch_id
    AND a.status <> 'closed'
LEFT JOIN employees e
    ON b.branch_id = e.branch_id
    AND e.status = 'active'
GROUP BY
    b.branch_id,
    b.branch_code,
    b.name,
    b.city;


CREATE VIEW customer_loan_summary AS
SELECT
    c.customer_id,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(l.loan_id) AS loan_count,
    COALESCE(
        SUM(
            CASE
                WHEN l.status = 'active'
                THEN l.outstanding_balance
                ELSE 0
            END
        ),
        0
    ) AS total_outstanding_balance
FROM customers c
LEFT JOIN loans l
    ON c.customer_id = l.customer_id
GROUP BY
    c.customer_id,
    c.customer_number,
    c.first_name,
    c.last_name;


-- ============================================================
-- Example Queries
-- ============================================================

-- List all active customer accounts
SELECT *
FROM customer_accounts
WHERE account_status = 'active'
ORDER BY customer_name;


-- Find customers with total balances above 10000
SELECT
    customer_id,
    customer_number,
    customer_name,
    SUM(balance) AS total_balance
FROM customer_accounts
GROUP BY
    customer_id,
    customer_number,
    customer_name
HAVING SUM(balance) > 10000
ORDER BY total_balance DESC;


-- Transaction history for one account
SELECT *
FROM account_transaction_history
WHERE account_number = 'ACC-1000001'
ORDER BY transaction_date DESC;


-- All active loans
SELECT *
FROM active_loans
ORDER BY outstanding_balance DESC;


-- Loan payment history
SELECT *
FROM loan_payment_history
ORDER BY payment_date DESC;


-- Customers with active loans
SELECT *
FROM customer_loan_summary
WHERE total_outstanding_balance > 0
ORDER BY total_outstanding_balance DESC;


-- Branch statistics
SELECT *
FROM branch_summary
ORDER BY total_account_balance DESC;


-- Total money held by the bank
SELECT
    SUM(balance) AS total_deposits
FROM accounts
WHERE status <> 'closed';


-- Transaction volume by type
SELECT
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
WHERE status = 'completed'
GROUP BY transaction_type
ORDER BY total_amount DESC;


-- Total loan portfolio
SELECT
    SUM(principal_amount) AS total_principal,
    SUM(outstanding_balance) AS total_outstanding
FROM loans
WHERE status = 'active';


-- Customers with more than one account
SELECT
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(a.account_id) AS account_count
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
WHERE a.status = 'active'
GROUP BY
    c.customer_id,
    c.customer_number,
    c.first_name,
    c.last_name
HAVING COUNT(a.account_id) > 1
ORDER BY account_count DESC;


-- Monthly loan payment totals
SELECT
    DATE_FORMAT(payment_date, '%Y-%m') AS payment_month,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_paid,
    SUM(principal_paid) AS total_principal_paid,
    SUM(interest_paid) AS total_interest_paid
FROM loan_payments
WHERE status = 'completed'
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY payment_month;


-- Active cards
SELECT
    c.card_number,
    c.card_type,
    a.account_number,
    CONCAT(cu.first_name, ' ', cu.last_name) AS customer_name,
    c.expiry_date,
    c.daily_limit,
    c.status
FROM cards c
JOIN accounts a
    ON c.account_id = a.account_id
JOIN customers cu
    ON a.customer_id = cu.customer_id
WHERE c.status = 'active'
ORDER BY c.expiry_date;