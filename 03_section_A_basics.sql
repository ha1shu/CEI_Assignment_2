-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 03_section_A_basics.sql
--  SECTION A: SQL Basics — SELECT, Constraints, Primary Keys


USE shopease;

-- ============================================================
-- Q1: Display all columns and rows from the customers table
-- Concept: SELECT * retrieves every column and every row

SELECT * FROM customers;

/*
  Expected Output (8 rows):
  customer_id | first_name | last_name | email              | city      | state       | join_date  | is_premium
  ----------------------------------------------------------------------------------------------------
  101         | Aarav      | Sharma    | aarav.s@email.com  | Mumbai    | Maharashtra | 2024-01-15 | 1
  102         | Priya      | Patel     | priya.p@email.com  | Ahmedabad | Gujarat     | 2024-02-20 | 0
  ... (8 rows total)
*/


-- ============================================================
-- Q2: Retrieve only first_name, last_name, and city
-- Concept: Column projection — select only what you need


SELECT first_name, last_name, city
FROM customers;

/*
  Expected Output (8 rows, 3 columns only):
  first_name | last_name | city
  ------------------------------
  Aarav      | Sharma    | Mumbai
  Priya      | Patel     | Ahmedabad
  ... (8 rows total)
*/


-- ============================================================
-- Q3: List all unique categories available in the products table

-- Concept: DISTINCT removes duplicate values from the result
-- Without DISTINCT we would see: Electronics, Clothing, Electronics,Clothing, Electronics, Home, Electronics, Home — 8 rows with repeats


SELECT DISTINCT category
FROM products;

/*
  Expected Output (3 rows — no duplicates):
  category
  -----------
  Electronics
  Clothing
  Home
*/


-- ============================================================
-- Q4: Primary Keys of each table — identification + explanation
-- Concept: A PRIMARY KEY uniquely identifies every row in a table.
--          It must be UNIQUE (no two rows share the same value) and
--          NOT NULL (every row must have an identity).


/*
  PRIMARY KEYS IN THIS SCHEMA:
  +--------------+------------------+-----------+
  | Table        | Primary Key      | Data Type |
  +--------------+------------------+-----------+
  | customers    | customer_id      | INT       |
  | products     | product_id       | INT       |
  | orders       | order_id         | INT       |
  | order_items  | item_id          | INT       |
  +--------------+------------------+-----------+

  WHY must a Primary Key be UNIQUE and NOT NULL?

  1. UNIQUE: If two rows had the same customer_id (e.g. both are 101),
     the database cannot distinguish which customer placed an order.
     Foreign key references would be ambiguous and data integrity
     would break.

  2. NOT NULL: A row with NULL as its primary key has no identity.
     It cannot be referenced by any other table. NULL also cannot
     be compared reliably (NULL != NULL in SQL), making lookups
     impossible.

  Real-world analogy: Think of a Primary Key like an Aadhaar card
  number, every individual has exactly one and no two individuals
  share one. Without it, we cannot uniquely identify a person in
  the system.
*/

-- we can verify the Primary Keys by checking the table structure:
DESCRIBE customers;
DESCRIBE products;
DESCRIBE orders;
DESCRIBE order_items;


-- ============================================================
-- Q5: What constraints are applied to the email column in the customers table? What would happen if you tried to insert a duplicate email?
-- Concept: UNIQUE constraint prevents duplicate values.
--          NOT NULL ensures the column always has a value.


/*
  FROM THE SCHEMA:
    email VARCHAR(100) UNIQUE NOT NULL

  TWO CONSTRAINTS APPLIED:
  1. NOT NULL  → Every customer must provide an email. Empty/NULL not allowed.
  2. UNIQUE    → No two customers can share the same email address.

  WHAT HAPPENS WITH A DUPLICATE?
  The database immediately rejects the INSERT with:
    ERROR 1062 (23000): Duplicate entry 'aarav.s@email.com'
    for key 'customers.email'

  The transaction is rolled back — no partial data is saved.
  This protects against accidental double-registration of the same user.
*/

-- DEMONSTRATION: This INSERT will intentionally FAIL

INSERT INTO customers VALUES
(109, 'Test', 'User', 'aarav.s@email.com', 'Surat', 'Gujarat', '2024-09-01', FALSE);

-- DEMONSTRATION: This INSERT will SUCCEED (unique email)
INSERT INTO customers VALUES
(109, 'Test', 'User', 'newuser@email.com', 'Surat', 'Gujarat', '2024-09-01', FALSE);


-- ============================================================
-- Q6: Insert a product with unit_price = -50 — constraint 

--  CHECK constraint enforces business rules at the DB level.
--          unit_price > 0 means negative prices are impossible.


/*
  FROM THE SCHEMA:
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0)

  THE CHECK CONSTRAINT:
  unit_price > 0 means the price must be strictly positive.
  A value of -50 violates this rule.

  WHAT HAPPENS?
  The database rejects the INSERT with:
    ERROR 3819 (HY000): Check constraint 'products_chk_1' is violated.



  OTHER CHECK CONSTRAINTS IN THIS SCHEMA:
  - stock_qty >= 0          (stock cannot go below zero)
  - quantity > 0            (must order at least 1 unit)
  - discount_pct BETWEEN 0 AND 100  (discount is a percentage)
  - total_amount >= 0       (order total cannot be negative)
  - status IN (...)         (only valid statuses allowed)
*/

-- DEMONSTRATION: This INSERT will intentionally FAIL
-- Uncomment to see the error:
 INSERT INTO products VALUES
 (209, 'Broken Product', 'Electronics', 'TestBrand', -50.00, 100);

-- DEMONSTRATION: What a valid insert looks like for comparison:
INSERT INTO products VALUES
(209, 'Valid Product', 'Electronics', 'TestBrand', 999.00, 100);


-- END OF SECTION A

