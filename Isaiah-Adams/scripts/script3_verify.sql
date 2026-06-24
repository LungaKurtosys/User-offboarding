-- ============================================
-- SCRIPT 3: VERIFY CLEANUP
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- ============================================

-- STEP 1: Confirm users are gone
SELECT 
    CASE WHEN COUNT(*) = 0 
    THEN 'SUCCESS - Users deleted' 
    ELSE 'FAILED - Users still exist' 
    END as User_Check
FROM User WHERE userId IN (6274, 5999);

-- STEP 2: Confirm roles are gone
SELECT 
    CASE WHEN COUNT(*) = 0 
    THEN 'SUCCESS - UserRoles deleted' 
    ELSE 'FAILED - UserRoles still exist' 
    END as UserRole_Check
FROM UserRole WHERE userId IN (6274, 5999);

-- STEP 3: Confirm applications are gone
SELECT 
    CASE WHEN COUNT(*) = 0 
    THEN 'SUCCESS - UserApplications deleted' 
    ELSE 'FAILED - UserApplications still exist' 
    END as UserApplication_Check
FROM UserApplication WHERE userId IN (6274, 5999);

-- STEP 4: Confirm clients still intact
SELECT 
    c.clientId,
    c.clientName,
    COUNT(u.userId) as remaining_users,
    'Client intact' as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;

-- STEP 5: Confirm cache was updated
SELECT 
    clientId,
    lastModified,
    'Cache Updated' as Cache_Check
FROM WarpdriveCache 
WHERE clientId IN (53, 190);
