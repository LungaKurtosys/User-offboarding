-- ============================================
-- SCRIPT 1: SAFETY CHECKS & ROW COUNTS
-- Author: Lunga Ndzimande
-- Ticket: Multi-User Offboarding
-- Environment: REL (Release)
-- Run this entire file top to bottom
-- ============================================

-- ============================================
-- STEP 1: CLIENT CONFIRMATION
-- ============================================
SELECT '=== STEP 1: CLIENT CONFIRMATION ===' AS '';
SELECT clientId, clientName, s3Folder
FROM Client
WHERE clientId IN (1, 53, 1096, 1360, 1412, 1449);

-- ============================================
-- STEP 2: SCENARIO CLASSIFICATION
-- ============================================
SELECT '=== STEP 2: SCENARIO CLASSIFICATION ===' AS '';
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) AS total_users,
    CASE
        WHEN COUNT(u.userId) = 1 THEN 'DEDICATED - Scenario A - Delete by clientId'
        ELSE 'SHARED - Scenario B - Delete by userId only'
    END AS Scenario
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (1, 53, 1096, 1360, 1412, 1449)
GROUP BY c.clientId, c.clientName;

-- ============================================
-- STEP 3: TOKENS CHECK
-- ============================================
SELECT '=== STEP 3: TOKENS CHECK ===' AS '';

SELECT 'clientId 1412 (Test Mash)' AS Scope, COUNT(*) AS token_count
FROM Tokens WHERE clientId = 1412;

SELECT 'Scenario B userIds' AS Scope, COUNT(*) AS token_count
FROM Tokens
WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);

-- ============================================
-- STEP 4: ROW COUNTS - SCENARIO B (shared userIds)
-- Dynamically generates count across all tables with userId column
-- NOTE: userId 5442 excluded pending manager confirmation
-- ============================================
SELECT '=== STEP 4: ROW COUNTS - SCENARIO B ===' AS '';
SELECT CONCAT(
    'SELECT ''', TABLE_NAME, ''' AS TableName, COUNT(*) AS Row_Count FROM `', TABLE_NAME, '` WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894) UNION ALL'
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'UDM__'
AND COLUMN_NAME LIKE '%userId%'
ORDER BY TABLE_NAME ASC;

-- ============================================
-- STEP 5: ROW COUNTS - SCENARIO A (clientId 1412)
-- Dynamically generates count across all tables with clientId column
-- ============================================
SELECT '=== STEP 5: ROW COUNTS - SCENARIO A (clientId 1412) ===' AS '';
SELECT CONCAT(
    'SELECT ''', TABLE_NAME, ''' AS TableName, COUNT(*) AS Row_Count FROM `', TABLE_NAME, '` WHERE clientId = 1412 UNION ALL'
)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'UDM__'
AND COLUMN_NAME LIKE '%clientId%'
ORDER BY TABLE_NAME ASC;
