-- Synthetic supplier observations for a fictional garment manufacturing supply
-- chain in Vietnam. 40 suppliers = 8 cities x 5 material
-- categories. Nothing is seeded as a prediction. Randomness is HASH-seeded, so
-- every rebuild is reproducible: per-supplier delivery-miss propensity, drift
-- between periodic supplier performance reviews, skipped reviews,
-- category-weighted exception signals, false-positive exception flags, and two
-- area-wide customs clearance system outages (Binh Duong and Nam Dinh). Exception checks are demo
-- signals, not supplier audit or qualification verdicts.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.SUPPLIERS AS
WITH suppliers AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS SUPPLIER_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT SUPPLIER_INDEX,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-program')), 1000000) / 1e6 AS U_PROGRAM,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-review')), 1000000) / 1e6 AS U_REVIEW,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-tier')), 1000000) / 1e6 AS U_TIER,
         MOD(ABS(HASH(SUPPLIER_INDEX, 'vntxsc-size')), 1000000) / 1e6 AS U_SIZE
  FROM suppliers
), suppliers_named AS (
  SELECT *,
         -- Every city x material category combination appears exactly once.
         CASE MOD(SUPPLIER_INDEX, 8) WHEN 0 THEN 'Nam Dinh' WHEN 1 THEN 'Thai Binh'
              WHEN 2 THEN 'Hung Yen' WHEN 3 THEN 'Da Nang' WHEN 4 THEN 'Long An'
              WHEN 5 THEN 'Ho Chi Minh City' WHEN 6 THEN 'Binh Duong'
              ELSE 'Dong Nai' END AS REGION,
         CASE FLOOR(SUPPLIER_INDEX / 8) WHEN 0 THEN 'Trims and accessories supplier'
              WHEN 1 THEN 'Cotton yarn supplier' WHEN 2 THEN 'Woven fabric supplier'
              WHEN 3 THEN 'Dyes and chemicals supplier' ELSE 'Knit fabric supplier' END AS CATEGORY
  FROM draws
)
SELECT 'TSP-' || LPAD(SUPPLIER_INDEX::VARCHAR, 4, '0') AS ID,
       REGION || ' ' || CATEGORY AS NAME,
       REGION, CATEGORY, SUPPLIER_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.5 + U_PROGRAM * 7.5, 1) AS PROGRAM_YEARS,
       ROUND(0.6 + U_SIZE * 0.8, 3) AS SIZE_FACTOR,
       -- Base daily probability of a confirmed delivery miss, higher for
       -- capacity-constrained categories (woven fabric, dyes and chemicals); ~15% of suppliers are weak links (x3).
       (0.004 + U_RATE * 0.020)
         * CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 0.45 WHEN 'Cotton yarn supplier' THEN 0.75
                         WHEN 'Woven fabric supplier' THEN 1.45 WHEN 'Dyes and chemicals supplier' THEN 1.35
                         ELSE 1.1 END
         * IFF(U_RATE > 0.85, 3, 1) AS BASE_MISS_RATE,
       7 * (1 + FLOOR(U_REVIEW * 3)) AS REVIEW_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS REVIEW_RETURN_PROB,
       -- Share of shipped units that typically arrive after the PO commit date.
       CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 3 WHEN 'Cotton yarn supplier' THEN 6
                     WHEN 'Woven fabric supplier' THEN 15 WHEN 'Dyes and chemicals supplier' THEN 11
                     ELSE 9 END AS BASE_LATE_PCT,
       'Active' AS STATUS
FROM suppliers_named;

CREATE TABLE RAW.SUPPLIER_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), outage_events AS (
  -- Two area-wide customs clearance system outages; every supplier in the city gets a flag.
  SELECT * FROM VALUES (27, 'Binh Duong'), (64, 'Nam Dinh') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT s.ID AS ENTITY_ID, s.SUPPLIER_INDEX, s.CATEGORY, s.REGION, s.PROGRAM_YEARS,
         s.SIZE_FACTOR, s.BASE_LATE_PCT,
         s.BASE_MISS_RATE, s.REVIEW_INTERVAL_DAYS, s.REVIEW_RETURN_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + s.SUPPLIER_INDEX * 3, s.REVIEW_INTERVAL_DAYS) AS DAYS_SINCE_REVIEW,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-miss')), 1000000) / 1e6 AS U_MISS,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-fp')), 1000000) / 1e6 AS U_FP,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-signal')), 1000000) / 1e6 AS U_SIG,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-ship')), 1000000) / 1e6 AS U_SHIP,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(s.ID, d.DAY_INDEX, 'vntxsc-hold')), 1000000) / 1e6 AS U_HOLD,
         o.REGION IS NOT NULL AS OUTAGE_EVENT
  FROM RAW.SUPPLIERS s CROSS JOIN days d
  LEFT JOIN outage_events o ON o.DAY_INDEX = d.DAY_INDEX AND o.REGION = s.REGION
), reviews AS (
  SELECT *,
         IFF(DAYS_SINCE_REVIEW = 0, 1, 0) AS REVIEW_DUE,
         IFF(DAYS_SINCE_REVIEW = 0 AND U_DONE < REVIEW_RETURN_PROB, 1, 0) AS REVIEW_DONE,
         -- Delivery drift rises between supplier performance reviews; weak follow-up carries it over.
         DAYS_SINCE_REVIEW / REVIEW_INTERVAL_DAYS + (1 - REVIEW_RETURN_PROB) AS DRIFT
  FROM base
), activity AS (
  SELECT *,
         CASE WHEN U_MISS < LEAST(0.5, BASE_MISS_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) / 4 THEN 2
              WHEN U_MISS < LEAST(0.5, BASE_MISS_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + PROGRAM_YEARS))) THEN 1
              ELSE 0 END AS MISS_COUNT
  FROM reviews
), checks AS (
  SELECT *,
         -- Fabric and trim receiving inspections confirm about 80% of misses; the rest stays undetected.
         IFF(OUTAGE_EVENT, 0, IFF(U_DETECT < 0.80, MISS_COUNT, 0)) AS CONFIRMED_COUNT,
         -- False-positive flags (cleared on receipt): higher where ASN data is weaker.
         IFF(OUTAGE_EVENT, 1, IFF(U_FP < CASE CATEGORY WHEN 'Woven fabric supplier' THEN 0.15
                                              WHEN 'Dyes and chemicals supplier' THEN 0.14
                                              WHEN 'Knit fabric supplier' THEN 0.12
                                              WHEN 'Cotton yarn supplier' THEN 0.09 ELSE 0.06 END, 1, 0)) AS FALSE_POSITIVE_COUNT
  FROM activity
), measured AS (
  SELECT *,
         CONFIRMED_COUNT + FALSE_POSITIVE_COUNT AS FLAG_COUNT,
         ROUND(CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 7 WHEN 'Cotton yarn supplier' THEN 8
                             WHEN 'Woven fabric supplier' THEN 5 WHEN 'Dyes and chemicals supplier' THEN 4 ELSE 7 END
               * SIZE_FACTOR * (0.7 + 0.6 * U_SHIP)) AS SHIPMENT_COUNT,
         -- Thousand units (pieces of trims, kg of yarn, metres of woven fabric, kg of dyes, kg of knit fabric) per inbound shipment.
         CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 150 WHEN 'Cotton yarn supplier' THEN 18
                       WHEN 'Woven fabric supplier' THEN 11 WHEN 'Dyes and chemicals supplier' THEN 6
                       ELSE 12 END
           * (0.9 + 0.2 * U_NOISE) AS AVG_SHIPMENT_KUNITS,
         LEAST(95, BASE_LATE_PCT + 6 * DRIFT + 9 * MISS_COUNT + 2 * U_NOISE) AS LATE_SHARE
  FROM checks
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       SHIPMENT_COUNT,
       ROUND(SHIPMENT_COUNT * AVG_SHIPMENT_KUNITS * (1 - LATE_SHARE / 100), 2) AS ONTIME_KUNITS,
       ROUND(SHIPMENT_COUNT * AVG_SHIPMENT_KUNITS, 2) AS SHIPPED_KUNITS,
       FLAG_COUNT, CONFIRMED_COUNT,
       IFF(CONFIRMED_COUNT > 0 AND U_HOLD < 0.56, 1, 0) AS LOTS_QUARANTINED,
       CASE WHEN FLAG_COUNT = 0 THEN 'None'
            WHEN OUTAGE_EVENT THEN 'Customs clearance system outage'
            WHEN CATEGORY = 'Trims and accessories supplier' THEN IFF(U_SIG < 0.6, 'ASN quantity mismatch', 'Test report missing')
            WHEN CATEGORY = 'Cotton yarn supplier' THEN IFF(U_SIG < 0.55, 'Yarn count deviation', 'Carrier pickup missed')
            WHEN CATEGORY = 'Woven fabric supplier' THEN IFF(U_SIG < 0.45, 'Loom capacity cut', IFF(U_SIG < 0.8, 'Commit date slipped', 'ASN quantity mismatch'))
            WHEN CATEGORY = 'Dyes and chemicals supplier' THEN IFF(U_SIG < 0.55, 'Dye lot shade out of tolerance', 'Dangerous goods declaration pending')
            ELSE IFF(U_SIG < 0.5, 'Unannounced process change', 'Commit date slipped') END AS RISK_SIGNAL,
       REVIEW_DUE, REVIEW_DONE,
       ROUND(0.4 + 1.8 * DRIFT + 3.2 * MISS_COUNT + U_NOISE * 0.9, 2) AS ASN_VARIANCE_PCT,
       ROUND(LATE_SHARE, 1) AS LATE_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Material qualification snapshot per supplier: active material codes, codes with a
-- qualified second source on file, and second-source qualifications in progress.
CREATE TABLE RAW.MATERIAL_QUALIFICATION AS
WITH sized AS (
  SELECT ID, CATEGORY,
         ROUND(CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 280 WHEN 'Cotton yarn supplier' THEN 60
                             WHEN 'Woven fabric supplier' THEN 85 WHEN 'Dyes and chemicals supplier' THEN 40 ELSE 110 END
               * (0.6 + MOD(ABS(HASH(ID, 'vntxsc-codes')), 1000000) / 1e6 * 0.8)) AS MATERIAL_CODES,
         CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 0.78 WHEN 'Cotton yarn supplier' THEN 0.66
                       WHEN 'Woven fabric supplier' THEN 0.31 WHEN 'Dyes and chemicals supplier' THEN 0.44 ELSE 0.57 END
           + MOD(ABS(HASH(ID, 'vntxsc-second')), 1000000) / 1e6 * 0.25 AS SECOND_SOURCE_SHARE
  FROM RAW.SUPPLIERS
)
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Trims and accessories supplier' THEN 'Alternate trim qualification'
                     WHEN 'Cotton yarn supplier' THEN 'Spinning mill qualification'
                     WHEN 'Woven fabric supplier' THEN 'Weaving mill qualification'
                     WHEN 'Dyes and chemicals supplier' THEN 'Dye recipe qualification'
                     ELSE 'Knitting mill qualification' END AS EVIDENCE_TYPE,
       MATERIAL_CODES AS REQUIRED_QTY,
       LEAST(MATERIAL_CODES, ROUND(MATERIAL_CODES * SECOND_SOURCE_SHARE)) AS ON_FILE_QTY,
       ROUND((MATERIAL_CODES - LEAST(MATERIAL_CODES, ROUND(MATERIAL_CODES * SECOND_SOURCE_SHARE))) * MOD(ABS(HASH(ID, 'vntxsc-pending')), 1000000) / 1e6 * 0.5) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM sized;
