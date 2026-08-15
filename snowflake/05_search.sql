-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Fabric Supply Chain
-- ============================================================================
USE DATABASE TEXTILE_SUPPLY_CHAIN;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.TEXTILE_SUPPLY_CHAIN_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, CATEGORY
  WAREHOUSE = TEXTILE_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.DOCUMENTS
);
