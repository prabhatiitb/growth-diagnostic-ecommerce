-- ============================================================
-- COHORT & RETENTION ANALYSIS
-- Business question: are we retaining customers, or just acquiring new ones?
-- Broken into staged temp tables (not one nested CTE) for performance on 100K+ rows.
-- ============================================================

-- Step 1: delivered orders with customer_unique_id and order month
CREATE TABLE tmp_customer_orders AS
SELECT
    c.customer_unique_id,
    o.order_id,
    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31';

-- Step 2: each customer's first-ever order month = their cohort
CREATE TABLE tmp_first_purchase AS
SELECT customer_unique_id, MIN(order_month) AS cohort_month
FROM tmp_customer_orders
GROUP BY customer_unique_id;

-- Step 3: tag every order with "months since first purchase"
CREATE TABLE tmp_cohort_activity AS
SELECT
    f.cohort_month,
    co.customer_unique_id,
    (CAST(SUBSTR(co.order_month,1,4) AS INT) - CAST(SUBSTR(f.cohort_month,1,4) AS INT)) * 12
      + (CAST(SUBSTR(co.order_month,6,2) AS INT) - CAST(SUBSTR(f.cohort_month,6,2) AS INT)) AS month_number
FROM tmp_customer_orders co
JOIN tmp_first_purchase f ON co.customer_unique_id = f.customer_unique_id;

-- Step 4: cohort sizes (headcount at month 0)
CREATE TABLE tmp_cohort_size AS
SELECT cohort_month, COUNT(DISTINCT customer_unique_id) AS num_customers
FROM tmp_cohort_activity
WHERE month_number = 0
GROUP BY cohort_month;

-- Step 5: final retention % table (cohort x month_number triangle)
SELECT
    ca.cohort_month,
    ca.month_number,
    COUNT(DISTINCT ca.customer_unique_id) AS active_customers,
    cs.num_customers AS cohort_size,
    ROUND(COUNT(DISTINCT ca.customer_unique_id) * 100.0 / cs.num_customers, 2) AS retention_pct
FROM tmp_cohort_activity ca
JOIN tmp_cohort_size cs ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, ca.month_number
ORDER BY ca.cohort_month, ca.month_number;

-- KEY FINDING:
-- Every single cohort (Jan 2017 - Jul 2018) shows the same pattern:
-- 100% active at Month 0, collapsing to <1% by Month 1, staying near-zero after.
-- This means retention is structurally near-zero, not a recent decline -
-- revenue growth has always depended entirely on new-customer acquisition volume.
