-- ============================================
-- SCRIPT 2B: DELETE - SCENARIO B (SHARED CLIENT)
-- Author: Lunga Ndzimande
-- Ticket: Multi-User Offboarding
-- Environment: REL (Release)
-- Use this ONLY for clients confirmed as SHARED (multiple users)
-- Replace userIds below with actual values from script1
-- ONLY RUN AFTER PEER REVIEW AND BACKUPS VERIFIED
-- ============================================

-- CHILDREN FIRST

-- Step 1: Delete UserRole (child)
DELETE FROM UserRole WHERE userId IN (<replace_with_userIds>);
SELECT 'UserRole deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 2: Delete UserApplication (child)
DELETE FROM UserApplication WHERE userId IN (<replace_with_userIds>);
SELECT 'UserApplication deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 3: Delete UserConfiguration (child)
DELETE FROM UserConfiguration WHERE userId IN (<replace_with_userIds>);
SELECT 'UserConfiguration deleted' as Status, ROW_COUNT() as Rows_Affected;

-- Step 4: Delete Tokens (child)
DELETE FROM Tokens WHERE userId IN (<replace_with_userIds>);
SELECT 'Tokens deleted' as Status, ROW_COUNT() as Rows_Affected;

-- PARENT LAST

-- Step 5: Delete User (parent)
DELETE FROM User WHERE userId IN (<replace_with_userIds>);
SELECT 'User deleted' as Status, ROW_COUNT() as Rows_Affected;
