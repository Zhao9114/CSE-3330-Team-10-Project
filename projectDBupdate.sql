-- =============================================================
-- Team 10 | CSE 3330/5330-008 | Spring 2026
-- Members: Zheng Yao Wong, Roberto Lira, Mahad Imran, Kaung Zaw Thant
-- File: projectDBupdate.sql
-- Purpose: Modify data so re-running queries produces different results.
-- Run AFTER projectDBinsert.sql. Run projectDBqueries.sql before and
-- after this script to observe the differences noted below.
-- =============================================================

-- -------------------------------------------------------------
-- UPDATE 1: Restock three low-stock ingredients
-- Effect on queries: Inventory Reorder Alert query
-- Before: Granola qty=7 (below threshold 5 - actually above, so also
--         lower threshold to demo the alert), Honey qty=4, Straw IC qty=3
-- We lower Granola qty to trigger the alert, then restock all three.
-- -------------------------------------------------------------
-- First bring Granola below threshold to show the alert fires:
UPDATE Spring26_S008_T10_Inventory
   SET quantity_on_hand = 3.00
 WHERE ingredient_id = 5;

-- Now restock all three low items (simulates a delivery arriving):
UPDATE Spring26_S008_T10_Inventory
   SET quantity_on_hand = 40.00
 WHERE ingredient_id = 5;   -- Granola restocked

UPDATE Spring26_S008_T10_Inventory
   SET quantity_on_hand = 25.00
 WHERE ingredient_id = 8;   -- Honey restocked

UPDATE Spring26_S008_T10_Inventory
   SET quantity_on_hand = 20.00
 WHERE ingredient_id = 13;  -- Strawberry Ice Cream restocked

-- -------------------------------------------------------------
-- UPDATE 2: Add a new supplier + contacts
-- Effect on queries: Division query dataset expands
-- -------------------------------------------------------------
INSERT INTO Spring26_S008_T10_Supplier VALUES (41, 'SunRipe Organics');
INSERT INTO Spring26_S008_T10_Supplier_Contact VALUES (41, '945-555-0601', 'hello@sunripe.com');
INSERT INTO Spring26_S008_T10_Supplier_Contact VALUES (41, '945-555-0602', 'orders@sunripe.com');

-- -------------------------------------------------------------
-- UPDATE 3: Add a new delivery from the new supplier (received by staff 5)
-- Effect on queries: CUBE delivery cost query
-- total_cost = 85.00 + 95.00 + 48.00 = 228.00
-- -------------------------------------------------------------
INSERT INTO Spring26_S008_T10_Delivery VALUES (41, DATE '2026-03-28', 228.00, 5, 41);
-- Strawberry Chunks
INSERT INTO Spring26_S008_T10_Delivery_Item VALUES (41, 3,  45.00,  85.00);
-- Banana Slices
INSERT INTO Spring26_S008_T10_Delivery_Item VALUES (41, 4,  50.00,  95.00);
-- Blueberry Chunks
INSERT INTO Spring26_S008_T10_Delivery_Item VALUES (41, 9,  25.00,  48.00);

-- -------------------------------------------------------------
-- UPDATE 4: Add 8 new orders clustered at 12:00 (lunch rush)
-- Effect on queries: Peak Sales Hours shifts hour 12 higher,
--   top-selling products changes, average transaction value changes
-- -------------------------------------------------------------
INSERT INTO Spring26_S008_T10_Orders VALUES (1051, TIMESTAMP '2026-03-28 12:05:00',  9.50);
INSERT INTO Spring26_S008_T10_Orders VALUES (1052, TIMESTAMP '2026-03-28 12:08:00',  8.75);
INSERT INTO Spring26_S008_T10_Orders VALUES (1053, TIMESTAMP '2026-03-28 12:12:00', 17.25);
INSERT INTO Spring26_S008_T10_Orders VALUES (1054, TIMESTAMP '2026-03-28 12:15:00',  9.50);
INSERT INTO Spring26_S008_T10_Orders VALUES (1055, TIMESTAMP '2026-03-28 12:22:00',  8.25);
INSERT INTO Spring26_S008_T10_Orders VALUES (1056, TIMESTAMP '2026-03-28 12:30:00',  9.50);
INSERT INTO Spring26_S008_T10_Orders VALUES (1057, TIMESTAMP '2026-03-28 12:41:00', 17.00);
INSERT INTO Spring26_S008_T10_Orders VALUES (1058, TIMESTAMP '2026-03-28 12:55:00',  7.75);

-- Contained rows for new orders (Acai Bowl is top seller)
INSERT INTO Spring26_S008_T10_Contained VALUES (1051, 13, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1052, 14, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1053, 2,  1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1053, 13, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1054, 13, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1055, 6,  1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1056, 13, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1057, 1,  1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1057, 13, 1);
INSERT INTO Spring26_S008_T10_Contained VALUES (1058, 5,  1);

-- Customizations on two new orders
INSERT INTO Spring26_S008_T10_Contain_Customization VALUES (1051, 13, 'extra granola');
INSERT INTO Spring26_S008_T10_Contain_Customization VALUES (1054, 13, 'add honey');
INSERT INTO Spring26_S008_T10_Contain_Customization VALUES (1056, 13, 'no banana');

-- -------------------------------------------------------------
-- UPDATE 5: Add new shifts for staff 5 (received new delivery above)
-- Effect on queries: labor cost report
-- -------------------------------------------------------------
INSERT INTO Spring26_S008_T10_Shift VALUES (5, DATE '2026-03-28',
    TIMESTAMP '2026-03-28 08:00:00', TIMESTAMP '2026-03-28 16:00:00');

-- -------------------------------------------------------------
-- UPDATE 6: Delete a customization row (tests FK/cascade behavior)
-- Effect on queries: Contain_Customization count changes
-- -------------------------------------------------------------
DELETE FROM Spring26_S008_T10_Contain_Customization
 WHERE order_num = 1004
   AND product_id = 14
   AND customization = 'no banana';

-- -------------------------------------------------------------
-- UPDATE 7: Update a contained quantity
-- Effect on queries: Top-selling products, revenue queries
-- -------------------------------------------------------------
UPDATE Spring26_S008_T10_Contained
   SET quantity = 3
 WHERE order_num = 1032
   AND product_id = 13;

-- Adjust the corresponding order total to match (3 acai bowls = 28.50)
UPDATE Spring26_S008_T10_Orders
   SET total_price = 28.50
 WHERE order_num = 1032;

COMMIT;

-- =============================================================
-- EXPECTED QUERY RESULT CHANGES AFTER THIS SCRIPT:
-- Q1 (Top-Selling Products): Acai Bowl count increases further
-- Q2 (Peak Hours): Hour 12 moves up significantly
-- Q4 (Revenue ROLLUP): bowl revenue and grand totals change due to new orders
-- Q5 (Delivery CUBE): New March delivery from new supplier appears
-- =============================================================
-- END OF UPDATE SCRIPT
-- =============================================================
