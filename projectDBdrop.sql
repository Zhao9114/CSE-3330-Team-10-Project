-- =============================================================
-- Team 10 | CSE 3330/5330-008 | Spring 2026
-- Members: Zheng Yao Wong, Roberto Lira, Mahad Imran, Kaung Zaw Thant
-- File: projectDBdrop.sql
-- Purpose: Drop all 13 tables in reverse creation order (children first)
-- =============================================================

-- TIER 4
DROP TABLE Spring26_S008_T10_Contain_Customization PURGE;

-- TIER 3
DROP TABLE Spring26_S008_T10_Delivery_Item         PURGE;
DROP TABLE Spring26_S008_T10_Contained             PURGE;

-- TIER 2
DROP TABLE Spring26_S008_T10_Delivery              PURGE;
DROP TABLE Spring26_S008_T10_Recipe                PURGE;
DROP TABLE Spring26_S008_T10_Shift                 PURGE;
DROP TABLE Spring26_S008_T10_Supplier_Contact      PURGE;
DROP TABLE Spring26_S008_T10_Inventory             PURGE;

-- TIER 1
DROP TABLE Spring26_S008_T10_Orders                PURGE;
DROP TABLE Spring26_S008_T10_Menu                  PURGE;
DROP TABLE Spring26_S008_T10_Staff                 PURGE;
DROP TABLE Spring26_S008_T10_Supplier              PURGE;
DROP TABLE Spring26_S008_T10_Ingredient            PURGE;

PURGE RECYCLEBIN;

-- =============================================================
-- END OF DROP SCRIPT
-- =============================================================
