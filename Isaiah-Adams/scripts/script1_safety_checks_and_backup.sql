-- ============================================
-- SCRIPT 1: SAFETY CHECKS & ROW COUNTS
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- NOTE: Clients are SHARED - process by userId only
-- ============================================

-- STEP 1: Confirm Isaiah's user accounts exist
SELECT
    u.userId,
    u.clientId,
    u.userName,
    u.name,
    u.email,
    u.status,
    c.clientName
FROM User u
JOIN Client c ON u.clientId = c.clientId
WHERE
    u.name LIKE '%Isaiah%'
    OR u.email LIKE '%isaiah%'
    OR u.userName LIKE '%isaiah%';

-- STEP 2: Confirm clients are SHARED - critical safety check
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Safe to delete by clientId'
        ELSE 'SHARED - Delete by userId only'
    END as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;

-- STEP 3: Count all rows before deletion (by userId only)
SELECT 'User' as TableName, COUNT(*) as Row_Count
FROM User WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserRole', COUNT(*)
FROM UserRole WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserApplication', COUNT(*)
FROM UserApplication WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserConfiguration', COUNT(*)
FROM UserConfiguration WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'Tokens', COUNT(*)
FROM Tokens WHERE userId IN (6274, 5999);
