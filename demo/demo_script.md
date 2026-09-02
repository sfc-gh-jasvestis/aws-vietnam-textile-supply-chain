# Fabric Supply Chain

**Vietnam - Textile & Garment**
Use case: Supply Chain Visibility

> Fabric Supply Chain for Vietnam - ML.FORECAST and Dynamic Tables power real-time supply chain visibility intelligence for textile & garment in Ho Chi Minh City & Binh Duong.

## Why Snowflake

Snowflake delivers supply chain visibility intelligence for Vietnamese textile & garment - Dynamic Tables maintain real-time dashboards, ML.FORECAST projects key metrics, and Cortex AI generates recommendations

- **ML.FORECAST for supply chain visibility** - Only demo for Vietnamese textile & garment
- **ML.ANOMALY_DETECTION early warning** - Detects deviations before impact
- **AI recommendations** - Cortex AI actionable guidance
- **Vietnamese context** - Local names, VND economics

## What is deployed

| | |
|---|---|
| Database | `VIETNAM_TEXTILE_SUPPLY_CHAIN` |
| Service | `VIETNAM_TEXTILE_SUPPLY_CHAIN_APP` |
| Compute pool | `SEA_DEMOS_VIETNAM_POOL` |
| Dimension table | `RAW.DOCUMENTS` (20 rows) |
| Fact table | `RAW.METRICS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | VND (₫) |

Regions in play: Ho Chi Minh City, Hanoi, Binh Duong, Dong Nai, Can Tho
Segments: Cotton Knit, Synthetic Woven, Denim, Technical Fabric

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh VIETNAM_TEXTILE_SUPPLY_CHAIN
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Fabric On-Time | `87%` | average per event |
| Active Suppliers | `124` | total across Documents |
| Lead Time (Avg) | `28 days` | average per event |
| Inventory Days | `18` | average per event |
| Fabric Utilization | `92%` | average per event |
| Trim Availability | `97%` | average per event |
| Import Dependency | `64%` | average per event |


## Demo flow

1. Overview
2. Analytics
3. AI Intelligence
4. Ask AI
5. Architecture

## Talking points

- **100K operations** - tracked in Ho Chi Minh City & Binh Duong
- **500K metrics** - time-series data points
- **5K assets** - monitored
- **100 docs** - searchable

## Business impact

- Vietnam textile & garment sector growing rapidly (GSO Vietnam)
- AI improves outcomes 15-30% (McKinsey)
- Vietnam FDI strong in this sector (MPI)
- Real-time analytics reduces response 60-80% (Gartner)

---
Generated from `generator/demo_specs/aws-vietnam-textile-supply-chain.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-vietnam-textile-supply-chain` instead.
