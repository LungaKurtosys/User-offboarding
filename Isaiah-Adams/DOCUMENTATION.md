# Isaiah Adams Offboarding - REL Environment Cleanup

**Author:** Lunga Ndzimande
**Date:** 2026-06-24
**Environment:** REL (Release) - Ireland (eu-west-1)
**Database:** SingleStore - UDM__
**Account:** KurtosysApp_Non-Prod

---

## Background

Isaiah Adams has left the organization. This ticket covers the full investigation,
identification, backup, cleanup and verification of all user accounts and associated
data in the Release (REL) environment following the Kurtosys standard offboarding process.

---

## Understanding the Database — KAPP Architecture

UDM__ is a **KAPP database**. This is critical to understand before doing any offboarding work.

```
One database (UDM__) holds data for MANY different clients.
Every table has a clientId column that separates one client's data from another.
NEVER delete data belonging to another client.
```

Example of how data is separated in the User table:

```
userId | clientId | userName
-------+----------+---------------------------
6274   |    53    | isaiah.adams@kurtosys.com   ← Kurtovest Demo tenant
5999   |   190    | isaiah.adams@kurtosys.com   ← Kapital Reporting tenant
1001   |    53    | john.smith@kurtosys.com     ← also Kurtovest Demo tenant
2002   |  1447    | another.user@kurtosys.com   ← completely different tenant
```

---

## Two Offboarding Scenarios — Which One Applies?

Before doing anything, you must identify which scenario applies:

### Scenario A — Dedicated Client
```
Client belongs to ONE user only
→ Delete EVERYTHING linked to clientId across ALL 160+ tables
→ Use INFORMATION_SCHEMA to auto-generate all scripts
→ Client record is also deleted
→ Example: a training or demo client created for one person only
```

### Scenario B — Shared Client
```
Client is shared with many other users
→ Delete by userId ONLY
→ Only 5 tables involved
→ Client record stays intact — other users depend on it
→ Example: a real client environment used by many team members
```

**The decision query — always run this first:**

```sql
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Scenario A applies'
        ELSE 'SHARED - Scenario B applies'
    END as Scenario
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (<clientIds>)
GROUP BY c.clientId, c.clientName;
```

---

## Parent and Child Tables — Deletion Order

This is a fundamental database concept that must always be followed:

```
Parent table  = User (the main record)
Child tables  = UserRole, UserApplication, UserConfiguration, Tokens
               (these all reference the userId)

CORRECT order:
Step 1: Delete children first (UserRole, UserApplication, UserConfiguration, Tokens)
Step 2: Delete parent last (User)

WHY?
If you delete User (parent) first, the child records still exist
but they are pointing to a userId that no longer exists.
These are called ORPHANED RECORDS and they break data integrity.
```

---

## What Was Wrong In My Initial Approach vs The Correct Approach

| | My Initial Wrong Approach | Correct Approach |
|--|--------------------------|-----------------|
| Starting point | Searched by name only | Confirm clientId first, then check shared vs dedicated |
| Client type check | Checked but did not use result to decide process | Use result to decide Scenario A or Scenario B |
| Tables covered | 4 tables only (missed Tokens) | 5 tables for shared client |
| Tokens table | Not included | Must be included — tokens are linked to userId |
| Parent/child order | Not clearly defined | Children first, parent last — always |
| Scripts for dedicated client | Would have been manual | Should use INFORMATION_SCHEMA to auto-generate |
| Risk | Could leave orphaned records or miss data | Clean, complete, safe deletion |

---

## Why This Ticket Uses Scenario B (Shared Client)

Isaiah Adams has accounts under two clients:

| userId | clientId | clientName |
|--------|----------|------------|
| 6274 | 53 | Kurtovest Demo |
| 5999 | 190 | Kapital Reporting |

After running the decision query:

```
Kurtovest Demo    → 669 users → SHARED → Scenario B
Kapital Reporting → 57 users  → SHARED → Scenario B
```

This means:
- Cannot delete by clientId — would wipe 669 and 57 other users data
- Must delete by userId 6274 and 5999 only
- Client records 53 and 190 stay intact

---

## Connection Method

**Step 1 — Local machine attempt (fails):**
```bash
ping ew1r-aggr-03.rel.kurtosys-internal.net
```

Result:
```
92 bytes from 172.69.107.98: Destination Host Unreachable
```

Cloudflare intercepts traffic. Local machine cannot reach internal Kurtosys network.

**Step 2 — AWS EC2 Console:**
- Navigate to AWS Console → EC2 → eu-west-1 Ireland
- Locate jumpbox: `ew1r-jump-01.rel.kurtosys-internal.net - 10.77.14.173`
- Confirm all instances running with 3/3 status checks passed

**Step 3 — Connect via AWS Session Manager:**

Why Session Manager:
- No open inbound ports required
- No SSH keys required
- Secure encrypted session through AWS KMS
- No VPN needed from local machine

**Step 4 — Test connectivity from jumpbox:**
```bash
ping ew1r-aggr-03.rel.kurtosys-internal.net
```

Result:
```
64 bytes from 10.77.6.161: icmp_seq=1 ttl=64 time=0.28 ms
64 bytes from 10.77.6.161: icmp_seq=2 ttl=64 time=0.29 ms
```

Jumpbox has direct access. ~0.28ms confirms same network.

**Step 5 — Connect to database:**
```bash
mysql -h ew1r-aggr-03.rel.kurtosys-internal.net -P 3306 -u FundPressSupport -p
```

```sql
USE UDM__;
```

---

## Step 1 — Identify Isaiah Adams Accounts

```sql
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
```

Result:
```
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
| userId | clientId | userName                  | name         | email                     | status      | clientName        |
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
|   6274 |       53 | isaiah.adams@kurtosys.com | isaiah.adams | isaiah.adams@kurtosys.com | Deactivated | Kurtovest Demo    |
|   5999 |      190 | isaiah.adams@kurtosys.com | Isaiah Adams | isaiah.adams@kurtosys.com | Deactivated | Kapital Reporting |
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
```

Isaiah Adams accounts identified:

| userId | clientId | clientName | Status |
|--------|----------|------------|--------|
| 6274 | 53 | Kurtovest Demo | Deactivated |
| 5999 | 190 | Kapital Reporting | Deactivated |

---

## Step 2 — Safety Check (Shared vs Dedicated)

```sql
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Scenario A - Delete by clientId'
        ELSE 'SHARED - Scenario B - Delete by userId only'
    END as Scenario
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
```

Result:
```
+----------+-------------------+-------------+---------------------------------------------+
| clientId | clientName        | total_users | Scenario                                    |
+----------+-------------------+-------------+---------------------------------------------+
|       53 | Kurtovest Demo    |         669 | SHARED - Scenario B - Delete by userId only |
|      190 | Kapital Reporting |          57 | SHARED - Scenario B - Delete by userId only |
+----------+-------------------+-------------+---------------------------------------------+
```

Conclusion:
- Both clients are SHARED → Scenario B applies
- Delete by userId 6274 and 5999 only
- Client records 53 and 190 must NOT be deleted

---

## Step 3 — Row Counts Before Deletion

```sql
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
```

Result:
```
+-------------------+-----------+
| TableName         | Row_Count |
+-------------------+-----------+
| User              |         2 |
| UserRole          |         7 |
| UserApplication   |         2 |
| UserConfiguration |         0 |
| Tokens            |         0 |
+-------------------+-----------+
Total: 11 records to be deleted
```

---

## Step 4 — Backup Scripts

Run from jumpbox terminal BEFORE any deletion:

```bash
# Create backup folder
mkdir /tmp/Isaiah-Adams-Offboarding
cd /tmp/Isaiah-Adams-Offboarding

# Backup User
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="userId IN (6274, 5999)" \
UDM__ User > User_2026-06-24.sql

# Backup UserRole
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="userId IN (6274, 5999)" \
UDM__ UserRole > UserRole_2026-06-24.sql

# Backup UserApplication
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="userId IN (6274, 5999)" \
UDM__ UserApplication > UserApplication_2026-06-24.sql

# Backup UserConfiguration
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="userId IN (6274, 5999)" \
UDM__ UserConfiguration > UserConfiguration_2026-06-24.sql

# Backup Tokens
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="userId IN (6274, 5999)" \
UDM__ Tokens > Tokens_2026-06-24.sql

# Verify backups created
ls -lh /tmp/Isaiah-Adams-Offboarding/
```

Expected output:
```
-rw-r--r-- 1 root root xxK Jun 24 User_2026-06-24.sql
-rw-r--r-- 1 root root xxK Jun 24 UserRole_2026-06-24.sql
-rw-r--r-- 1 root root xxK Jun 24 UserApplication_2026-06-24.sql
-rw-r--r-- 1 root root xxK Jun 24 UserConfiguration_2026-06-24.sql
-rw-r--r-- 1 root root xxK Jun 24 Tokens_2026-06-24.sql
```

---

## Step 5 — Peer Review and Approval

```
STOP — Do not proceed until approved by:
→ Yogeshwar Phull
→ Tashvir Babulal

Share with reviewer:
1. Safety check results — clients are SHARED
2. Row counts from Step 3
3. Confirmation backups were created from Step 4
```

---

## Step 6 — Delete Scripts

**ONLY run after peer review approval and backups verified.**

```sql
-- ============================================
-- SCRIPT 2: DELETE
-- Author: Lunga Ndzimande
-- Ticket: Isaiah Adams Offboarding
-- Environment: REL (Release)
-- Date: 2026-06-24
-- IMPORTANT: Clients are SHARED
--            Deleting by userId ONLY
--            Clients 53 and 190 are NOT deleted
--            Children deleted first, parent deleted last
-- ONLY RUN AFTER PEER REVIEW AND APPROVAL
-- ONLY RUN AFTER BACKUPS VERIFIED
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
```

Expected output:
```
+--------------------------+---------------+
| Status                   | Rows_Affected |
+--------------------------+---------------+
| UserRole deleted         |             7 |
| UserApplication deleted  |             2 |
| UserConfiguration deleted|             0 |
| Tokens deleted           |             0 |
| User deleted             |             2 |
+--------------------------+---------------+
```

---

## Step 7 — Verify Cleanup

```sql
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

-- STEP 6: Confirm shared clients still intact
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as remaining_users,
    'Client intact - other users unaffected' as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
```

Expected output:
```
+---------------------------+
| User_Check                |
+---------------------------+
| SUCCESS - Users deleted   |

+-----------------------------------+
| UserRole_Check                    |
+-----------------------------------+
| SUCCESS - UserRoles deleted       |

+-------------------------------------------+
| UserApplication_Check                     |
+-------------------------------------------+
| SUCCESS - UserApplications deleted        |

+-------------------------------------------+
| UserConfiguration_Check                   |
+-------------------------------------------+
| SUCCESS - UserConfigurations deleted      |

+---------------------------+
| Tokens_Check              |
+---------------------------+
| SUCCESS - Tokens deleted  |

+----------+-------------------+-----------------+----------------------------------------+
| clientId | clientName        | remaining_users | Safety_Check                           |
+----------+-------------------+-----------------+----------------------------------------+
|       53 | Kurtovest Demo    |             668 | Client intact - other users unaffected |
|      190 | Kapital Reporting |              56 | Client intact - other users unaffected |
+----------+-------------------+-----------------+----------------------------------------+
```

---

## Full Summary

| Field | Details |
|-------|---------|
| Environment | REL - Ireland (eu-west-1) |
| Database | SingleStore - UDM__ |
| Connection | AWS Session Manager via jumpbox ew1r-aggr-03:3306 |
| Users Found | 2 accounts |
| Status | Both Deactivated |
| Client Type | SHARED — Scenario B applied |
| Deleted by | userId only |

**Records deleted:**

| Table | Before | After |
|-------|--------|-------|
| User | 2 | 0 |
| UserRole | 7 | 0 |
| UserApplication | 2 | 0 |
| UserConfiguration | 0 | 0 |
| Tokens | 0 | 0 |
| Total | 11 | 0 |

**Clients remain intact:**

| clientId | clientName | Users Before | Users After |
|----------|------------|-------------|-------------|
| 53 | Kurtovest Demo | 669 | 668 |
| 190 | Kapital Reporting | 57 | 56 |

---

## Actions Taken

| Action | Status |
|--------|--------|
| Connection via AWS Session Manager | Done ✅ |
| Isaiah's accounts identified | Done ✅ |
| Clients confirmed as SHARED | Done ✅ |
| Row counts recorded | Done ✅ |
| Backups created | Pending ⏳ |
| Peer review and approval | Pending ⏳ |
| Delete scripts run | Pending ⏳ |
| Verification — all counts zero | Pending ⏳ |
| Ticket closure | Pending ⏳ |

---

## Summary — What I Learned and What I Fixed

### What I Learned

**1. UDM__ is a KAPP Database**
```
Before: I did not fully consider that one database holds many clients
After:  I now understand that every table has a clientId column
        separating one client's data from another
        NEVER delete by clientId if other users share that client
```

**2. Always Check Shared vs Dedicated Client First**
```
Before: I jumped straight into searching for the user and deleting
After:  I now always run the safety check first:

        SELECT clientId, clientName, COUNT(userId) as total_users
        FROM Client c JOIN User u ON c.clientId = u.clientId
        WHERE c.clientId IN (53, 190)
        GROUP BY c.clientId, c.clientName;

        Result told me:
        Kurtovest Demo    = 669 users → SHARED → delete by userId only
        Kapital Reporting = 57 users  → SHARED → delete by userId only
```

**3. Two Scenarios Exist — I Was Using the Wrong One**
```
Before: I treated this like a dedicated client ticket
        and only deleted from 4 tables

After:  I now understand there are two scenarios:

        Scenario A — Dedicated client (1 user only)
        → Delete everything by clientId across ALL 160+ tables
        → Use INFORMATION_SCHEMA to auto-generate all scripts
        → Client record is also deleted

        Scenario B — Shared client (many users)
        → Delete by userId ONLY
        → Only 5 tables involved
        → Client record stays intact
        → Isaiah Adams falls under Scenario B
```

**4. Parent and Child Table Relationship**
```
Before: I did not clearly understand or follow parent/child deletion order

After:  I now understand:
        Parent  = User table (the main record)
        Children = UserRole, UserApplication, UserConfiguration, Tokens
                  (these all reference the userId)

        If you delete the parent (User) first:
        → Children still exist but point to a userId that no longer exists
        → These are called ORPHANED RECORDS
        → This breaks data integrity

        Correct order:
        Step 1: Delete children first
        Step 2: Delete parent last
```

**5. The Tokens Table Was Completely Missing**
```
Before: My scripts only covered:
        - User
        - UserRole
        - UserApplication
        - UserConfiguration

After:  I now include Tokens as well:
        - UserRole          (child)
        - UserApplication   (child)
        - UserConfiguration (child)
        - Tokens            (child)
        - User              (parent — last)

        Tokens are linked to userId not clientId
        They must always be backed up and deleted by userId
```

---

### What I Fixed in My Scripts

**Fix 1 — Added the safety check query at the start**

Wrong (what I had before):
```sql
-- Jumped straight to searching by name
SELECT * FROM User WHERE name LIKE '%Isaiah%';
```

Fixed (what it is now):
```sql
-- First confirm if client is shared or dedicated
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Scenario A - Delete by clientId'
        ELSE 'SHARED - Scenario B - Delete by userId only'
    END as Scenario
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
```

**Fix 2 — Added Tokens to row counts**

Wrong (what I had before):
```sql
SELECT 'User' as TableName, COUNT(*) FROM User WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserRole', COUNT(*) FROM UserRole WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserApplication', COUNT(*) FROM UserApplication WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserConfiguration', COUNT(*) FROM UserConfiguration WHERE userId IN (6274, 5999);
-- Tokens was MISSING
```

Fixed (what it is now):
```sql
SELECT 'User' as TableName, COUNT(*) FROM User WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserRole', COUNT(*) FROM UserRole WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserApplication', COUNT(*) FROM UserApplication WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'UserConfiguration', COUNT(*) FROM UserConfiguration WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'Tokens', COUNT(*) FROM Tokens WHERE userId IN (6274, 5999);
-- Tokens NOW INCLUDED
```

**Fix 3 — Added Tokens to backup scripts**

Wrong (what I had before):
```bash
# Only backed up 3 tables
mysqldump ... UDM__ User > User_2026-06-24.sql
mysqldump ... UDM__ UserRole > UserRole_2026-06-24.sql
mysqldump ... UDM__ UserApplication > UserApplication_2026-06-24.sql
# UserConfiguration and Tokens were MISSING
```

Fixed (what it is now):
```bash
# All 5 tables backed up
mysqldump ... UDM__ User > User_2026-06-24.sql
mysqldump ... UDM__ UserRole > UserRole_2026-06-24.sql
mysqldump ... UDM__ UserApplication > UserApplication_2026-06-24.sql
mysqldump ... UDM__ UserConfiguration > UserConfiguration_2026-06-24.sql
mysqldump ... UDM__ Tokens > Tokens_2026-06-24.sql
```

**Fix 4 — Fixed delete script order (children first, parent last)**

Wrong (what I had before):
```sql
-- Order was not clearly defined
DELETE FROM UserRole WHERE userId IN (6274, 5999);
DELETE FROM UserApplication WHERE userId IN (6274, 5999);
DELETE FROM UserConfiguration WHERE userId IN (6274, 5999);
DELETE FROM User WHERE userId IN (6274, 5999);
-- Tokens was MISSING
-- WarpdriveCache update was added incorrectly
--   (not needed for shared client — only relevant for dedicated client)
```

Fixed (what it is now):
```sql
-- CHILDREN FIRST
DELETE FROM UserRole WHERE userId IN (6274, 5999);
DELETE FROM UserApplication WHERE userId IN (6274, 5999);
DELETE FROM UserConfiguration WHERE userId IN (6274, 5999);
DELETE FROM Tokens WHERE userId IN (6274, 5999);  -- NOW INCLUDED

-- PARENT LAST
DELETE FROM User WHERE userId IN (6274, 5999);
-- WarpdriveCache update REMOVED — not applicable for shared client
```

**Fix 5 — Added Tokens to verify script**

Wrong (what I had before):
```sql
-- Only verified 4 tables
-- No Tokens check
-- WarpdriveCache check was incorrectly included
```

Fixed (what it is now):
```sql
-- Verifies all 5 tables
-- Tokens check NOW INCLUDED
-- Confirms shared clients still intact with remaining users
-- WarpdriveCache check REMOVED — not applicable for shared client
```
