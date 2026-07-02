-- ============================================
-- SCRIPT 2A: DELETE - SCENARIO A (DEDICATED CLIENT)
-- Author: Lunga Ndzimande
-- Ticket: Multi-User Offboarding
-- Environment: REL (Release)
-- Use this ONLY for clients confirmed as DEDICATED (1 user only)
-- ONLY RUN AFTER PEER REVIEW AND BACKUPS VERIFIED
-- ============================================

-- Auto-generate delete statements for a dedicated client
-- Replace 1458 with the actual dedicated clientId

SELECT CONCAT('DELETE FROM ', TABLE_NAME, ' WHERE clientId = <dedicated_clientId>;')
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'UDM__'
AND COLUMN_NAME LIKE '%clientId%'
ORDER BY TABLE_NAME ASC;
