-- =============================================================
-- Team 10 | CSE 3330/5330-008 | Spring 2026
-- Members: Zheng Yao Wong, Roberto Lira, Mahad Imran, Kaung Zaw Thant
-- File: projectDBcreate.sql
-- Purpose: Create all 13 tables in dependency order (parents first)
-- Prefix: Spring26_S008_T10_
-- =============================================================

-- -------------------------------------------------------------
-- TIER 1: No foreign key dependencies
-- -------------------------------------------------------------

CREATE TABLE Spring26_S008_T10_Ingredient (
    ingredient_id       NUMBER(5)       PRIMARY KEY,
    ingredient_name     VARCHAR2(100)   NOT NULL,
    unit_of_measurement VARCHAR2(30)    NOT NULL
);

CREATE TABLE Spring26_S008_T10_Supplier (
    supplier_id     NUMBER(5)       PRIMARY KEY,
    company_name    VARCHAR2(100)   NOT NULL
);

CREATE TABLE Spring26_S008_T10_Staff (
    staff_id    NUMBER(5)       PRIMARY KEY,
    first_name  VARCHAR2(50)    NOT NULL,
    last_name   VARCHAR2(50)    NOT NULL,
    hourly_rate NUMBER(5,2)     NOT NULL CHECK (hourly_rate > 0)
);

CREATE TABLE Spring26_S008_T10_Menu (
    product_id      NUMBER(5)       PRIMARY KEY,
    product_name    VARCHAR2(100)   NOT NULL,
    category        VARCHAR2(20)    NOT NULL
                        CHECK (category IN ('smoothie', 'bowl', 'ice cream')),
    price           NUMBER(5,2)     NOT NULL CHECK (price > 0)
);

CREATE TABLE Spring26_S008_T10_Orders (
    order_num           NUMBER(7)       PRIMARY KEY,
    order_timestamp     TIMESTAMP       NOT NULL,
    total_price         NUMBER(7,2)     NOT NULL CHECK (total_price >= 0)
);

-- -------------------------------------------------------------
-- TIER 2: Reference Tier 1 tables
-- -------------------------------------------------------------

CREATE TABLE Spring26_S008_T10_Inventory (
    inventory_id        NUMBER(5)       PRIMARY KEY,
    reorder_threshold   NUMBER(8,2)     NOT NULL CHECK (reorder_threshold >= 0),
    quantity_on_hand    NUMBER(8,2)     NOT NULL CHECK (quantity_on_hand >= 0),
    ingredient_id       NUMBER(5)       NOT NULL UNIQUE,
    CONSTRAINT fk_inv_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES Spring26_S008_T10_Ingredient(ingredient_id)
);

CREATE TABLE Spring26_S008_T10_Supplier_Contact (
    supplier_id NUMBER(5)       NOT NULL,
    phone       VARCHAR2(20)    NOT NULL,
    email       VARCHAR2(100)   NOT NULL,
    CONSTRAINT pk_supplier_contact
        PRIMARY KEY (supplier_id, phone, email),
    CONSTRAINT fk_sc_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES Spring26_S008_T10_Supplier(supplier_id)
);

CREATE TABLE Spring26_S008_T10_Shift (
    staff_id    NUMBER(5)   NOT NULL,
    shift_date  DATE        NOT NULL,
    clock_in    TIMESTAMP   NOT NULL,
    clock_out   TIMESTAMP   NOT NULL,
    CONSTRAINT pk_shift
        PRIMARY KEY (staff_id, shift_date),
    CONSTRAINT fk_shift_staff
        FOREIGN KEY (staff_id)
        REFERENCES Spring26_S008_T10_Staff(staff_id),
    CONSTRAINT chk_shift_times
        CHECK (clock_out > clock_in)
);

CREATE TABLE Spring26_S008_T10_Recipe (
    ingredient_id   NUMBER(5)       NOT NULL,
    product_id      NUMBER(5)       NOT NULL,
    amount_required NUMBER(8,3)     NOT NULL CHECK (amount_required > 0),
    CONSTRAINT pk_recipe
        PRIMARY KEY (ingredient_id, product_id),
    CONSTRAINT fk_recipe_ingredient
        FOREIGN KEY (ingredient_id)
        REFERENCES Spring26_S008_T10_Ingredient(ingredient_id),
    CONSTRAINT fk_recipe_menu
        FOREIGN KEY (product_id)
        REFERENCES Spring26_S008_T10_Menu(product_id)
);

CREATE TABLE Spring26_S008_T10_Delivery (
    delivery_id     NUMBER(5)       PRIMARY KEY,
    delivery_date   DATE            NOT NULL,
    total_cost      NUMBER(8,2)     NOT NULL CHECK (total_cost >= 0),
    staff_id        NUMBER(5)       NOT NULL,
    supplier_id     NUMBER(5)       NOT NULL,
    CONSTRAINT fk_delivery_staff
        FOREIGN KEY (staff_id)
        REFERENCES Spring26_S008_T10_Staff(staff_id),
    CONSTRAINT fk_delivery_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES Spring26_S008_T10_Supplier(supplier_id)
);

-- -------------------------------------------------------------
-- TIER 3: Reference Tier 2 tables
-- -------------------------------------------------------------

CREATE TABLE Spring26_S008_T10_Delivery_Item (
    delivery_id         NUMBER(5)       NOT NULL,
    inventory_id        NUMBER(5)       NOT NULL,
    quantity_received   NUMBER(8,2)     NOT NULL CHECK (quantity_received > 0),
    line_cost           NUMBER(8,2)     NOT NULL CHECK (line_cost >= 0),
    CONSTRAINT pk_delivery_item
        PRIMARY KEY (delivery_id, inventory_id),
    CONSTRAINT fk_di_delivery
        FOREIGN KEY (delivery_id)
        REFERENCES Spring26_S008_T10_Delivery(delivery_id),
    CONSTRAINT fk_di_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES Spring26_S008_T10_Inventory(inventory_id)
);

CREATE TABLE Spring26_S008_T10_Contained (
    order_num   NUMBER(7)   NOT NULL,
    product_id  NUMBER(5)   NOT NULL,
    quantity    NUMBER(3)   NOT NULL CHECK (quantity > 0),
    CONSTRAINT pk_contained
        PRIMARY KEY (order_num, product_id),
    CONSTRAINT fk_cont_order
        FOREIGN KEY (order_num)
        REFERENCES Spring26_S008_T10_Orders(order_num),
    CONSTRAINT fk_cont_menu
        FOREIGN KEY (product_id)
        REFERENCES Spring26_S008_T10_Menu(product_id)
);

-- -------------------------------------------------------------
-- TIER 4: References Tier 3 (Contained)
-- -------------------------------------------------------------

CREATE TABLE Spring26_S008_T10_Contain_Customization (
    order_num       NUMBER(7)       NOT NULL,
    product_id      NUMBER(5)       NOT NULL,
    customization   VARCHAR2(100)   NOT NULL,
    CONSTRAINT pk_contain_custom
        PRIMARY KEY (order_num, product_id, customization),
    CONSTRAINT fk_cc_contained
        FOREIGN KEY (order_num, product_id)
        REFERENCES Spring26_S008_T10_Contained(order_num, product_id)
);

-- -------------------------------------------------------------
-- TRIGGERS: Keep derived totals synchronized with child rows
-- -------------------------------------------------------------

CREATE OR REPLACE TRIGGER Spring26_S008_T10_trg_order_total
FOR INSERT OR UPDATE OR DELETE ON Spring26_S008_T10_Contained
COMPOUND TRIGGER
    TYPE t_order_seen IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    g_order_seen t_order_seen;

    PROCEDURE mark_order(p_order_num NUMBER) IS
    BEGIN
        IF p_order_num IS NOT NULL THEN
            g_order_seen(p_order_num) := TRUE;
        END IF;
    END mark_order;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING OR UPDATING THEN
            mark_order(:NEW.order_num);
        END IF;

        IF DELETING OR UPDATING THEN
            mark_order(:OLD.order_num);
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        l_order_num PLS_INTEGER;
    BEGIN
        l_order_num := g_order_seen.FIRST;

        WHILE l_order_num IS NOT NULL LOOP
            UPDATE Spring26_S008_T10_Orders o
               SET total_price = NVL((
                       SELECT ROUND(SUM(c.quantity * m.price), 2)
                         FROM Spring26_S008_T10_Contained c
                         JOIN Spring26_S008_T10_Menu m
                           ON m.product_id = c.product_id
                        WHERE c.order_num = l_order_num
                   ), 0)
             WHERE o.order_num = l_order_num;

            l_order_num := g_order_seen.NEXT(l_order_num);
        END LOOP;
    END AFTER STATEMENT;
END Spring26_S008_T10_trg_order_total;
/

CREATE OR REPLACE TRIGGER Spring26_S008_T10_trg_contained_delete
BEFORE DELETE ON Spring26_S008_T10_Contained
FOR EACH ROW
BEGIN
    DELETE FROM Spring26_S008_T10_Contain_Customization
     WHERE order_num = :OLD.order_num
       AND product_id = :OLD.product_id;
END Spring26_S008_T10_trg_contained_delete;
/

CREATE OR REPLACE TRIGGER Spring26_S008_T10_trg_delivery_total
FOR INSERT OR UPDATE OR DELETE ON Spring26_S008_T10_Delivery_Item
COMPOUND TRIGGER
    TYPE t_delivery_seen IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    g_delivery_seen t_delivery_seen;

    PROCEDURE mark_delivery(p_delivery_id NUMBER) IS
    BEGIN
        IF p_delivery_id IS NOT NULL THEN
            g_delivery_seen(p_delivery_id) := TRUE;
        END IF;
    END mark_delivery;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING OR UPDATING THEN
            mark_delivery(:NEW.delivery_id);
        END IF;

        IF DELETING OR UPDATING THEN
            mark_delivery(:OLD.delivery_id);
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        l_delivery_id PLS_INTEGER;
    BEGIN
        l_delivery_id := g_delivery_seen.FIRST;

        WHILE l_delivery_id IS NOT NULL LOOP
            UPDATE Spring26_S008_T10_Delivery d
               SET total_cost = NVL((
                       SELECT ROUND(SUM(di.line_cost), 2)
                         FROM Spring26_S008_T10_Delivery_Item di
                        WHERE di.delivery_id = l_delivery_id
                   ), 0)
             WHERE d.delivery_id = l_delivery_id;

            l_delivery_id := g_delivery_seen.NEXT(l_delivery_id);
        END LOOP;
    END AFTER STATEMENT;
END Spring26_S008_T10_trg_delivery_total;
/

-- =============================================================
-- END OF CREATE SCRIPT
-- =============================================================
