-- ============================================================
-- UNIT ECONOMICS BY GEOGRAPHY
-- Business question: which regions have the economics to support investment?
-- LIMITATION (state explicitly): Olist's public dataset has no COGS or marketing
-- spend data, so this is a fulfillment-cost efficiency proxy (freight as % of
-- order value), not full net-profit unit economics.
-- ============================================================

SELECT
    c.customer_state,
    SUM(oi.price) AS total_price,
    SUM(oi.freight_value) AS total_freight,
    COUNT(DISTINCT o.order_id) AS num_orders,
    ROUND(SUM(oi.freight_value) * 100.0 / SUM(oi.price), 2) AS freight_pct_of_price,
    ROUND(SUM(oi.price) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY c.customer_state
ORDER BY num_orders DESC;

-- KEY FINDING:
-- Sao Paulo (SP, Olist's hub): 40,406 orders, freight = 13.85% of order value (most efficient)
-- Remote states (RR, MA, PI): far fewer orders, freight = 24-28% of order value (nearly 2x worse)
-- High-volume states cluster near the operational hub and have better fulfillment economics.
-- Implication: geographic expansion into remote/low-density states brings weaker unit
-- economics unless paired with a regional fulfillment hub - the same tension quick-commerce
-- players (Blinkit/Zepto) face with dark-store placement.
