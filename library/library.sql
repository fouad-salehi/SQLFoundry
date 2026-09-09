-- ============================================================
-- SQLFoundry - Library Management System
-- Database: MySQL 8.0+
-- File: library.sql
-- ============================================================

DROP DATABASE IF EXISTS library_db;

CREATE DATABASE library_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE library_db;

-- ============================================================
-- 1. AUTHORS
-- ============================================================

CREATE TABLE authors (
    author_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE NULL,
    death_date DATE NULL,
    biography TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_author_dates
        CHECK (
            death_date IS NULL
            OR birth_date IS NULL
            OR death_date >= birth_date
        ),

    INDEX idx_authors_name (last_name, first_name)
) ENGINE=InnoDB;


-- ============================================================
-- 2. PUBLISHERS
-- ============================================================

CREATE TABLE publishers (
    publisher_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(30) NULL,
    website VARCHAR(500) NULL,
    address VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_publishers_name (name)
) ENGINE=InnoDB;


-- ============================================================
-- 3. CATEGORIES
-- ============================================================

CREATE TABLE categories (
    category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NULL,

    UNIQUE KEY uq_categories_name (name)
) ENGINE=InnoDB;


-- ============================================================
-- 4. BOOKS
-- ============================================================

CREATE TABLE books (
    book_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL,
    title VARCHAR(300) NOT NULL,
    subtitle VARCHAR(300) NULL,
    publisher_id INT UNSIGNED NULL,
    category_id INT UNSIGNED NULL,
    publication_date DATE NULL,
    edition VARCHAR(50) NULL,
    language_code VARCHAR(10) NOT NULL DEFAULT 'en',
    page_count INT UNSIGNED NULL,
    description TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_books_isbn (isbn),

    INDEX idx_books_title (title),
    INDEX idx_books_publisher (publisher_id),
    INDEX idx_books_category (category_id),

    CONSTRAINT fk_books_publisher
        FOREIGN KEY (publisher_id)
        REFERENCES publishers (publisher_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_books_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_books_page_count
        CHECK (page_count IS NULL OR page_count > 0)
) ENGINE=InnoDB;


-- ============================================================
-- 5. BOOK AUTHORS
-- Many-to-Many relationship between books and authors
-- ============================================================

CREATE TABLE book_authors (
    book_id INT UNSIGNED NOT NULL,
    author_id INT UNSIGNED NOT NULL,
    author_order TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (book_id, author_id),

    INDEX idx_book_authors_author (author_id),

    CONSTRAINT fk_book_authors_book
        FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_book_authors_author
        FOREIGN KEY (author_id)
        REFERENCES authors (author_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;


-- ============================================================
-- 6. MEMBERS
-- ============================================================

CREATE TABLE members (
    member_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    membership_number VARCHAR(30) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(30) NULL,
    address VARCHAR(500) NULL,
    date_of_birth DATE NULL,
    joined_at DATE NOT NULL DEFAULT (CURRENT_DATE),
    status ENUM('active', 'suspended', 'expired') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_membership_number (membership_number),
    UNIQUE KEY uq_members_email (email),

    INDEX idx_members_name (last_name, first_name),
    INDEX idx_members_status (status)
) ENGINE=InnoDB;


-- ============================================================
-- 7. LIBRARIANS
-- ============================================================

CREATE TABLE librarians (
    librarian_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    employee_number VARCHAR(30) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NULL,
    phone VARCHAR(30) NULL,
    hired_at DATE NOT NULL,
    status ENUM('active', 'inactive') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_librarians_employee_number (employee_number),
    UNIQUE KEY uq_librarians_email (email),

    INDEX idx_librarians_name (last_name, first_name)
) ENGINE=InnoDB;


-- ============================================================
-- 8. SHELVES
-- ============================================================

CREATE TABLE shelves (
    shelf_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30) NOT NULL,
    section VARCHAR(100) NOT NULL,
    floor_number TINYINT UNSIGNED NOT NULL DEFAULT 1,
    description VARCHAR(500) NULL,

    UNIQUE KEY uq_shelves_code (code),

    INDEX idx_shelves_section (section)
) ENGINE=InnoDB;


-- ============================================================
-- 9. BOOK COPIES
-- A book can have multiple physical copies
-- ============================================================

CREATE TABLE book_copies (
    copy_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    book_id INT UNSIGNED NOT NULL,
    barcode VARCHAR(50) NOT NULL,
    shelf_id INT UNSIGNED NULL,
    acquisition_date DATE NULL,
    price DECIMAL(10, 2) NULL,
    condition_status ENUM(
        'new',
        'good',
        'fair',
        'damaged',
        'lost'
    ) NOT NULL DEFAULT 'good',
    availability_status ENUM(
        'available',
        'borrowed',
        'reserved',
        'maintenance',
        'lost'
    ) NOT NULL DEFAULT 'available',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_book_copies_barcode (barcode),

    INDEX idx_book_copies_book (book_id),
    INDEX idx_book_copies_shelf (shelf_id),
    INDEX idx_book_copies_status (availability_status),

    CONSTRAINT fk_book_copies_book
        FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_book_copies_shelf
        FOREIGN KEY (shelf_id)
        REFERENCES shelves (shelf_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_book_copy_price
        CHECK (price IS NULL OR price >= 0)
) ENGINE=InnoDB;


-- ============================================================
-- 10. LOANS
-- ============================================================

CREATE TABLE loans (
    loan_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    copy_id INT UNSIGNED NOT NULL,
    member_id INT UNSIGNED NOT NULL,
    librarian_id INT UNSIGNED NULL,
    borrowed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_at DATETIME NOT NULL,
    returned_at DATETIME NULL,
    renewal_count TINYINT UNSIGNED NOT NULL DEFAULT 0,
    notes VARCHAR(500) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_loans_copy (copy_id),
    INDEX idx_loans_member (member_id),
    INDEX idx_loans_librarian (librarian_id),
    INDEX idx_loans_due_date (due_at),
    INDEX idx_loans_returned (returned_at),

    CONSTRAINT fk_loans_copy
        FOREIGN KEY (copy_id)
        REFERENCES book_copies (copy_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_loans_member
        FOREIGN KEY (member_id)
        REFERENCES members (member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_loans_librarian
        FOREIGN KEY (librarian_id)
        REFERENCES librarians (librarian_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT chk_loans_dates
        CHECK (
            returned_at IS NULL
            OR returned_at >= borrowed_at
        ),

    CONSTRAINT chk_loans_due_date
        CHECK (due_at >= borrowed_at)
) ENGINE=InnoDB;


-- ============================================================
-- 11. RESERVATIONS
-- ============================================================

CREATE TABLE reservations (
    reservation_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    book_id INT UNSIGNED NOT NULL,
    member_id INT UNSIGNED NOT NULL,
    reserved_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME NULL,
    fulfilled_at DATETIME NULL,
    status ENUM(
        'pending',
        'fulfilled',
        'cancelled',
        'expired'
    ) NOT NULL DEFAULT 'pending',

    INDEX idx_reservations_book (book_id),
    INDEX idx_reservations_member (member_id),
    INDEX idx_reservations_status (status),
    INDEX idx_reservations_queue (book_id, status, reserved_at),

    CONSTRAINT fk_reservations_book
        FOREIGN KEY (book_id)
        REFERENCES books (book_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_reservations_member
        FOREIGN KEY (member_id)
        REFERENCES members (member_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT chk_reservations_dates
        CHECK (
            expires_at IS NULL
            OR expires_at >= reserved_at
        )
) ENGINE=InnoDB;


-- ============================================================
-- 12. FINES
-- ============================================================

CREATE TABLE fines (
    fine_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    loan_id INT UNSIGNED NOT NULL,
    member_id INT UNSIGNED NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    reason ENUM(
        'late_return',
        'damage',
        'lost_book',
        'other'
    ) NOT NULL,
    issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at DATETIME NULL,
    status ENUM(
        'unpaid',
        'partially_paid',
        'paid',
        'waived'
    ) NOT NULL DEFAULT 'unpaid',
    notes VARCHAR(500) NULL,

    INDEX idx_fines_loan (loan_id),
    INDEX idx_fines_member (member_id),
    INDEX idx_fines_status (status),

    CONSTRAINT fk_fines_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans (loan_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_fines_member
        FOREIGN KEY (member_id)
        REFERENCES members (member_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_fines_amount
        CHECK (amount > 0)
) ENGINE=InnoDB;


-- ============================================================
-- 13. SAMPLE AUTHORS
-- ============================================================

INSERT INTO authors
    (first_name, last_name, birth_date, biography)
VALUES
    ('George', 'Orwell', '1903-06-25',
     'English novelist and essayist.'),

    ('Jane', 'Austen', '1775-12-16',
     'English novelist known for her works on social commentary.'),

    ('Fyodor', 'Dostoevsky', '1821-11-11',
     'Russian novelist and philosopher.'),

    ('Gabriel', 'García Márquez', '1927-03-06',
     'Colombian novelist and Nobel Prize winner.'),

    ('Haruki', 'Murakami', '1949-01-12',
     'Japanese novelist and short-story writer.'),

    ('J. R. R.', 'Tolkien', '1892-01-03',
     'English writer and philologist.'),

    ('Frank', 'Herbert', '1920-10-08',
     'American science-fiction author.');


-- ============================================================
-- 14. SAMPLE PUBLISHERS
-- ============================================================

INSERT INTO publishers
    (name, email, phone, website, address)
VALUES
    ('Penguin Classics',
     'contact@penguin.example',
     '+1-555-100-1000',
     'https://example.com/penguin',
     'London, UK'),

    ('Vintage Books',
     'contact@vintage.example',
     '+1-555-200-2000',
     'https://example.com/vintage',
     'New York, USA'),

    ('HarperCollins',
     'contact@harpercollins.example',
     '+1-555-300-3000',
     'https://example.com/harpercollins',
     'New York, USA'),

    ('Modern Library',
     'contact@modernlibrary.example',
     '+1-555-400-4000',
     'https://example.com/modern-library',
     'New York, USA');


-- ============================================================
-- 15. SAMPLE CATEGORIES
-- ============================================================

INSERT INTO categories
    (name, description)
VALUES
    ('Classic Literature', 'Classic works of literature.'),
    ('Fiction', 'Fictional stories and novels.'),
    ('Science Fiction', 'Science-fiction and speculative fiction.'),
    ('Philosophy', 'Philosophy and philosophical literature.'),
    ('History', 'Historical books and studies.'),
    ('Technology', 'Books about computing and technology.');


-- ============================================================
-- 16. SAMPLE BOOKS
-- ============================================================

INSERT INTO books
    (
        isbn,
        title,
        subtitle,
        publisher_id,
        category_id,
        publication_date,
        edition,
        language_code,
        page_count,
        description
    )
VALUES
    (
        '9780451524935',
        '1984',
        NULL,
        1,
        1,
        '1949-06-08',
        'Classic Edition',
        'en',
        328,
        'A dystopian novel about surveillance and totalitarianism.'
    ),

    (
        '9780141439518',
        'Pride and Prejudice',
        NULL,
        1,
        1,
        '1813-01-28',
        'Classic Edition',
        'en',
        432,
        'A classic novel of manners, relationships and social class.'
    ),

    (
        '9780140449242',
        'Crime and Punishment',
        NULL,
        1,
        1,
        '1866-01-01',
        'Classic Edition',
        'en',
        671,
        'A psychological novel exploring morality and guilt.'
    ),

    (
        '9780060883287',
        'One Hundred Years of Solitude',
        NULL,
        3,
        2,
        '1967-05-30',
        'Reissue',
        'en',
        417,
        'A multigenerational story centered on the Buendía family.'
    ),

    (
        '9780307387899',
        'The Wind-Up Bird Chronicle',
        NULL,
        2,
        2,
        '1994-01-01',
        'Reissue',
        'en',
        607,
        'A surreal novel combining mystery, memory and history.'
    ),

    (
        '9780544003415',
        'The Hobbit',
        NULL,
        3,
        2,
        '1937-09-21',
        'Illustrated Edition',
        'en',
        310,
        'A fantasy adventure following Bilbo Baggins.'
    ),

    (
        '9780441172719',
        'Dune',
        NULL,
        3,
        3,
        '1965-08-01',
        'Classic Edition',
        'en',
        688,
        'A science-fiction novel set on the desert planet Arrakis.'
    );


-- ============================================================
-- 17. BOOK AUTHORS
-- ============================================================

INSERT INTO book_authors
    (book_id, author_id, author_order)
VALUES
    (1, 1, 1),
    (2, 2, 1),
    (3, 3, 1),
    (4, 4, 1),
    (5, 5, 1),
    (6, 6, 1),
    (7, 7, 1);


-- ============================================================
-- 18. SAMPLE SHELVES
-- ============================================================

INSERT INTO shelves
    (code, section, floor_number, description)
VALUES
    ('A-01', 'Classic Literature', 1, 'Classic literature collection.'),
    ('A-02', 'Classic Literature', 1, 'Classic literature collection.'),
    ('B-01', 'Fiction', 1, 'General fiction collection.'),
    ('C-01', 'Science Fiction', 2, 'Science-fiction collection.'),
    ('D-01', 'Philosophy', 2, 'Philosophy collection.');


-- ============================================================
-- 19. SAMPLE BOOK COPIES
-- ============================================================

INSERT INTO book_copies
    (
        book_id,
        barcode,
        shelf_id,
        acquisition_date,
        price,
        condition_status,
        availability_status
    )
VALUES
    (1, 'LIB-1984-001', 1, '2025-01-10', 15.99, 'good', 'available'),
    (1, 'LIB-1984-002', 1, '2025-01-10', 15.99, 'good', 'available'),
    (1, 'LIB-1984-003', 1, '2025-03-15', 15.99, 'fair', 'borrowed'),

    (2, 'LIB-PNP-001', 1, '2025-01-15', 14.99, 'good', 'available'),
    (2, 'LIB-PNP-002', 1, '2025-01-15', 14.99, 'good', 'available'),

    (3, 'LIB-CNP-001', 2, '2025-02-01', 17.99, 'good', 'available'),

    (4, 'LIB-100Y-001', 3, '2025-02-10', 18.99, 'good', 'available'),
    (4, 'LIB-100Y-002', 3, '2025-02-10', 18.99, 'good', 'borrowed'),

    (5, 'LIB-WBC-001', 3, '2025-03-01', 19.99, 'new', 'available'),

    (6, 'LIB-HOB-001', 3, '2025-03-05', 21.99, 'good', 'available'),
    (6, 'LIB-HOB-002', 3, '2025-03-05', 21.99, 'good', 'reserved'),

    (7, 'LIB-DUN-001', 4, '2025-03-20', 22.99, 'new', 'available'),
    (7, 'LIB-DUN-002', 4, '2025-03-20', 22.99, 'good', 'available');


-- ============================================================
-- 20. SAMPLE MEMBERS
-- ============================================================

INSERT INTO members
    (
        membership_number,
        first_name,
        last_name,
        email,
        phone,
        address,
        date_of_birth,
        joined_at,
        status
    )
VALUES
    (
        'MEM-0001',
        'John',
        'Carter',
        'john.carter@example.com',
        '+1-555-0101',
        '12 Oak Street',
        '1995-04-12',
        '2025-01-05',
        'active'
    ),

    (
        'MEM-0002',
        'Emma',
        'Wilson',
        'emma.wilson@example.com',
        '+1-555-0102',
        '45 Pine Avenue',
        '1998-09-21',
        '2025-01-12',
        'active'
    ),

    (
        'MEM-0003',
        'Daniel',
        'Brown',
        'daniel.brown@example.com',
        '+1-555-0103',
        '78 River Road',
        '1992-02-18',
        '2025-02-03',
        'active'
    ),

    (
        'MEM-0004',
        'Sophia',
        'Taylor',
        'sophia.taylor@example.com',
        '+1-555-0104',
        '9 Green Lane',
        '2000-11-05',
        '2025-02-20',
        'suspended'
    ),

    (
        'MEM-0005',
        'Michael',
        'Anderson',
        'michael.anderson@example.com',
        '+1-555-0105',
        '22 Lake Road',
        '1989-07-30',
        '2025-03-01',
        'active'
    );


-- ============================================================
-- 21. SAMPLE LIBRARIANS
-- ============================================================

INSERT INTO librarians
    (
        employee_number,
        first_name,
        last_name,
        email,
        phone,
        hired_at,
        status
    )
VALUES
    (
        'EMP-001',
        'Olivia',
        'Martin',
        'olivia.martin@example.com',
        '+1-555-0201',
        '2024-01-10',
        'active'
    ),

    (
        'EMP-002',
        'James',
        'Thompson',
        'james.thompson@example.com',
        '+1-555-0202',
        '2024-06-15',
        'active'
    );


-- ============================================================
-- 22. SAMPLE LOANS
-- ============================================================

INSERT INTO loans
    (
        copy_id,
        member_id,
        librarian_id,
        borrowed_at,
        due_at,
        returned_at,
        renewal_count,
        notes
    )
VALUES
    (
        3,
        1,
        1,
        '2026-09-01 10:00:00',
        '2026-09-15 18:00:00',
        NULL,
        0,
        'Currently borrowed.'
    ),

    (
        8,
        2,
        2,
        '2026-09-03 14:30:00',
        '2026-09-17 18:00:00',
        NULL,
        1,
        'Renewed once.'
    ),

    (
        1,
        3,
        1,
        '2026-08-01 11:00:00',
        '2026-08-15 18:00:00',
        '2026-08-12 16:20:00',
        0,
        'Returned on time.'
    );


-- ============================================================
-- 23. SAMPLE RESERVATIONS
-- ============================================================

INSERT INTO reservations
    (
        book_id,
        member_id,
        reserved_at,
        expires_at,
        fulfilled_at,
        status
    )
VALUES
    (
        6,
        5,
        '2026-09-07 12:00:00',
        '2026-09-14 18:00:00',
        NULL,
        'pending'
    ),

    (
        1,
        2,
        '2026-08-20 09:30:00',
        '2026-08-27 18:00:00',
        '2026-08-22 15:00:00',
        'fulfilled'
    );


-- ============================================================
-- 24. SAMPLE FINES
-- ============================================================

INSERT INTO fines
    (
        loan_id,
        member_id,
        amount,
        reason,
        issued_at,
        paid_at,
        status,
        notes
    )
VALUES
    (
        3,
        3,
        5.00,
        'late_return',
        '2026-08-16 09:00:00',
        '2026-08-16 10:30:00',
        'paid',
        'Returned one day after the due date.'
    );


-- ============================================================
-- 25. VIEWS
-- ============================================================

CREATE VIEW available_books AS
SELECT
    b.book_id,
    b.isbn,
    b.title,
    c.name AS category,
    COUNT(bc.copy_id) AS available_copies
FROM books b
LEFT JOIN categories c
    ON c.category_id = b.category_id
LEFT JOIN book_copies bc
    ON bc.book_id = b.book_id
    AND bc.availability_status = 'available'
GROUP BY
    b.book_id,
    b.isbn,
    b.title,
    c.name;


CREATE VIEW active_loans AS
SELECT
    l.loan_id,
    bc.barcode,
    b.title,
    m.member_id,
    m.membership_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    l.borrowed_at,
    l.due_at,
    CASE
        WHEN l.due_at < CURRENT_TIMESTAMP THEN 'overdue'
        ELSE 'active'
    END AS loan_status
FROM loans l
INNER JOIN book_copies bc
    ON bc.copy_id = l.copy_id
INNER JOIN books b
    ON b.book_id = bc.book_id
INNER JOIN members m
    ON m.member_id = l.member_id
WHERE l.returned_at IS NULL;


CREATE VIEW book_catalog AS
SELECT
    b.book_id,
    b.isbn,
    b.title,
    b.subtitle,
    CONCAT(a.first_name, ' ', a.last_name) AS author_name,
    p.name AS publisher,
    c.name AS category,
    b.publication_date,
    b.edition,
    b.language_code,
    b.page_count,
    COUNT(bc.copy_id) AS total_copies,
    SUM(
        CASE
            WHEN bc.availability_status = 'available'
            THEN 1
            ELSE 0
        END
    ) AS available_copies
FROM books b
LEFT JOIN book_authors ba
    ON ba.book_id = b.book_id
LEFT JOIN authors a
    ON a.author_id = ba.author_id
LEFT JOIN publishers p
    ON p.publisher_id = b.publisher_id
LEFT JOIN categories c
    ON c.category_id = b.category_id
LEFT JOIN book_copies bc
    ON bc.book_id = b.book_id
GROUP BY
    b.book_id,
    b.isbn,
    b.title,
    b.subtitle,
    a.first_name,
    a.last_name,
    p.name,
    c.name,
    b.publication_date,
    b.edition,
    b.language_code,
    b.page_count;


-- ============================================================
-- 26. EXAMPLE BUSINESS QUERIES
-- ============================================================

-- List all books
SELECT
    book_id,
    title,
    isbn
FROM books
ORDER BY title;


-- Find available books
SELECT *
FROM available_books
WHERE available_copies > 0
ORDER BY title;


-- Currently borrowed books
SELECT *
FROM active_loans
ORDER BY due_at;


-- Overdue books
SELECT *
FROM active_loans
WHERE loan_status = 'overdue'
ORDER BY due_at;


-- Most borrowed books
SELECT
    b.book_id,
    b.title,
    COUNT(l.loan_id) AS borrow_count
FROM books b
INNER JOIN book_copies bc
    ON bc.book_id = b.book_id
INNER JOIN loans l
    ON l.copy_id = bc.copy_id
GROUP BY
    b.book_id,
    b.title
ORDER BY borrow_count DESC, b.title;


-- Most active members
SELECT
    m.member_id,
    m.membership_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    COUNT(l.loan_id) AS total_loans
FROM members m
LEFT JOIN loans l
    ON l.member_id = m.member_id
GROUP BY
    m.member_id,
    m.membership_number,
    m.first_name,
    m.last_name
ORDER BY total_loans DESC, member_name;


-- Unpaid fines
SELECT
    f.fine_id,
    f.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    f.amount,
    f.reason,
    f.issued_at
FROM fines f
INNER JOIN members m
    ON m.member_id = f.member_id
WHERE f.status IN ('unpaid', 'partially_paid')
ORDER BY f.issued_at;


-- Books currently reserved
SELECT
    r.reservation_id,
    b.title,
    m.membership_number,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    r.reserved_at,
    r.status
FROM reservations r
INNER JOIN books b
    ON b.book_id = r.book_id
INNER JOIN members m
    ON m.member_id = r.member_id
WHERE r.status = 'pending'
ORDER BY r.reserved_at;


-- ============================================================
-- END OF SQLFoundry - Library Management System
-- ============================================================