"""
RFM Segmentation - Recency, Frequency, Monetary analysis
Business question: who are our valuable customers, and are we protecting them?

Note on methodology: 97% of customers in this dataset ordered exactly once
(90,315 of 93,104), so Frequency has almost no variance. Standard pd.qcut()
quintiles fail on a field this skewed - a manual business-rule score is used
for Frequency instead, while Recency and Monetary use standard quintiles.
"""

import pandas as pd
import sqlite3

conn = sqlite3.connect('olist.db')  # adjust path to your local .db file

query = """
SELECT
    c.customer_unique_id,
    o.order_id,
    o.order_purchase_timestamp,
    SUM(oi.price) AS order_price,
    SUM(oi.freight_value) AS order_freight
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY c.customer_unique_id, o.order_id, o.order_purchase_timestamp
"""
df = pd.read_sql(query, conn)
df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
df['order_total'] = df['order_price'] + df['order_freight']

# Snapshot date = one day after the last order (standard RFM practice)
snapshot_date = df['order_purchase_timestamp'].max() + pd.Timedelta(days=1)

rfm = df.groupby('customer_unique_id').agg(
    last_order_date=('order_purchase_timestamp', 'max'),
    frequency=('order_id', 'nunique'),
    monetary=('order_total', 'sum')
).reset_index()
rfm['recency'] = (snapshot_date - rfm['last_order_date']).dt.days

# Recency & Monetary: standard quintile scoring
rfm['R_score'] = pd.qcut(rfm['recency'], 5, labels=[5, 4, 3, 2, 1]).astype(int)
rfm['M_score'] = pd.qcut(rfm['monetary'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5]).astype(int)

# Frequency: manual scoring (qcut fails - 97% of values are identical)
def freq_score(f):
    if f == 1:
        return 1
    elif f == 2:
        return 3
    else:
        return 5  # 3+ orders is genuinely rare, high-value repeat behavior

rfm['F_score'] = rfm['frequency'].apply(freq_score)

def segment(row):
    if row['F_score'] >= 3 and row['R_score'] >= 4:
        return 'Champions'
    elif row['F_score'] >= 3:
        return 'Loyal (at risk of lapsing)'
    elif row['R_score'] >= 4 and row['M_score'] >= 4:
        return 'Promising New/High-Value'
    elif row['R_score'] <= 2 and row['M_score'] >= 4:
        return 'At Risk (high value, gone quiet)'
    elif row['R_score'] <= 2:
        return 'Lost (one-time, long gone)'
    else:
        return 'Standard One-Timer'

rfm['segment'] = rfm.apply(segment, axis=1)

summary = rfm.groupby('segment').agg(
    customers=('customer_unique_id', 'count'),
    avg_monetary=('monetary', 'mean'),
    total_monetary=('monetary', 'sum')
).sort_values('total_monetary', ascending=False)
summary['pct_of_customers'] = round(summary['customers'] / len(rfm) * 100, 1)
summary['pct_of_revenue'] = round(summary['total_monetary'] / rfm['monetary'].sum() * 100, 1)

print(summary)

# KEY FINDING:
# "Champions" (repeat + recent buyers) = only 1.3% of customers, 2.5% of revenue.
# "Promising New/High-Value" + "At Risk (high value, gone quiet)" = 55.7% of revenue -
# customers who bought once, spent well, and never returned. This is the highest-
# leverage segment for a second-purchase conversion campaign.

rfm.to_csv('rfm_segments.csv', index=False)
conn.close()
