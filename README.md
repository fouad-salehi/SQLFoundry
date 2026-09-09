# SQLFoundry

![SQLFoundry](https://img.shields.io/badge/project-SQLFoundry-important)
![Database](https://img.shields.io/badge/database-MySQL%208.0%2B-blue)
![Language](https://img.shields.io/badge/language-SQL-orange)
![Type](https://img.shields.io/badge/type-relational%20database-green)
![Projects](https://img.shields.io/badge/projects-12-success)
![License](https://img.shields.io/badge/license-MIT-green)

**SQLFoundry — A collection of standalone relational database systems built with MySQL.**

SQLFoundry is a collection of practical, independent database projects designed around real-world systems. Each project focuses on relational database design, data integrity, normalization, constraints, indexing, reporting, and practical SQL usage.

---

## Overview

SQLFoundry is built to demonstrate how complete relational database systems can be designed for different real-world domains.

Every project is an independent MySQL database containing:

* Database schema
* Related entities and relationships
* Primary and foreign keys
* Unique and check constraints
* Indexes
* Referential integrity
* Realistic sample data
* SQL views
* Example queries

The projects are intentionally independent and can be installed, tested, and explored separately.

## Projects

| Project                   | Domain                | Description                                                               |
| ------------------------- | --------------------- | ------------------------------------------------------------------------- |
| [Library](library/)       | Library Management    | Books, authors, members, loans, reservations, copies, and fines           |
| [Gym](gym/)               | Fitness Management    | Members, trainers, memberships, classes, attendance, and workouts         |
| [Restaurant](restaurant/) | Restaurant Management | Customers, employees, tables, orders, reservations, and inventory         |
| [Hotel](hotel/)           | Hotel Management      | Rooms, guests, reservations, services, invoices, and payments             |
| [E-commerce](ecommerce/)  | E-commerce            | Products, customers, inventory, orders, reviews, and payments             |
| [Hospital](hospital/)     | Healthcare            | Patients, doctors, appointments, prescriptions, admissions, and billing   |
| [School](school/)         | Education             | Students, teachers, courses, classes, attendance, exams, and grades       |
| [Banking](banking/)       | Banking               | Accounts, cards, transactions, transfers, loans, and payments             |
| [Car Rental](car-rental/) | Vehicle Rental        | Vehicles, customers, reservations, rentals, insurance, and maintenance    |
| [Inventory](inventory/)   | Warehouse Management  | Products, warehouses, suppliers, stock, purchases, and transfers          |
| [Cinema](cinema/)         | Cinema Management     | Movies, halls, seats, showtimes, bookings, tickets, and payments          |
| [Airport](airport/)       | Airport Management    | Flights, airlines, aircraft, passengers, bookings, baggage, and check-ins |


## Project Highlights

### Library

A library management system for handling books, authors, publishers, members, librarians, physical copies, loans, reservations, and fines.

**Key concepts:**

* Book and author relationships
* Physical copy tracking
* Loan management
* Reservations
* Fine management
* Book availability

[View Project](library/)


### Gym

A gym management system covering members, trainers, membership plans, payments, classes, attendance, exercises, and workout plans.

**Key concepts:**

* Member and trainer management
* Membership plans
* Class scheduling
* Enrollment and attendance
* Exercise management
* Workout plans

[View Project](gym/)


### Restaurant

A restaurant database designed around customers, employees, tables, menus, orders, reservations, suppliers, ingredients, and payments.

**Key concepts:**

* Menu and category management
* Table management
* Order processing
* Reservations
* Supplier management
* Ingredient and inventory data
* Payment tracking

[View Project](restaurant/)


### Hotel

A hotel management system for rooms, guests, employees, reservations, services, invoices, and payments.

**Key concepts:**

* Room and room type management
* Guest management
* Reservations
* Multiple guests per reservation
* Hotel services
* Service orders
* Invoicing and payments
* Room availability

[View Project](hotel/)


### E-commerce

An e-commerce database covering products, categories, customers, addresses, inventory, coupons, orders, reviews, and payments.

**Key concepts:**

* Product catalog
* Customer accounts
* Addresses
* Inventory management
* Coupons
* Orders and order items
* Product reviews
* Payment tracking
* Stock monitoring

[View Project](ecommerce/)


### Hospital

A hospital management system covering departments, doctors, patients, appointments, medical records, medications, prescriptions, admissions, rooms, bills, and payments.

**Key concepts:**

* Department management
* Doctor and patient records
* Appointments
* Medical records
* Prescriptions
* Hospital rooms
* Patient admissions
* Billing and payments

[View Project](hospital/)


### School

A school management database designed around academic years, departments, students, teachers, courses, classrooms, classes, enrollments, attendance, exams, grades, and payments.

**Key concepts:**

* Academic year management
* Student and teacher management
* Departments and courses
* Class scheduling
* Classroom management
* Enrollment
* Attendance
* Exams and grades
* Payment tracking

[View Project](school/)


### Banking

A banking management system covering branches, customers, employees, account types, accounts, beneficiaries, cards, transactions, loans, loan payments, and transfers.

**Key concepts:**

* Branch management
* Account management
* Beneficiaries
* Bank cards
* Transactions
* Transfers
* Loans
* Loan payments
* Financial reporting

[View Project](banking/)


### Car Rental

A vehicle rental management system for branches, customers, vehicle categories, vehicles, reservations, rentals, insurance, payments, and maintenance.

**Key concepts:**

* Rental branches
* Vehicle categories
* Vehicle inventory
* Reservations
* Rental contracts
* Insurance plans
* Payments
* Maintenance records

[View Project](car-rental/)


### Inventory

An inventory and warehouse management system covering categories, suppliers, warehouses, products, stock levels, purchase orders, transfers, and stock transactions.

**Key concepts:**

* Product management
* Categories
* Suppliers
* Warehouses
* Stock tracking
* Purchase orders
* Stock transfers
* Stock transactions
* Low-stock monitoring
* Warehouse valuation

[View Project](inventory/)


### Cinema

A cinema management system designed around cinemas, halls, seats, movies, genres, customers, showtimes, bookings, tickets, and payments.

**Key concepts:**

* Cinema and hall management
* Seat management
* Movies and genres
* Showtime scheduling
* Customer management
* Bookings
* Ticket sales
* Revenue reporting

[View Project](cinema/)


### Airport

An airport management system covering airports, terminals, gates, airlines, aircraft, routes, flights, passengers, bookings, tickets, baggage, check-ins, employees, and payments.

**Key concepts:**

* Airport and terminal management
* Gate management
* Airline management
* Aircraft fleet management
* Routes and flight schedules
* Passenger management
* Bookings and tickets
* Baggage tracking
* Passenger check-ins
* Employee management
* Payment tracking

[View Project](airport/)


## Features

* MySQL 8.0+
* Normalized relational schemas
* Primary and foreign keys
* Unique constraints
* Check constraints
* Referential integrity
* Indexed columns
* Realistic sample data
* SQL views
* Practical SQL queries
* Independent database systems
* Consistent project structure


## Database Design

SQLFoundry focuses on practical relational database engineering.

Core design principles include:

* Entity relationships
* Database normalization
* Referential integrity
* Data validation
* Constraint-based design
* Indexing
* Query organization
* Reporting views
* Practical SQL operations

The projects are designed to demonstrate how multiple related entities can work together as a complete database system rather than as isolated SQL examples.


## Project Structure

Each project follows a consistent structure:

```text
project/
├── README.md
├── LICENSE
└── project.sql
```

Each project is completely independent from the others.


## Getting Started

### Requirements

* MySQL 8.0 or later

### Installation

Clone the repository:

```bash
git clone https://github.com/fouad-salehi/SQLFoundry.git
cd SQLFoundry
```

Choose a project:

```bash
cd airport
```

Run the SQL script:

```bash
mysql -u your_username -p < airport.sql
```

The SQL script creates the required database, tables, relationships, constraints, indexes, sample data, and views.

The same process can be used for any project in the collection.


## Usage

Each database can be explored independently using MySQL or any compatible database management tool.

After importing a project, you can inspect:

* Tables
* Relationships
* Constraints
* Indexes
* Sample records
* Views
* Example queries

Refer to the individual project's `README.md` for project-specific documentation.


## Design Philosophy

> **Build the database. Understand the system.**

SQLFoundry is based on the idea that learning relational databases is more effective when working with complete systems.

Instead of isolated SQL exercises, each project models a different real-world domain and provides a structured environment for exploring database architecture, relationships, constraints, queries, and reporting.


## Author

**Fouad Salehi**

GitHub: [github.com/fouad-salehi](https://github.com/fouad-salehi)


## License

MIT License

Copyright (c) 2026 Fouad Salehi
