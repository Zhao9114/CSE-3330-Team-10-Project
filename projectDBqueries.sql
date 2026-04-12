-- =============================================================
-- Team 10 | CSE 3330/5330-008 | Spring 2026
-- Members: Zheng Yao Wong, Roberto Lira, Mahad Imran, Kaung Zaw Thant
-- File: projectDBqueries.sql
-- Purpose: 7 ad-hoc queries covering all required categories
--   Category A (GROUP BY / HAVING / Aggregate): Q1, Q2, Q3
--   Category B (CUBE / ROLLUP):                 Q4, Q5
--   Category C (DIVISION):                      Q6
--   Bonus:                                       Q7
-- All queries use joins or nested subqueries. No SELECT *.
-- LIKE used in Q2. ORDER BY + FETCH used in Q1, Q3, Q7.
-- =============================================================

-- =============================================================
-- Q1 | Category A — GROUP BY / HAVING / Aggregate
-- English: List the top 5 best-selling menu items by total quantity
--          sold across all orders, showing product name, category,
--          and total units sold. Order from most to least sold.
-- Business Goal #1: Top-Selling Products Report
-- =============================================================
SELECT m.product_name,
       m.category,
       SUM(c.quantity)   AS total_units_sold,
       SUM(c.quantity * m.price) AS total_revenue
  FROM Spring26_S008_T10_Contained c
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 GROUP BY m.product_name, m.category
 ORDER BY total_units_sold DESC
 FETCH FIRST 5 ROWS ONLY;

/*
Expected output (before update script):
PRODUCT_NAME               CATEGORY    TOTAL_UNITS_SOLD  TOTAL_REVENUE
Acai Bowl                  bowl        22                209.00
Yogurt Bowl                bowl        10                 87.50
Strawberry Banana Calypso  smoothie     6                 45.00
...
*/

-- =============================================================
-- Q2 | Category A — GROUP BY / HAVING / Aggregate + LIKE
-- English: Show total sales volume (number of orders and revenue)
--          grouped by hour of day, for all smoothie products whose
--          names contain the word 'Mango'. Use HAVING to show only
--          hours with more than 0 orders.
-- Business Goal #3: Peak Sales Hours Analysis
-- Also satisfies LIKE requirement.
-- =============================================================
SELECT EXTRACT(HOUR FROM o.order_timestamp)  AS sale_hour,
       COUNT(DISTINCT o.order_num)            AS num_orders,
       SUM(c.quantity * m.price)              AS hour_revenue
  FROM Spring26_S008_T10_Orders    o
  JOIN Spring26_S008_T10_Contained c ON o.order_num  = c.order_num
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 WHERE m.product_name LIKE '%Mango%'
 GROUP BY EXTRACT(HOUR FROM o.order_timestamp)
HAVING COUNT(DISTINCT o.order_num) > 0
 ORDER BY sale_hour;

/*
Expected output:
SALE_HOUR  NUM_ORDERS  HOUR_REVENUE
9          1           7.75
12         3           23.25
13         2           15.50
14         1            7.75
*/

-- =============================================================
-- Q3 | Category A — GROUP BY / HAVING / Aggregate
-- English: Show total amount spent per supplier over Q1 2026,
--          for suppliers where total spending exceeded $400.
--          Order by total spending descending, show top 5.
-- Business Goal #9: Supplier Expense Tracking
-- =============================================================
SELECT s.company_name,
       COUNT(DISTINCT d.delivery_id)   AS num_deliveries,
       SUM(di.line_cost)               AS total_spent
  FROM Spring26_S008_T10_Supplier      s
  JOIN Spring26_S008_T10_Delivery      d  ON s.supplier_id  = d.supplier_id
  JOIN Spring26_S008_T10_Delivery_Item di ON d.delivery_id  = di.delivery_id
 WHERE d.delivery_date BETWEEN DATE '2026-01-01' AND DATE '2026-03-31'
 GROUP BY s.company_name
HAVING SUM(di.line_cost) > 400
 ORDER BY total_spent DESC
 FETCH FIRST 5 ROWS ONLY;

/*
Expected output (before update):
COMPANY_NAME              NUM_DELIVERIES  TOTAL_SPENT
FreshFarm Produce Co.     3               892.50
DairyDirect Supply        3               738.25
NutriBase Wholesale       2               515.00
*/

-- =============================================================
-- Q4 | Category B — ROLLUP (Data Warehouse / Analytics)
-- English: Show total revenue broken down by category and product
--          using ROLLUP to produce subtotals per category and a
--          grand total row. Null in product_name = category subtotal.
--          Null in both = grand total.
-- Business Goal #4: Category Revenue Breakdown
-- =============================================================
SELECT m.category,
       m.product_name,
       SUM(c.quantity * m.price)  AS total_revenue,
       SUM(c.quantity)            AS total_units
  FROM Spring26_S008_T10_Contained c
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 GROUP BY ROLLUP(m.category, m.product_name)
 ORDER BY m.category NULLS LAST, m.product_name NULLS LAST;

/*
Expected output (partial):
CATEGORY   PRODUCT_NAME               TOTAL_REVENUE  TOTAL_UNITS
bowl       Acai Bowl                  209.00          22
bowl       Yogurt Bowl                 87.50          10
bowl       (null)                     296.50          32    <- category subtotal
ice cream  Chocolate Ice Cream         ...
ice cream  ...
ice cream  (null)                      ...             <- category subtotal
smoothie   ...
smoothie   (null)                      ...             <- category subtotal
(null)     (null)                      ...             <- grand total
*/

-- =============================================================
-- Q5 | Category B — CUBE (Data Warehouse / Analytics)
-- English: Show total delivery cost by supplier and delivery month
--          using CUBE, so we see every combination of subtotals:
--          per supplier, per month, per supplier+month, and grand total.
-- Business Goal #10: Quarterly Profit Performance (cost side)
-- =============================================================
SELECT s.company_name,
       TO_CHAR(d.delivery_date, 'YYYY-MM')  AS delivery_month,
       SUM(di.line_cost)                    AS total_cost
  FROM Spring26_S008_T10_Supplier      s
  JOIN Spring26_S008_T10_Delivery      d  ON s.supplier_id = d.supplier_id
  JOIN Spring26_S008_T10_Delivery_Item di ON d.delivery_id = di.delivery_id
 GROUP BY CUBE(s.company_name, TO_CHAR(d.delivery_date, 'YYYY-MM'))
 ORDER BY s.company_name NULLS LAST,
          TO_CHAR(d.delivery_date, 'YYYY-MM') NULLS LAST;

/*
Expected output (partial):
COMPANY_NAME            DELIVERY_MONTH  TOTAL_COST
DairyDirect Supply      2026-01         280.00
DairyDirect Supply      2026-02         260.00
DairyDirect Supply      2026-03         198.25
DairyDirect Supply      (null)          738.25   <- supplier subtotal
FreshFarm Produce Co.   2026-01         312.50
...
(null)                  2026-01         ...      <- month subtotal
(null)                  (null)          ...      <- grand total
*/

-- =============================================================
-- Q6 | Category C — DIVISION
-- English: Find all staff members who have received deliveries from
--          EVERY supplier in the database.
--          (Classic relational division using double NOT EXISTS)
-- Business Goal: Ensures full supplier coverage by staff — useful
--          for tracking which staff are fully cross-trained on all
--          supplier relationships.
-- =============================================================
SELECT st.staff_id,
       st.first_name,
       st.last_name
  FROM Spring26_S008_T10_Staff st
 WHERE NOT EXISTS (
           -- For this staff member, find any supplier they have NOT
           -- received a delivery from
           SELECT s.supplier_id
             FROM Spring26_S008_T10_Supplier s
            WHERE NOT EXISTS (
                      SELECT d.delivery_id
                        FROM Spring26_S008_T10_Delivery d
                       WHERE d.staff_id    = st.staff_id
                         AND d.supplier_id = s.supplier_id
                  )
       );

/*
Expected output (before update, staff 1 has deliveries from suppliers 1,4,5):
No staff member receives from ALL 5 suppliers in the base data.
After update script adds supplier 6, result stays empty unless data extended.
This demonstrates the division concept correctly — an empty result means
no single staff member is fully cross-trained across all suppliers.
*/

-- =============================================================
-- Q7 | Bonus — Subquery + ORDER BY + FETCH
-- English: Show all menu items whose price is above the average price
--          of their own category, ordered by price descending.
--          Return only the top 5 results.
-- Business Goal #7: Base Profitability Comparison
-- Satisfies: nested subquery, ORDER BY, FETCH FIRST N ROWS ONLY
-- =============================================================
SELECT m.product_name,
       m.category,
       m.price,
       ROUND(avg_cat.avg_price, 2) AS category_avg_price,
       ROUND(m.price - avg_cat.avg_price, 2) AS above_avg_by
  FROM Spring26_S008_T10_Menu m
  JOIN (
           SELECT category,
                  AVG(price) AS avg_price
             FROM Spring26_S008_T10_Menu
            GROUP BY category
       ) avg_cat ON m.category = avg_cat.category
 WHERE m.price > avg_cat.avg_price
 ORDER BY m.price DESC
 FETCH FIRST 5 ROWS ONLY;

/*
Expected output:
PRODUCT_NAME          CATEGORY   PRICE  CATEGORY_AVG_PRICE  ABOVE_AVG_BY
Green Coconut Boost   smoothie   8.50   7.90                 0.60
Berry Mix Supreme     smoothie   8.25   7.90                 0.35
Coconut Dream         smoothie   8.25   7.90                 0.35
Acai Bowl             bowl       9.50   9.13                 0.37
*/

-- =============================================================
-- END OF QUERIES SCRIPT
-- =============================================================
