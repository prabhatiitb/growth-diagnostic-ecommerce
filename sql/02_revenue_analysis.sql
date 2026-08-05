-- ============================================================
-- REVENUE, AOV & CATEGORY ANALYSIS
-- Business question: is growth healthy, and where does revenue come from?
-- ============================================================

-- Monthly revenue trend + order count + AOV
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    ROUND(SUM(oi.price), 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS num_orders,
    ROUND(SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS aov
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY month
ORDER BY month;

-- Overall AOV
SELECT ROUND(SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS overall_aov
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31';

-- Top categories by revenue
SELECT
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    ROUND(SUM(oi.price), 2) AS category_revenue,
    COUNT(DISTINCT oi.order_id) AS num_orders
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o ON oi.order_id = o.order_id
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY category
ORDER BY category_revenue DESC
LIMIT 15;

-- KEY FINDING:
-- Revenue grew steadily through 2017, peaked at Black Friday (Nov 2017, R$987,765),
-- then plateaued between R$820K-980K/month through mid-2018 with no compounding growth.
-- health_beauty leads revenue (R$1.23M) AND order count (8,610) -> frequency-driver category.
-- watches_gifts is #2 revenue (R$1.16M) with far fewer orders (5,491) -> high-ticket, low-frequency category.
