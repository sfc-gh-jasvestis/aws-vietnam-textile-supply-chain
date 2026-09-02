-- Generated from generator/demo_specs/aws-vietnam-textile-supply-chain.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-vietnam-textile-supply-chain
-- This is the schema that is actually deployed for VIETNAM_TEXTILE_SUPPLY_CHAIN.

-- VIETNAM_TEXTILE_SUPPLY_CHAIN  (Fabric Supply Chain)
-- generated from generator/demo_specs/aws-vietnam-textile-supply-chain.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS VIETNAM_TEXTILE_SUPPLY_CHAIN;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_SUPPLY_CHAIN.RAW;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_SUPPLY_CHAIN.CURATED;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_SUPPLY_CHAIN.APP;
USE DATABASE VIETNAM_TEXTILE_SUPPLY_CHAIN;

-- 5 real regions; entity names carry their region so the two always agree
