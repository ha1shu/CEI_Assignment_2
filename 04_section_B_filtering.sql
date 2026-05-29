-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 04_section_B_filtering.sql
--  SECTION B: Filtering & Optimization — WHERE, Indexes, SARGability


USE shopease;

-- ============================================================
-- Q7: Find all customers from Maharashtra
-- Concept: WHERE clause with exact string match
-- Note: String values are case-sensitive — 'maharashtra' returns 0 rows


SELECT *
FROM customers
WHERE state = 'Maharashtra';

/*
  Expected Output (2 rows):
  customer_id | first_name | last_name | city   | state       | ...
  ------------------------------------------------------------------
  101         | Aarav      | Sharma    | Mumbai | Maharashtra | ...
  107         | Karan      | Mehta     | Pune   | Maharashtra | ...
*/


-- ============================================================
-- Q8: Products with unit_price between ₹500 and ₹2000
-- Concept: BETWEEN operator — inclusive on BOTH ends
-- BETWEEN 500 AND 2000 includes exactly 500.00 and exactly 2000.00


SELECT product_id, product_name, brand, unit_price
FROM products
WHERE unit_price BETWEEN 500 AND 2000;

/*
  Expected Output (4 rows):
  product_id | product_name          | brand         | unit_price
  ---------------------------------------------------------------
  201        | Wireless Earbuds      | BoAt           | 1499.00
  202        | Cotton T-Shirt        | Levis          | 799.00
  206		 | Bedsheet Set			 | Spaces 		  | 1299.00
  207        | Laptop Stand          | AmazonBasics   | 899.00
  208        | Cushion Covers (Set)  | HomeCenter     | 599.00
*/


-- ============================================================
-- Q9: Retrieve all Delivered or Shipped orders

-- Preferred approach: IN (readable and scalable)

SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE status IN ('Delivered', 'Shipped');

/*
  Equivalent using OR (less preferred but identical result):
  WHERE status = 'Delivered' OR status = 'Shipped'

  Expected Output (8 rows — excludes Pending and Cancelled):
  order_id | customer_id | order_date | status    | total_amount
  ------------------------------------------------------------------
  1001     | 101         | 2024-08-01 | Delivered | 4498.00
  1002     | 102         | 2024-08-03 | Delivered | 799.00
  1003     | 103         | 2024-08-05 | Shipped   | 7498.00
  1004     | 101         | 2024-08-10 | Delivered | 3499.00
  1006     | 105         | 2024-08-15 | Delivered | 5898.00
  1008     | 103         | 2024-08-20 | Delivered | 899.00
  1009     | 107         | 2024-08-25 | Shipped   | 6098.00
  1010     | 108         | 2024-08-28 | Delivered | 1598.00
*/


-- ============================================================
-- Q10: Customers whose first_name starts with 'A'
-- Concept: LIKE operator with % wildcard for pattern matching
-- 'A%' means: starts with A, followed by any characters


SELECT customer_id, first_name, last_name, city
FROM customers
WHERE first_name LIKE 'A%';

/*
  Expected Output (2 rows):
  customer_id | first_name | last_name | city
  -------------------------------------------
  101         | Aarav      | Sharma    | Mumbai
  106         | Ananya     | Iyer      | Chennai
*/


-- ============================================================
-- Q11: What is an Index? When should you create one?
-- Theory question — Indexes, B-Tree, cardinality


/*
  WHAT IS AN INDEX?
  -----------------
  An index is a separate data structure (typically a B-Tree) that the
  database maintains alongside a table. It stores a sorted copy of one
  or more column values along with pointers to the physical location of
  the actual rows in the table.

  Without an index: the database performs a FULL TABLE SCAN — it reads
  every single row to find matches. For a table with 1 million rows,
  this means 1 million row reads for every query.

  With an index: the database jumps directly to the relevant rows using
  the B-Tree structure — like using a book's index instead of reading
  every page.

  WHEN TO CREATE AN INDEX:
  +-------------------------------------------------+-------------------------------+
  | Scenario                                        | ShopEase Example              |
  +-------------------------------------------------+-------------------------------+
  | Column frequently used in WHERE clauses         | WHERE status = 'Delivered'    |
  | Column used in JOIN conditions                  | orders.customer_id            |
  | Column used in ORDER BY / GROUP BY              | ORDER BY order_date           |
  | Column with HIGH cardinality (many unique vals) | email — every value is unique |
  +-------------------------------------------------+-------------------------------+

  WHEN NOT TO CREATE AN INDEX:
  - Small tables: Full scan is faster than the overhead of index lookup
  - Frequently updated columns: Index must be rebuilt on every UPDATE/INSERT
  - Low-cardinality columns: is_premium (only TRUE/FALSE) — index barely helps
    because half the table matches either value

  INDEXES ALREADY IN OUR SCHEMA:
  - idx_customers_city      ON customers(city)
  - idx_customers_state     ON customers(state)
  - idx_products_category   ON products(category)
  - idx_orders_date         ON orders(order_date)
  - idx_orders_status       ON orders(status)
*/

-- You can view existing indexes with:
SHOW INDEX FROM customers;
SHOW INDEX FROM orders;
SHOW INDEX FROM products;
SHOW INDEX FROM order_items;


-- ============================================================
-- Q12: Rewrite non-SARGable query to use index properly

-- SARGability — making WHERE conditions index-friendly
-- SARGable = Search ARGument ABLE


/*
  ORIGINAL (BAD) QUERY — Non-SARGable:
  -----------------------------------------------------------------------
  SELECT * FROM customers WHERE YEAR(join_date) = 2024;

  WHY IS THIS BAD?
  - YEAR() is a function applied to the column join_date
  - The B-Tree index stores actual DATE values (e.g. '2024-03-10')
  - It has no entry for YEAR(join_date) — it cannot use the index
  - The database is forced to do a FULL TABLE SCAN:
      → read every row → apply YEAR() → compare to 2024
  - As the table grows to millions of rows, this becomes very slow

  GOLDEN RULE: Never wrap an indexed column inside a function in WHERE.
  The database can't use the index on a transformed/computed value.
*/

--  BAD — Non-SARGable: index on join_date is NOT used
-- SELECT * FROM customers WHERE YEAR(join_date) = 2024;

--  GOOD — SARGable rewrite: index on join_date IS used
SELECT customer_id, first_name, last_name, join_date
FROM customers
WHERE join_date >= '2024-01-01'
  AND join_date < '2025-01-01';

/*
  HOW THE REWRITE HELPS:
  - The B-Tree index on join_date can locate '2024-01-01' instantly
  - It then scans forward until it reaches '2025-01-01'
  - No function is applied to the column — index is fully utilized

  OTHER COMMON NON-SARGable PATTERNS TO AVOID:
  +-----------------------------------------+------------------------------------------+
  | BAD (non-SARGable)                      | GOOD (SARGable rewrite)                  |
  +-----------------------------------------+------------------------------------------+
  | WHERE YEAR(join_date) = 2024            | WHERE join_date >= '2024-01-01'          |
  |                                         |   AND join_date < '2025-01-01'           |
  | WHERE UPPER(city) = 'MUMBAI'            | WHERE city = 'Mumbai'                    |
  | WHERE total_amount * 1.18 > 5000        | WHERE total_amount > 5000 / 1.18         |
  | WHERE LEFT(email, 5) = 'priya'          | WHERE email LIKE 'priya%'                |
  +-----------------------------------------+------------------------------------------+

  Expected Output (all 8 customers — all joined in 2024):
  customer_id | first_name | last_name | join_date
  -------------------------------------------------
  101         | Aarav      | Sharma    | 2024-01-15
  102         | Priya      | Patel     | 2024-02-20
  ... (all 8 rows)
*/

-- Use EXPLAIN to verify index usage (run in MySQL):
EXPLAIN
SELECT customer_id, first_name, last_name, join_date
FROM customers
WHERE join_date >= '2024-01-01'
  AND join_date < '2025-01-01';
-- Look for 'key' column in output — it should show idx_customers_state or similar



-- END OF SECTION B

