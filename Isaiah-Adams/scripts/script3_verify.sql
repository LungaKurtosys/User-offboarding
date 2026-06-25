-- ============================================
-- SCRIPT 3: VERIFY CLEANUP
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- ============================================

-- STEP 1: Confirm User records are gone
SELECT
    CASE WHEN COUNT(*) = 0
    THEN 'SUCCESS - Users deleted'
    ELSE 'FAILED - Users still exist'
    END as User_Check
FROM User WHERE userId IN (6274, 5999);

-- STEP 2: Confirm UserRole records are gone
SELECT
    CASE WHEN COUNT(*) = 0
    THEN 'SUCCESS - UserRoles deleted'
    ELSE 'FAILED - UserRoles still exist'
    END as UserRole_Check
FROM UserRole WHERE userId IN (6274, 5999);

-- STEP 3: Confirm UserApplication records are gone
SELECT
    CASE WHEN COUNT(*) = 0
    THEN 'SUCCESS - UserApplications deleted'
    ELSE 'FAILED - UserApplications still exist'
    END as UserApplication_Check
FROM UserApplication WHERE userId IN (6274, 5999);

-- STEP 4: Confirm UserConfiguration records are gone
SELECT
    CASE WHEN COUNT(*) = 0
    THEN 'SUCCESS - UserConfigurations deleted'
    ELSE 'FAILED - UserConfigurations still exist'
    END as UserConfiguration_Check
FROM UserConfiguration WHERE userId IN (6274, 5999);

-- STEP 5: Confirm Tokens are gone
SELECT
    CASE WHEN COUNT(*) = 0
    THEN 'SUCCESS - Tokens deleted'
    ELSE 'FAILED - Tokens still exist'
    END as Tokens_Check
FROM Tokens WHERE userId IN (6274, 5999);

-- STEP 6: Confirm shared clients still intact with remaining users
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as remaining_users,
    'Client intact - other users unaffected' as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
