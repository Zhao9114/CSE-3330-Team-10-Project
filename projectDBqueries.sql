/* 
Team 10 | CSE 3330-008 | Spring 2026
Members: Zheng Yao Wong, Roberto Lira, Mahad Imran, Kaung Zaw Thant
File: projectDBqueries.sql

7 ad-hoc queries covering all required categories
   Category A (GROUP BY / HAVING / Aggregate): Q1, Q2, Q3
   Category B (CUBE / ROLLUP):                 Q4, Q5
   Category C (DIVISION):                      Q6
  Bonus:                                       Q7
 LIKE used in Q7. ORDER BY + FETCH used in Q1, Q3, Q7.
*/

-- Q1 | Category A - GROUP BY / HAVING / Aggregate
-- Top 5 best-selling menu items by total quantity sold across all
-- orders, with product name, category, and units sold.
-- Ordered from most to least sold.
SELECT m.product_name,
       m.category,
       SUM(c.quantity)   AS total_units_sold,
       SUM(c.quantity * m.price) AS total_revenue
  FROM Spring26_S008_T10_Contained c
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 GROUP BY m.product_name, m.category
 ORDER BY total_units_sold DESC
 FETCH FIRST 5 ROWS ONLY;



-- Q2 | Category A - GROUP BY / HAVING / Aggregate
-- Total orders and revenue grouped by hour of day.
-- HAVING filters out hours with no sales.
SELECT EXTRACT(HOUR FROM o.order_timestamp)  AS sale_hour,
       COUNT(DISTINCT o.order_num)            AS num_orders,
       SUM(c.quantity * m.price)              AS hour_revenue
  FROM Spring26_S008_T10_Orders    o
  JOIN Spring26_S008_T10_Contained c ON o.order_num  = c.order_num
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 GROUP BY EXTRACT(HOUR FROM o.order_timestamp)
HAVING COUNT(DISTINCT o.order_num) > 0
 ORDER BY sale_hour;


-- Q3 | Category A - GROUP BY / HAVING / Aggregate
-- Total spending per supplier for Q1 2026. HAVING filters to
-- suppliers where we spent over $400. Top 5 by spend.
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


-- Q4 | Category B - ROLLUP (Data Warehouse / Analytics)
-- Revenue by category and product using ROLLUP. NULL in product_name
-- means it's a category subtotal; NULL in both means grand total.
SELECT m.category,
       m.product_name,
       SUM(c.quantity * m.price)  AS total_revenue,
       SUM(c.quantity)            AS total_units
  FROM Spring26_S008_T10_Contained c
  JOIN Spring26_S008_T10_Menu      m ON c.product_id = m.product_id
 GROUP BY ROLLUP(m.category, m.product_name)
 ORDER BY m.category NULLS LAST, m.product_name NULLS LAST;


-- Q5 | Category B - CUBE (Data Warehouse / Analytics)
-- Delivery cost by supplier and month using CUBE, giving every
-- combination: per supplier, per month, both, and grand total.
SELECT s.company_name,
       TO_CHAR(d.delivery_date, 'YYYY-MM')  AS delivery_month,
       SUM(di.line_cost)                    AS total_cost
  FROM Spring26_S008_T10_Supplier      s
  JOIN Spring26_S008_T10_Delivery      d  ON s.supplier_id = d.supplier_id
  JOIN Spring26_S008_T10_Delivery_Item di ON d.delivery_id = di.delivery_id
 GROUP BY CUBE(s.company_name, TO_CHAR(d.delivery_date, 'YYYY-MM'))
 ORDER BY s.company_name NULLS LAST,
          TO_CHAR(d.delivery_date, 'YYYY-MM') NULLS LAST;

-- Q6 | Category C - DIVISION
-- Find staff who have received deliveries from every supplier
-- in the database. Uses double NOT EXISTS for relational division.
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


-- Q7 | Bonus - Subquery + ORDER BY + FETCH + LIKE
-- Bowl items priced above their category average, ordered by price
-- descending. Top 5 only.
-- Uses: nested subquery, LIKE, ORDER BY, FETCH FIRST N ROWS ONLY
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
 WHERE m.product_name LIKE '%Bowl%'
   AND m.price > avg_cat.avg_price
 ORDER BY m.price DESC
 FETCH FIRST 5 ROWS ONLY;

