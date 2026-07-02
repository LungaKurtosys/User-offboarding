-- ============================================
-- SCRIPT 3: VERIFY CLEANUP
-- Author: Lunga Ndzimande
-- Ticket: Multi-User Offboarding
-- Environment: REL (Release)
-- Replace userIds and clientIds with actual values
-- ============================================

-- STEP 1: Verify all user records are gone (Scenario B)
SELECT 'User' as TableName,
    COUNT(*) as Remaining,
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS' ELSE 'FAILED - Records still exist' END as Status
FROM User WHERE userId IN (<replace_with_userIds>)
UNION ALL
SELECT 'UserRole',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS' ELSE 'FAILED - Records still exist' END
FROM UserRole WHERE userId IN (<replace_with_userIds>)
UNION ALL
SELECT 'UserApplication',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS' ELSE 'FAILED - Records still exist' END
FROM UserApplication WHERE userId IN (<replace_with_userIds>)
UNION ALL
SELECT 'UserConfiguration',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS' ELSE 'FAILED - Records still exist' END
FROM UserConfiguration WHERE userId IN (<replace_with_userIds>)
UNION ALL
SELECT 'Tokens',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS' ELSE 'FAILED - Records still exist' END
FROM Tokens WHERE userId IN (<replace_with_userIds>);

-- STEP 2: Confirm shared clients are still intact (Scenario B only)
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as remaining_users,
    'Client intact - other users unaffected' as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (<replace_with_shared_clientIds>)
GROUP BY c.clientId, c.clientName;

-- STEP 3: Confirm dedicated client is fully gone (Scenario A only)
SELECT
    clientId,
    COUNT(*) as remaining_rows,
    CASE WHEN COUNT(*) = 0 THEN 'SUCCESS - Client fully deleted' ELSE 'FAILED - Records still exist' END as Status
FROM Client
WHERE clientId = <replace_with_dedicated_clientId>;
