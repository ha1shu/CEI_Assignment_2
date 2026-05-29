-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 06_section_D_joins.sql
--  SECTION D: Joins & Relationships — INNER, LEFT, 3-table chains


USE shopease;

-- ============================================================
-- Q19. Write an INNER JOIN query to display each order along with the customer's first_name and last_name. Show: order_id, order_date, first_name, last_name, total_amount.


SELECT
    o.order_id,
    c.first_name,
    c.last_name,
    o.order_date,
    o.status,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date;

/*
  Expected Output (10 rows):
  order_id | first_name | last_name | order_date | status    | total_amount
  --------------------------------------------------------------------------
  1001     | Aarav      | Sharma    | 2024-08-01 | Delivered | 4498.00
  1002     | Priya      | Patel     | 2024-08-03 | Delivered | 799.00
  1003     | Rohan      | Gupta     | 2024-08-05 | Shipped   | 7498.00
  ... (10 rows total)
*/


-- ============================================================
-- Q20: Using a LEFT JOIN, list ALL customers and their orders (if any). Customers with no orders should still appear with NULL values for order columns.


SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    COUNT(o.order_id)  AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.city
ORDER BY total_orders DESC;

/*
  

  Expected Output (all 8 customers):
  customer_id | first_name | last_name | city      | total_orders | total_spent
  ----------------------------------------------------------------------------
  101         | Aarav      | Sharma    | Mumbai    | 2            | 7997.00
  103         | Rohan      | Gupta     | Delhi     | 2            | 8397.00
  102         | Priya      | Patel     | Ahmedabad | 1            | 799.00
  104         | Sneha      | Reddy     | Hyderabad | 1            | 2999.00
  105         | Vikram     | Singh     | Jaipur    | 1            | 5898.00
  106         | Ananya     | Iyer      | Chennai   | 1            | 1299.00
  107         | Karan      | Mehta     | Pune      | 1            | 6098.00
  108         | Divya      | Nair      | Kochi     | 1            | 1598.00
*/


-- ============================================================
-- Q21: Write a query using JOINs across three tables (orders → order_items → products) to show: order_id, product_name, quantity, unit_price, and discount_pct for each order item.

-- Total revenue per product (3-table join)
-- Concept: Chain joins through the bridge table order_items
-- Revenue = quantity × unit_price × (1 - discount_pct / 100)


SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100))
    , 2) AS total_revenue
FROM products p
INNER JOIN order_items oi  ON p.product_id  = oi.product_id
INNER JOIN orders  o   ON oi.order_id  = o.order_id
WHERE o.status = 'Delivered'
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

/*
  
  Expected Output (products that had Delivered orders):
  product_id | product_name       | category    | units_sold | total_revenue
  --------------------------------------------------------------------------
  204        | Running Shoes      | Clothing    | 2          | 8758.05
  201        | Wireless Earbuds   | Electronics | 3          | 4197.10
  205        | Bluetooth Speaker  | Electronics | 1          | 3499.00
  207        | Laptop Stand       | Electronics | 2          | 1709.10
  202        | Cotton T-Shirt     | Clothing    | 1          | 799.00
  206        | Bedsheet Set       | Home        | 1          | 1299.00
  208        | Cushion Covers     | Home        | 1          | 599.00
*/


-- ============================================================
-- Q22: Explain INNER JOIN vs LEFT JOIN vs RIGHT JOIN


/*
  JOIN TYPE COMPARISON:
  +---------------+----------------------------------------+---------------------------+
  | Join Type     | Returns                                | Use When                  |
  +---------------+----------------------------------------+---------------------------+
  | INNER JOIN    | Only rows matched in BOTH tables       | You only want pairs       |
  | LEFT JOIN     | ALL left rows + matched right rows     | Left rows must appear     |
  | RIGHT JOIN    | ALL right rows + matched left rows     | Right rows must appear    |
  | FULL OUTER    | ALL rows from BOTH tables              | You want everything       |
  +---------------+----------------------------------------+---------------------------+

  ShopEase Examples:
  INNER JOIN → only customers who have placed at least one order
  LEFT JOIN  → all customers, even those with no orders (NULL for order cols)
  RIGHT JOIN → all orders, even if customer record was somehow deleted
*/

-- INNER JOIN demonstration
SELECT c.first_name, c.last_name, o.order_id, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;
-- Returns 10 rows: only customer-order pairs that match


-- LEFT JOIN demonstration
SELECT c.first_name, c.last_name, o.order_id, o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;
-- Returns 10 rows here (all customers have orders in sample data)
-- If a customer had NO orders: their row appears with NULL in order_id, total_amount


-- RIGHT JOIN demonstration (same result as LEFT JOIN with tables swapped)
SELECT c.first_name, c.last_name, o.order_id, o.total_amount
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;
-- Returns 10 rows: all orders; NULL for customer name if no match


-- ============================================================
-- Q23:  Identify all Foreign Key relationships in the schema. Explain what would happen if you tried to insert an order with customer_id = 999 (which doesn't exist in customers).

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    p.stock_qty
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.item_id IS NULL
ORDER BY p.category;

/*

  Expected Output:
  In our sample data, all 8 products appear in at least one order_item.
  Result: 0 rows — but the pattern is correct.
  In a real database with hundreds of products, many would show here.
*/

-- ============================================================
-- BONUS: Full customer purchase summary (analyst-level query)
-- Demonstrates chaining all 4 tables in one professional query
-- ============================================================

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.city,
    c.state,
    c.is_premium,
    COUNT(DISTINCT o.order_id)  AS total_orders,
    COUNT(oi.item_id) AS total_items,
    ROUND(SUM(
        oi.quantity * oi.unit_price
        * (1 - oi.discount_pct / 100)
    ), 2)                                           AS total_spent_discounted
FROM customers c
LEFT JOIN orders      o   ON c.customer_id  = o.customer_id
LEFT JOIN order_items oi  ON o.order_id     = oi.order_id
WHERE o.status IN ('Delivered', 'Shipped') OR o.order_id IS NULL
GROUP BY c.customer_id, customer_name, c.city, c.state, c.is_premium
ORDER BY total_spent_discounted DESC;

-- ============================================================
-- END OF SECTION D
-- ============================================================
