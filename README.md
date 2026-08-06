# Diagnosing a Growth Plateau: E-Commerce Retention & Unit-Economics Analysis

An end-to-end analytics case study diagnosing why revenue growth flattened for a real
e-commerce marketplace, using SQL, Python, and Tableau — built to answer the questions
a growth-stage company's leadership team would actually ask.

## Business Problem

Revenue growth, once steady, flattened through 2018. Leadership needs answers to:
- Is growth healthy, or is it masking a retention problem?
- Who are our valuable customers, and are we protecting them?
- Which products and categories drive revenue?
- Which regions have the economics to support further investment?

## Dataset

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(Kaggle) — 96,211 delivered orders, 93,104 customers, Jan 2017–Aug 2018.

**A real, publicly verifiable dataset was used deliberately** (over a synthetic one) so every
number in this analysis is checkable and defensible.

## Methodology

| Stage | Tool | What it answers |
|---|---|---|
| Data modeling & cleaning | SQL (SQLite) | Built a relational schema; caught and corrected a data quality issue (`customer_id` is order-level, not person-level — `customer_unique_id` is the true customer key) |
| Revenue & category analysis | SQL | Monthly revenue trend, AOV, top categories |
| Cohort & retention analysis | SQL | Month-by-month retention tracked per acquisition cohort |
| RFM segmentation | Python (pandas) | Customers scored on Recency, Frequency, Monetary value |
| Unit economics | SQL | Freight cost as % of order value, by state |
| Dashboards | Tableau | Executive Summary + Growth & Retention views |
| Synthesis | PowerPoint | Consulting-style findings → recommendations deck |

## Key Findings

1. **Revenue plateaued in 2018** — grew steadily through 2017 (peaking at Black Friday,
   R$987,765 in Nov 2017), then flattened to R$820K–980K/month with no compounding growth.
2. **Retention is structurally near-zero** — every acquisition cohort shows the same
   pattern: 100% active at Month 0, <1% by Month 1. This isn't a decline; there was never
   a repeat-purchase engine.
3. **One-time buyers drive most revenue** — RFM segmentation shows "Champions" are only
   1.3% of customers and 2.5% of revenue. 55.7% of revenue sits with high-value customers
   who bought once and never returned.
4. **Fulfillment cost depends on geography** — freight is 13.85% of order value in the
   core hub state (São Paulo) vs. 24–28% in remote states — expansion into these markets
   would import a margin problem without a regional fulfillment hub.

## Recommendations

1. Launch a second-purchase conversion program targeting the "Promising" and "At Risk"
   RFM segments (55.7% of revenue, near-zero retention).
2. Shift category mix toward repeat-friendly categories (e.g. health_beauty, the current
   #1 category by both revenue and order volume).
3. Prioritize deepening the core hub market before geographic expansion into
   high-freight-cost, low-density states.

## Repo Structure

```
sql/                  -- schema setup, revenue, cohort/retention, unit economics
python/                -- RFM segmentation script
tableau/                -- exported CSVs used as Tableau data sources
presentation/           -- consulting-style findings & recommendations deck
data/                   -- (not included; see Dataset section to download from Kaggle)
```

## Known Limitations (stated explicitly, not hidden)

- No COGS or marketing spend data in the public dataset, so unit economics use freight
  ratio as a fulfillment-efficiency proxy, not full net-profit margin.
- Olist is a general marketplace, not quick-commerce specifically — the retention and
  unit-economics framework is presented as a transferable diagnostic approach, not a
  quick-commerce-specific claim.
- Analysis window restricted to Jan 2017–Aug 2018 to exclude pilot-scale (Sep/Dec 2016)
  and incomplete boundary (Sep/Oct 2018) data.

## Author

Prabhat Kumar — IIT Bombay, Class of 2027
