# Textile Supplier Delivery Risk

**Vietnam - Textile and garment supply chain**
Use case: On-time delivery and delivery-miss risk for yarn, fabric, trims and dye suppliers feeding fictional cut-and-sew garment factories

> A fictional Vietnam garment manufacturing supply chain, 40 material suppliers from Nam Dinh, Thai Binh and Hung Yen in the north to Ho Chi Minh City, Binh Duong, Dong Nai and Long An in the south, tracked from mill dispatch to factory receiving: dynamic tables for on-time delivery, a holdout-evaluated delivery-miss classifier, an inbound shipment forecast and grounded AI answers. Exception checks are demo signals, not supplier audit, compliance or qualification verdicts.

## Why Snowflake

- **Dynamic tables** reconcile inbound shipments, on-time delivery, exception flags, confirmed delivery misses and supplier review completion from RAW supplier data, with checks in `run_core.py`
- **Delivery-miss classification** gives a holdout-evaluated next-7-day probability per supplier
- **Shipment forecast** projects 14 days of network-wide inbound shipments with prediction intervals, for receiving and fabric inspection planning
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live shipments**: a native shipment simulator (Snowflake only) or Amazon Data Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.SUPPLIERS` (40 rows) |
| Fact table | `RAW.SUPPLIER_DAILY` (3,600 supplier-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `SIGNAL_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.DELIVERY_RISK_SCORES`, `ML.DELIVERY_RISK_HOLDOUT_METRICS`, `ML.SHIPMENT_FORECAST`, `ML.ASN_VARIANCE_ANOMALIES` |

Cities: Nam Dinh, Thai Binh, Hung Yen, Da Nang, Long An, Ho Chi Minh City, Binh Duong, Dong Nai.
Material categories: Trims and accessories supplier, Cotton yarn supplier, Woven fabric supplier, Dyes and chemicals supplier, Knit fabric supplier.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| On-Time Delivery (units) | 90.0% |
| Inbound Shipments | 23,538 |
| Units Shipped (millions) | 989 |
| Delivery Exception Flags | 573 |
| Confirmed Delivery Misses | 170 |
| Flag Precision | 29.7% |
| Lots Quarantined at Receiving | 78 |
| Supplier Review Completion | 69.1% |
| Suppliers Monitored | 40 |
| Second-Source Coverage | 73.7% |
| Qualifications Pending | 307 |
| Active Material Codes | 4,092 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily inbound shipments against exception flags, flags and confirmed delivery misses by exception signal, supplier table
2. Predictive: holdout metrics, risk bands, 14-day inbound shipment forecast, ASN quantity variance anomalies
3. Supplier Reviews: review completion, second-source coverage and pending qualifications, review completion against confirmed misses, then generate the action memo
4. Live Shipments: run `CALL APP.SIMULATE_SHIPMENTS(20)` (Snowflake only) or `python aws/publish_shipments.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_SHIPMENT_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Fewer than one exception flag in three is confirmed as a delivery miss (29.7%). The rest are false positives, and chasing them is where the sourcing team loses its week while the cutting room waits for fabric.
- "Commit date slipped" produces the most confirmed misses (42) and the most flags (130); "Loom capacity cut" is next (31 of 68). Customs clearance system outage flags hit every supplier in a province at once and are never confirmed.
- TSP-0032 (Nam Dinh knit fabric supplier) has the most confirmed misses (20), and woven fabric suppliers have the lowest on-time delivery (78.7%).
- The risk model is evaluated on a time-based holdout: precision 0.64 and recall 0.42 at 0.5, against a 0.25 base rate. Use it to order supplier calls, not as a verdict. Forecast and anomaly figures can shift slightly with the build day.
- Customs clearance outage days are excluded from model training, because the supplier did not cause them.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
