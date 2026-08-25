-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Fabric Supply Chain
-- ============================================================================
USE DATABASE TEXTILE_SUPPLY_CHAIN;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_vietnam_textile_supply_chain_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: PERFORMANCE_ALERT
CREATE OR REPLACE ALERT APP.PERFORMANCE_ALERT
  WAREHOUSE = TEXTILE_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Supply Chain Visibility performance below threshold'
IF (EXISTS (
  SELECT 1 FROM CURATED.PERFORMANCE_DASHBOARD
  WHERE 1=1 -- Condition: Key metric below threshold
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_vietnam_textile_supply_chain_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Fabric Supply Chain: Supply Chain Visibility performance below threshold',
    'Supply Chain Visibility performance below threshold'
  );

ALTER ALERT APP.PERFORMANCE_ALERT RESUME;

-- Alert: ANOMALY_ALERT
CREATE OR REPLACE ALERT APP.ANOMALY_ALERT
  WAREHOUSE = TEXTILE_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Anomalous pattern detected'
IF (EXISTS (
  SELECT 1 FROM CURATED.PERFORMANCE_DASHBOARD
  WHERE 1=1 -- Condition: ML detects anomaly
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_vietnam_textile_supply_chain_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Fabric Supply Chain: Anomalous pattern detected',
    'Anomalous pattern detected'
  );

ALTER ALERT APP.ANOMALY_ALERT RESUME;

