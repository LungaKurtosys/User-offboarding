-- ============================================
-- SCRIPT 1: SAFETY CHECKS & BACKUP
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- ============================================

-- STEP 1: Confirm users exist
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
    OR u.name LIKE '%Adams%'
    OR u.email LIKE '%isaiah%' 
    OR u.email LIKE '%adams%'
    OR u.userName LIKE '%isaiah%' 
    OR u.userName LIKE '%adams%';

-- STEP 2: Confirm clients are SHARED
SELECT 
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    'Client is SHARED - DO NOT DELETE' as Safety_Note
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;

-- STEP 3: Count rows before deletion
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
FROM UserConfiguration WHERE userId IN (6274, 5999);
