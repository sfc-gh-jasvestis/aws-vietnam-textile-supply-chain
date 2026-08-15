-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Fabric Supply Chain
-- ============================================================================
USE DATABASE TEXTILE_SUPPLY_CHAIN;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.TEXTILE_SUPPLY_CHAIN_ANALYTICS
  COMMENT = 'Textile & Garment supply chain visibility analytics'
AS
  TABLES (
    CURATED.PERFORMANCE_DASHBOARD AS performance_dashboard,CURATED.TREND_ANALYTICS AS trend_analytics,CURATED.FORECAST_INPUT AS forecast_input,CURATED.OPERATIONAL_RISK AS operational_risk
  );
