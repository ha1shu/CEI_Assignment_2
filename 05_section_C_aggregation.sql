-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 05_section_C_aggregation.sql
--  SECTION C: Aggregation — COUNT, SUM, AVG, GROUP BY, HAVING


USE shopease;

-- ============================================================
-- IMPORTANT: SQL EXECUTION ORDER (memorize this)
-- 1. FROM       → identify the table
-- 2. WHERE      → filter individual rows  (BEFORE grouping)
-- 3. GROUP BY   → form groups
-- 4. HAVING     → filter groups           (AFTER grouping)
-- 5. SELECT     → compute output columns
-- 6. ORDER BY   → sort the final result
-- 7. LIMIT      → restrict number of rows
--
-- KEY RULE: WHERE runs before GROUP BY, so it cannot see
-- aggregate values. Use HAVING to filter on aggregates.
-- ============================================================


-- ============================================================
-- Q13: Count total number of orders placed

-- COUNT(*) counts every row regardless of NULL values


SELECT COUNT(*) AS total_orders
FROM orders;

/*
  COUNT(*) vs COUNT(column):
  - COUNT(*)         → counts ALL rows, including those with NULLs
  - COUNT(column)    → counts only rows where column is NOT NULL

  Expected Output:
  total_orders
  ------------
  10
*/


-- ============================================================
-- Q14: Total revenue from Delivered orders only

-- SUM() with WHERE — filter rows first, then aggregate
-- Business insight: Only Delivered orders represent real collected revenue


SELECT SUM(total_amount) AS total_revenue
FROM orders
WHERE status = 'Delivered';

/*
  Manual verification:
  Delivered orders: 1001(4498) + 1002(799) + 1004(3499)
                  + 1006(5898) + 1008(899) + 1010(1598)
                  = ₹17,191.00

  Expected Output:
  total_revenue
  -------------
  17191.00
*/


-- ============================================================
-- Q15: Average order value across all orders

-- AVG() — mean value, ROUND() for clean currency output
-- Business insight: Benchmark for upselling and basket size analysis


SELECT ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders;

/*
  AVG() automatically ignores NULL values in the column.
  ROUND(..., 2) ensures professional 2-decimal currency display.

  Calculation: SUM of all 10 orders / 10
  = (4498 + 799 + 7498 + 3499 + 2999 + 5898 + 1299 + 899 + 6098 + 1598) / 10
  = 35085 / 10
  = 3508.50

  Expected Output:
  avg_order_value
  ---------------
  3508.50
*/


-- ============================================================
-- Q16: Count of orders and total revenue grouped by status

-- GROUP BY — compute aggregates per group (like a pivot)
-- Business insight: Dashboard view of order pipeline health


SELECT
    status,
    COUNT(*)                    AS order_count,
    SUM(total_amount)           AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_order_value
FROM orders
GROUP BY status
ORDER BY total_revenue DESC;

/*
  HOW GROUP BY WORKS:
  Step 1 — FROM orders: load all 10 rows
  Step 2 — GROUP BY status: form 4 groups
           Delivered  → rows 1001, 1002, 1004, 1006, 1008, 1010
           Shipped    → rows 1003, 1009
           Cancelled  → row  1005
           Pending    → row  1007
  Step 3 — COUNT and SUM computed per group
  Step 4 — ORDER BY sorts by revenue descending

  Expected Output:
  status     | order_count | total_revenue | avg_order_value
  -----------------------------------------------------------
  Delivered  | 6           | 17191.00      | 2865.17
  Shipped    | 2           | 13596.00      | 6798.00
  Cancelled  | 1           | 2999.00       | 2999.00
  Pending    | 1           | 1299.00       | 1299.00
*/


-- ============================================================
-- Q17: Customers who have placed more than 1 order (repeat buyers)
-- GROUP BY + HAVING — HAVING filters on aggregated values
-- Business insight: Identify loyal customers for retention programs


SELECT
    customer_id,
    COUNT(*)  AS order_count,
    SUM(total_amount) AS total_spent
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;

/*
  WHY HAVING AND NOT WHERE?

   WRONG — This causes ERROR: Invalid use of group function
  -------------------------------------------------------
  SELECT customer_id, COUNT(*) AS order_count
  FROM orders
  WHERE COUNT(*) > 1       ← WHERE runs before GROUP BY
  GROUP BY customer_id;    ← groups don't exist yet at WHERE stage

   CORRECT — HAVING runs after GROUP BY
  -------------------------------------------------------
  HAVING COUNT(*) > 1      ← groups already exist at HAVING stage

  SIMPLE RULE TO REMEMBER:
  → Filter on raw column values?    Use WHERE
  → Filter on aggregate functions?  Use HAVING

  Expected Output:
  customer_id | order_count | total_spent
  ----------------------------------------
  101         | 2           | 7997.00
  103         | 2           | 8397.00
*/


-- ============================================================
-- Q18: Most expensive and cheapest product per category

-- MAX() and MIN() with GROUP BY — extremes per group
-- Bonus: price_range shows the spread — a real analyst insight
-- Business insight: Understand pricing strategy per category


SELECT
    category,
    COUNT(*)                            AS product_count,
    MAX(unit_price)                     AS max_price,
    MIN(unit_price)                     AS min_price,
    MAX(unit_price) - MIN(unit_price)   AS price_range
FROM products
GROUP BY category
ORDER BY max_price DESC;

/*
  Expected Output:
  category    | product_count | max_price | min_price | price_range
  -----------------------------------------------------------------
  Clothing    | 2             | 4599.00   | 799.00    | 3800.00
  Electronics | 4             | 3499.00   | 899.00    | 2600.00
  Home        | 2             | 1299.00   | 599.00    | 700.00

  INSIGHT: Clothing has the widest price range (₹3800) suggesting
  it spans both budget (T-shirts) and premium (Nike shoes) segments.
  Electronics has 4 products — the most diverse category.
*/


-- ============================================================
-- BONUS: Combined summary query (not in assignment but shows
-- how a real analyst thinks — one query, full picture)


SELECT
    p.category,
    COUNT(DISTINCT p.product_id)        AS products_available,
    SUM(p.stock_qty)                    AS total_stock_units,
    ROUND(AVG(p.unit_price), 2)         AS avg_price
FROM products p
GROUP BY p.category
ORDER BY avg_price DESC;




-- END OF SECTION C
