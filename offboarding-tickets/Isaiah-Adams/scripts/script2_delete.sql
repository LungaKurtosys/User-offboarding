-- ============================================
-- SCRIPT 2: DELETE
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- ============================================
-- IMPORTANT:
-- Clients are SHARED - deleting by userId only
-- Clients 53 and 190 are NOT deleted
-- Children deleted first, parent deleted last
-- ============================================
-- ONLY RUN AFTER PEER REVIEW AND APPROVAL
-- ONLY RUN AFTER SCRIPT 1 BACKUPS VERIFIED
-- ============================================

-- CHILDREN FIRST

-- Step 1: Delete UserRole (child)
DELETE FROM UserRole WHERE userId IN (6274, 5999);
SELECT 'UserRole deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 2: Delete UserApplication (child)
DELETE FROM UserApplication WHERE userId IN (6274, 5999);
SELECT 'UserApplication deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 3: Delete UserConfiguration (child)
DELETE FROM UserConfiguration WHERE userId IN (6274, 5999);
SELECT 'UserConfiguration deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 4: Delete Tokens (child)
DELETE FROM Tokens WHERE userId IN (6274, 5999);
SELECT 'Tokens deleted' as Status, ROW_COUNT() as Rows_Affected;

-- PARENT LAST

-- Step 5: Delete User (parent)
DELETE FROM User WHERE userId IN (6274, 5999);
SELECT 'User deleted' as Status, ROW_COUNT() as Rows_Affected;
