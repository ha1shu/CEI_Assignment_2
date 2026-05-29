-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 07_section_E_advanced.sql
--  SECTION E: CASE WHEN, ACID Properties, Transactions


USE shopease;

-- ============================================================
-- Q24: Write a query using CASE to classify products into price tiers: 
-- • 'Budget'    → unit_price < 1000 
-- • 'Mid-Range' → unit_price BETWEEN 1000 AND 3000 
-- • 'Premium'   → unit_price > 3000 
-- Display: product_name, unit_price, price_tier.

SELECT
    o.order_id,
    c.first_name,
    c.last_name,
    o.total_amount,
    o.status,
    CASE
        WHEN o.total_amount >= 5000 THEN 'High Value'
        WHEN o.total_amount >= 2000 THEN 'Mid Value'
        ELSE                             'Low Value'
    END AS order_category
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.total_amount DESC;

/*
  
  Expected Output (10 rows, sorted by amount):
  order_id | first_name | total_amount | status    | order_category
  ------------------------------------------------------------------
  1003     | Rohan      | 7498.00      | Shipped   | High Value
  1009     | Karan      | 6098.00      | Shipped   | High Value
  1006     | Vikram     | 5898.00      | Delivered | High Value
  1001     | Aarav      | 4498.00      | Delivered | Mid Value
  1004     | Aarav      | 3499.00      | Delivered | Mid Value
  1005     | Sneha      | 2999.00      | Cancelled | Mid Value
  1010     | Divya      | 1598.00      | Delivered | Low Value
  1007     | Ananya     | 1299.00      | Pending   | Low Value
  1008     | Rohan      | 899.00       | Delivered | Low Value
  1002     | Priya      | 799.00       | Delivered | Low Value
*/


-- ============================================================
-- Q25: Using a CASE statement inside an aggregate function, count how many orders are 'Delivered' vs 'Not Delivered' (all other statuses). Display the result in a single row.


-- Approach 1: Pivot (all categories in ONE row — impressive technique)
SELECT
    COUNT(CASE WHEN total_amount >= 5000  THEN 1 END) AS high_value_count,
    COUNT(CASE WHEN total_amount >= 2000 AND total_amount < 5000 THEN 1 END) AS mid_value_count,
    COUNT(CASE WHEN total_amount <  2000  THEN 1 END) AS low_value_count,
    COUNT(*)  AS total_orders,
    ROUND(AVG(total_amount), 2)    AS avg_order_value
FROM orders;

/*
  
  Expected Output (1 summary row):
  high_value_count | mid_value_count | low_value_count | total_orders | avg_order_value
  --------------------------------------------------------------------------------------
  3                | 3               | 4               | 10           | 3508.50
*/

-- Approach 2: Grouped rows (easier to read, shows revenue per tier)
SELECT
    CASE
        WHEN total_amount >= 5000 THEN 'High Value'
        WHEN total_amount >= 2000 THEN 'Mid Value'
        ELSE                           'Low Value'
    END                      AS order_category,
    COUNT(*)                 AS order_count,
    SUM(total_amount)        AS category_revenue,
    ROUND(AVG(total_amount), 2) AS avg_in_category
FROM orders
GROUP BY order_category
ORDER BY category_revenue DESC;

/*
  Expected Output (3 rows):
  order_category | order_count | category_revenue | avg_in_category
  ------------------------------------------------------------------
  High Value     | 3           | 19494.00         | 6498.00
  Mid Value      | 3           | 10996.00         | 3665.33
  Low Value      | 4           | 4595.00          | 1148.75
*/


-- ============================================================
-- Q26: ACID Properties — Theory + ShopEase Examples


/*
  ═══════════════════════════════════════════════════════════════
  ACID PROPERTIES — Full Explanation with ShopEase Context
  ═══════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────┐
  │  A — ATOMICITY                                              │
  │  "All or nothing — a transaction completes fully or not"   │
  ├─────────────────────────────────────────────────────────────┤
  │  Bank analogy:                                              │
  │  Transfer ₹1000: Debit Account A → Credit Account B        │
  │  If crash occurs after debit but before credit → ROLLBACK  │
  │  Both operations undo. ₹1000 is never lost.                │
  │                                                             │
  │  ShopEase example:                                          │
  │  Placing order 1011 requires:                               │
  │    INSERT orders + INSERT order_items + UPDATE stock_qty    │
  │  If stock UPDATE fails → entire transaction is rolled back  │
  │  No orphaned order row exists without its items/stock change│
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │  C — CONSISTENCY                                            │
  │  "DB moves from one valid state to another valid state"    │
  ├─────────────────────────────────────────────────────────────┤
  │  Bank analogy:                                              │
  │  Rule: balance cannot go below ₹0.                         │
  │  A transfer that causes balance = -₹500 is REJECTED.       │
  │  The constraint is enforced — state stays valid.            │
  │                                                             │
  │  ShopEase example:                                          │
  │  CHECK constraint: stock_qty >= 0                           │
  │  If selling 300 units when stock = 250, the transaction     │
  │  is rejected. DB never reaches an inconsistent state.       │
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │  I — ISOLATION                                              │
  │  "Concurrent transactions cannot see each other's          │
  │   intermediate (uncommitted) state"                         │
  ├─────────────────────────────────────────────────────────────┤
  │  Bank analogy:                                              │
  │  Two people withdraw ₹1000 from the same ₹1000 account     │
  │  simultaneously. Without isolation, both see ₹1000 as      │
  │  available → both succeed → account goes to -₹1000.        │
  │  Isolation ensures only one transaction completes.          │
  │                                                             │
  │  ShopEase example:                                          │
  │  Two customers buy the last Bluetooth Speaker (stock = 1).  │
  │  Isolation: only one purchase succeeds. The second sees     │
  │  updated stock = 0 and fails gracefully.                    │
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │  D — DURABILITY                                             │
  │  "Once COMMIT runs, changes survive permanently —           │
  │   crashes, power failures, hardware errors included"        │
  ├─────────────────────────────────────────────────────────────┤
  │  Bank analogy:                                              │
  │  You receive "Transfer Successful" confirmation.            │
  │  Bank server crashes 1 second later.                        │
  │  When it restarts, your transfer is still recorded.         │
  │  Achieved via WAL (Write-Ahead Log) / redo logs.            │
  │                                                             │
  │  ShopEase example:                                          │
  │  Order 1011 is committed at 2:00 PM.                        │
  │  Server loses power at 2:01 PM.                             │
  │  After restart, order 1011 is still in the database.        │
  └─────────────────────────────────────────────────────────────┘

*/


-- ============================================================
/*27: Write a SQL transaction that does the following atomically: 
  1. Insert a new order (order_id=1011, customer_id=102, today's date, 'Pending', 1598.00) 
  2. Insert two order items for that order 
  3. Update the stock_qty of the purchased products 
  4. If any step fails, ROLLBACK the entire transaction. Otherwise, COMMIT. 
Write the complete BEGIN...COMMIT/ROLLBACK block.
*/


-- ─────────────────────────────────────────
-- FIRST: Check current stock before ordering

SELECT product_id, product_name, stock_qty
FROM products
WHERE product_id IN (201, 202);
-- Wireless Earbuds (201): stock = 250
-- Cotton T-Shirt   (202): stock = 500

-- ─────────────────────────────────────────
-- THE TRANSACTION

START TRANSACTION;

    -- Step 1: Insert the new order header
    --         Total = (2 × 1499) + (2 × 799) = 2998 + 1598 = ₹4596
    INSERT INTO orders (order_id, customer_id, order_date, status, total_amount)
    VALUES (1011, 105, CURDATE(), 'Pending', 4596.00);

    -- Step 2: Insert order_item — 2 × Wireless Earbuds (no discount)
    INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
    VALUES (5016, 1011, 201, 2, 1499.00, 0.00);

    -- Step 3: Insert order_item — 2 × Cotton T-Shirts (no discount)
    INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
    VALUES (5017, 1011, 202, 2, 799.00, 0.00);

    -- Step 4: Reduce stock for Wireless Earbuds — deduct 2 units
    UPDATE products
    SET stock_qty = stock_qty - 2
    WHERE product_id = 201;

    -- Step 5: Reduce stock for Cotton T-Shirt — deduct 2 units
    UPDATE products
    SET stock_qty = stock_qty - 2
    WHERE product_id = 202;

-- All 5 steps succeeded → make changes permanent
COMMIT;




SELECT * FROM orders WHERE order_id = 1011;
SELECT * FROM order_items WHERE order_id = 1011;

SELECT product_id, product_name, stock_qty
FROM products
WHERE product_id IN (201, 202);
-- Wireless Earbuds: should now show 248 (250 - 2)
-- Cotton T-Shirt:   should now show 498 (500 - 2)


-- END OF SECTION E — Assignment Complete

