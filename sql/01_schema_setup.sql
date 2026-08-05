-- ============================================================
-- SCHEMA SETUP
-- Dataset: Olist Brazilian E-Commerce Public Dataset (Kaggle)
-- Loaded via: DB Browser for SQLite -> File -> Import -> Table from CSV
-- Tables loaded directly from the 6 raw CSVs (see /data folder):
--   olist_customers_dataset
--   olist_orders_dataset
--   olist_order_items_dataset
--   olist_order_payments_dataset
--   olist_products_dataset
--   product_category_name_translation
-- ============================================================

-- IMPORTANT DATA QUALITY NOTE (read before running anything else):
-- customer_id is unique PER ORDER, not per person.
-- customer_unique_id is the true customer identifier.
-- Always GROUP BY / JOIN on customer_unique_id for any customer-level metric
-- (retention, RFM, repeat purchase rate) or repeat customers get miscounted as new.

-- Index join columns for performance (100K+ rows without this = slow/timeout joins)
CREATE INDEX IF NOT EXISTS idx_orders_customer ON olist_orders_dataset(customer_id);

-- Sanity check: row counts after import
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM olist_customers_dataset
UNION ALL SELECT 'orders', COUNT(*) FROM olist_orders_dataset
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items_dataset
UNION ALL SELECT 'order_payments', COUNT(*) FROM olist_order_payments_dataset
UNION ALL SELECT 'products', COUNT(*) FROM olist_products_dataset
UNION ALL SELECT 'category_translation', COUNT(*) FROM product_category_name_translation;

-- Confirm the customer_id vs customer_unique_id data quality issue
SELECT
    COUNT(DISTINCT customer_id) AS order_level_ids,
    COUNT(DISTINCT customer_unique_id) AS real_unique_customers,
    COUNT(DISTINCT customer_id) - COUNT(DISTINCT customer_unique_id) AS hidden_repeat_customers
FROM olist_customers_dataset;

-- Order status breakdown (decide which statuses count as "real" revenue)
SELECT order_status, COUNT(*) AS num_orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY num_orders DESC;

-- Date range check (used to decide the clean analysis window)
SELECT MIN(order_purchase_timestamp) AS earliest_order,
       MAX(order_purchase_timestamp) AS latest_order
FROM olist_orders_dataset;

-- Decision: analysis window restricted to 2017-01-01 -> 2018-08-31
-- Reason: Sep/Dec 2016 = pilot-scale volume (1 order each);
--         Sep/Oct 2018 = incomplete, orders placed but not yet delivered at export time
