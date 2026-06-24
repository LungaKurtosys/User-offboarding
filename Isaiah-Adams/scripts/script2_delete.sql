-- ============================================
-- SCRIPT 2: DELETE
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- ONLY RUN AFTER PEER REVIEW AND APPROVAL
-- ONLY RUN AFTER SCRIPT 1 BACKUP VERIFIED
-- ============================================

-- STEP 1: Delete child tables first
DELETE FROM UserRole WHERE userId IN (6274, 5999);
SELECT 'UserRole deleted' as Status, ROW_COUNT() as Rows_Affected;

DELETE FROM UserApplication WHERE userId IN (6274, 5999);
SELECT 'UserApplication deleted' as Status, ROW_COUNT() as Rows_Affected;

DELETE FROM UserConfiguration WHERE userId IN (6274, 5999);
SELECT 'UserConfiguration deleted' as Status, ROW_COUNT() as Rows_Affected;

-- STEP 2: Delete parent table last
DELETE FROM User WHERE userId IN (6274, 5999);
SELECT 'User deleted' as Status, ROW_COUNT() as Rows_Affected;

-- STEP 3: Update Cache
SELECT * FROM WarpdriveCache WHERE clientId IN (53, 190);
UPDATE WarpdriveCache SET lastModified = NOW() WHERE clientId IN (53, 190);
SELECT 'WarpdriveCache updated' as Status, ROW_COUNT() as Rows_Affected;
