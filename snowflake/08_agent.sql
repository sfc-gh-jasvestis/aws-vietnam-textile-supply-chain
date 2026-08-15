-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Fabric Supply Chain
-- ============================================================================
USE DATABASE TEXTILE_SUPPLY_CHAIN;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.TEXTILE_SUPPLY_CHAIN_AGENT
  COMMENT = 'Fabric Supply Chain AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'TEXTILE_SUPPLY_CHAIN.APP.TEXTILE_SUPPLY_CHAIN_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'TEXTILE_SUPPLY_CHAIN.SEARCH.TEXTILE_SUPPLY_CHAIN_SEARCH', TOOL_DESCRIPTION => 'Search documents for Textile & Garment information')
  )
  SYSTEM_PROMPT = 'You are the Supply Chain Visibility Agent for Vietnamese textile & garment operations in Ho Chi Minh City & Binh Duong.';
