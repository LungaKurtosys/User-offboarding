# Isaiah Adams Offboarding - REL Environment Cleanup

## Ticket Details

| Field | Details |
|-------|---------|
| Author | Lunga Ndzimande |
| Date | 2026-06-24 |
| Environment | REL (Release) - Ireland (eu-west-1) |
| Database | SingleStore - UDM__ |
| Account | KurtosysApp_Non-Prod |

## Background

Isaiah Adams has left the organization. This document covers the full investigation, 
identification and cleanup of all user accounts and associated data in the Release (REL) 
environment.

---

## Step 1 - Local Machine Connection Attempt (Failed)

Attempted to connect to the REL environment from local machine.

**Command:**
```bash
ping ew1r-aggr-03.rel.kurtosys-internal.net
```

**Result:**
```
PING ew1r-aggr-03.rel.kurtosys-internal.net (10.77.6.161)
92 bytes from 172.69.107.98: Destination Host Unreachable
Request timeout for icmp_seq 0
```

**Conclusion:** Local machine cannot reach internal Kurtosys network. 
Cloudflare IP `172.69.107.98` is intercepting the traffic instead of routing it 
to the internal network. This confirmed that AWS Session Manager was required 
to access the internal REL environment.

---

## Step 2 - AWS EC2 Console

Navigated to AWS EC2 Console (eu-west-1 Ireland region) to locate the jumpbox instance. 
All instances confirmed running with 3/3 status checks passed.

**Jumpbox used:**
```
ew1r-jump-01.rel.kurtosys-internal.net - 10.77.14.173
```

---

## Step 3 - Connect via AWS Session Manager

Connected to the internal network via AWS Session Manager on the jumpbox instance.

**Why Session Manager was chosen:**
- No open inbound ports required
- No SSH keys required
- Secure encrypted session directly through AWS
- No VPN access needed from local machine
- Session encrypted using AWS KMS

---

## Step 4 - Jumpbox Connectivity Test

Tested connectivity to the REL environment from the jumpbox.

**Command:**
```bash
ping ew1r-aggr-03.rel.kurtosys-internal.net
```

**Result:**
```
PING ew1r-aggr-03.rel.kurtosys-internal.net (10.77.6.161)
64 bytes from 10.77.6.161: icmp_seq=1 ttl=64 time=0.28 ms
64 bytes from 10.77.6.161: icmp_seq=2 ttl=64 time=0.29 ms
```

**Conclusion:** Jumpbox has direct access to the internal Kurtosys network 
with response times of ~0.28ms confirming they are on the same network.

---

## Step 5 - Port Scan to Find SingleStore

Performed a port scan on the aggregator node to identify open ports and confirm 
SingleStore database is accessible.

**Command:**
```bash
nmap -p 1-10000 ew1r-aggr-03.rel.kurtosys-internal.net
```

**Result:**
```
PORT     STATE SERVICE
22/tcp   open  ssh
111/tcp  open  rpcbind
2049/tcp open  nfs
3306/tcp open  mysql
9104/tcp open  jetdirect
```

**Conclusion:** Port 3306 (MySQL/SingleStore) confirmed open on aggr-03. 
Admin node (ew1r-admin-01) was also scanned and only had port 8080 open 
confirming it is not a database connection point.

---

## Step 6 - Connect to SingleStore

Connected to SingleStore database using MySQL client.

**Command:**
```bash
mysql -h ew1r-aggr-03.rel.kurtosys-internal.net -P 3306 -u FundPressSupport -p
```

**Result:**
```
Welcome to the MySQL monitor.
Server version: 5.7.32 SingleStoreDB source distribution
```

**Conclusion:** Successfully connected to SingleStore REL environment 
on ew1r-aggr-03.rel.kurtosys-internal.net port 3306.

---

## Step 7 - Show Databases

Listed all available databases.

**Command:**
```sql
SHOW DATABASES;
```

**Result:**
```
+--------------------+
| Database           |
+--------------------+
| UDM__              |
| information_schema |
+--------------------+
```

**Conclusion:** Two databases found:
- `UDM__` - Main application database containing all client and user data
- `information_schema` - System database containing metadata only (not relevant to this ticket)

---

## Step 8 - Select Database and Show Tables

Selected UDM__ database and listed all tables.

**Command:**
```sql
USE UDM__;
SHOW TABLES;
```

**Result:** 249 tables found in UDM__ database.

**Key tables identified for this investigation:**
- `User` - Contains all user accounts
- `Client` - Contains all client records
- `UserRole` - Contains user role assignments
- `UserApplication` - Contains user application assignments
- `UserConfiguration` - Contains user configuration data
- `WarpdriveCache` - Cache table to be updated after deletion

---

## Step 9 - User Table Structure

Examined the structure of the User table to identify columns for searching.

**Command:**
```sql
DESCRIBE User;
```

**Key columns identified:**

| Column | Purpose |
|--------|---------|
| userId | Unique identifier for each user |
| clientId | Links user to a client |
| userName | Username used to login |
| name | Full name of the user |
| email | Email address of the user |
| status | Account status (Active/Deactivated) |

---

## Step 10 - Client Table Structure

Examined the structure of the Client table.

**Command:**
```sql
DESCRIBE Client;
```

**Key columns identified:**

| Column | Purpose |
|--------|---------|
| clientId | Unique identifier for each client |
| clientName | Name of the client |

---

## Step 11 - Search for Isaiah Adams

Searched for Isaiah Adams across all key columns without knowing the user ID upfront.

**Command:**
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
    OR u.name LIKE '%Adams%'
    OR u.email LIKE '%isaiah%' 
    OR u.email LIKE '%adams%'
    OR u.userName LIKE '%isaiah%' 
    OR u.userName LIKE '%adams%';
```

**Result:**
```
+--------+----------+------------------------------+-----------------+------------------------------+-------------+-------------------------+
| userId | clientId | userName                     | name            | email                        | status      | clientName              |
+--------+----------+------------------------------+-----------------+------------------------------+-------------+-------------------------+
|   6274 |       53 | isaiah.adams@kurtosys.com    | isaiah.adams    | isaiah.adams@kurtosys.com    | Deactivated | Kurtovest Demo          |
|   3507 |       79 | Shaunette.Adams@kurtosys.com | Shaunette Adams | Shaunette.Adams@kurtosys.com | Deactivated | BMO GAM Development     |
|   5999 |      190 | isaiah.adams@kurtosys.com    | Isaiah Adams    | isaiah.adams@kurtosys.com    | Deactivated | Kapital Reporting       |
|   3219 |     1029 | shaunette.adams@kurtosys.com |                 | shaunette.adams@kurtosys.com | Deactivated | M&G Limited Development |
+--------+----------+------------------------------+-----------------+------------------------------+-------------+-------------------------+
```

**Conclusion:** 4 results returned. Filtered to only Isaiah Adams accounts:

| userId | clientId | clientName | Status |
|--------|----------|------------|--------|
| 6274 | 53 | Kurtovest Demo | Deactivated |
| 5999 | 190 | Kapital Reporting | Deactivated |

Shaunette Adams (userId 3507 and 3219) excluded as she is a different person.

---

## Step 12 - Confirm Client Names

Confirmed client names associated with Isaiah Adams.

**Command:**
```sql
SELECT clientId, clientName 
FROM Client 
WHERE clientId IN (53, 190);
```

**Result:**
```
+----------+-------------------+
| clientId | clientName        |
+----------+-------------------+
|       53 | Kurtovest Demo    |
|      190 | Kapital Reporting |
+----------+-------------------+
```

---

## Step 13 - Safety Check (Clients are Shared)

Verified both clients are shared with other users before proceeding.

**Command:**
```sql
SELECT 
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    'Client is SHARED - DO NOT DELETE' as Safety_Note
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
```

**Result:**
```
+----------+-------------------+-------------+----------------------------------+
| clientId | clientName        | total_users | Safety_Note                      |
+----------+-------------------+-------------+----------------------------------+
|       53 | Kurtovest Demo    |         669 | Client is SHARED - DO NOT DELETE |
|      190 | Kapital Reporting |          57 | Client is SHARED - DO NOT DELETE |
+----------+-------------------+-------------+----------------------------------+
```

**Conclusion:**
- Kurtovest Demo has 669 other users - client NOT to be deleted
- Kapital Reporting has 57 other users - client NOT to be deleted
- Only Isaiah Adams user accounts to be removed

---

## Step 14 - Row Count Before Deletion

Counted all records associated with Isaiah Adams before deletion.

**Command:**
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
FROM UserConfiguration WHERE userId IN (6274, 5999);
```

**Result:**
```
+-------------------+-----------+
| TableName         | Row_Count |
+-------------------+-----------+
| User              |         2 |
| UserRole          |         7 |
| UserApplication   |         2 |
| UserConfiguration |         0 |
+-------------------+-----------+
```

**Total: 11 records to be deleted across 3 tables.**

---

## Step 15 - Check UserRole Details

Retrieved all role assignments for Isaiah Adams.

**Command:**
```sql
SELECT * FROM UserRole WHERE userId IN (6274, 5999);
```

**Result:**
```
+--------+--------+
| userId | roleId |
+--------+--------+
|   5999 |      2 |
|   5999 |      4 |
|   5999 |   1776 |
|   6274 |     36 |
|   6274 |     37 |
|   6274 |   1072 |
|   6274 |   1804 |
+--------+--------+
```

---

## Step 16 - Check UserApplication Details

Retrieved all application assignments for Isaiah Adams.

**Command:**
```sql
SELECT * FROM UserApplication WHERE userId IN (6274, 5999);
```

**Result:**
```
+--------+-----------------+-----------+
| userId | applicationCode | isDefault |
+--------+-----------------+-----------+
|   6274 | kurtosysapp     |         1 |
|   5999 | kurtosysapp     |         1 |
+--------+-----------------+-----------+
```

---

## Full Summary of Findings

| Field | Details |
|-------|---------|
| Environment | REL - Ireland (eu-west-1) |
| Database | SingleStore - UDM__ |
| Connection Method | AWS Session Manager - Jumpbox - ew1r-aggr-03:3306 |
| Users Found | 2 accounts |
| Status | Both Deactivated |

**Users to be deleted:**

| userId | clientId | clientName | userName | Status |
|--------|----------|------------|----------|--------|
| 6274 | 53 | Kurtovest Demo | isaiah.adams@kurtosys.com | Deactivated |
| 5999 | 190 | Kapital Reporting | isaiah.adams@kurtosys.com | Deactivated |

**Records to be deleted:**

| Table | Records |
|-------|---------|
| User | 2 |
| UserRole | 7 |
| UserApplication | 2 |
| UserConfiguration | 0 |
| Total | 11 |

**Safety checks:**
- Kurtovest Demo has 669 other users - client NOT deleted
- Kapital Reporting has 57 other users - client NOT deleted
- Only Isaiah's user accounts to be removed
- Backups created before deletion

---

## Scripts

| Script | File | Purpose |
|--------|------|---------|
| Script 1 | script1_safety_checks_and_backup.sql | Safety checks and row counts |
| Backup | script1_backup.sh | mysqldump backups |
| Script 2 | script2_delete.sql | Delete records and update cache |
| Script 3 | script3_verify.sql | Verify cleanup successful |

---

## Script 1 - Safety Checks and Backup

This script must be run first before any deletion. It confirms the correct users
have been identified, verifies clients are shared and counts all records.

```sql
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
```

**Backup commands - run from jumpbox terminal:**

```bash
# Create backup folder
mkdir /tmp/Isaiah-Offboarding
cd /tmp/Isaiah-Offboarding

# Backup User table
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--where="userId IN (6274, 5999)" \
UDM__ User > User_Isaiah_2026-06-24.sql

# Backup UserRole table
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--where="userId IN (6274, 5999)" \
UDM__ UserRole > UserRole_Isaiah_2026-06-24.sql

# Backup UserApplication table
mysqldump -h ew1r-aggr-03.rel.kurtosys-internal.net \
-u FundPressSupport -p --hex-blob --no-create-info \
--where="userId IN (6274, 5999)" \
UDM__ UserApplication > UserApplication_Isaiah_2026-06-24.sql

# Verify backup files were created
ls -lh /tmp/Isaiah-Offboarding/
```

**Expected backup output:**
```
-rw-r--r-- 1 root root  xxK Jun 24 User_Isaiah_2026-06-24.sql
-rw-r--r-- 1 root root  xxK Jun 24 UserRole_Isaiah_2026-06-24.sql
-rw-r--r-- 1 root root  xxK Jun 24 UserApplication_Isaiah_2026-06-24.sql
```

---

## Script 2 - Delete

This script must only be run after peer review and approval and after Script 1
backups have been verified. Deletes child tables first then parent table last.

```sql
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
```

**Expected output after deletion:**
```
+-------------------------+---------------+
| Status                  | Rows_Affected |
+-------------------------+---------------+
| UserRole deleted        |             7 |
| UserApplication deleted |             2 |
| UserConfiguration deleted|            0 |
| User deleted            |             2 |
| WarpdriveCache updated  |             2 |
+-------------------------+---------------+
```

---

## Script 3 - Verify Cleanup

This script must be run after Script 2 to confirm all records have been
successfully deleted and clients remain intact.

```sql
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
```

**Expected output after verification:**
```
+-----------------------------------+
| User_Check                        |
+-----------------------------------+
| SUCCESS - Users deleted           |
+-----------------------------------+

+-----------------------------------+
| UserRole_Check                    |
+-----------------------------------+
| SUCCESS - UserRoles deleted       |
+-----------------------------------+

+-------------------------------------------+
| UserApplication_Check                     |
+-------------------------------------------+
| SUCCESS - UserApplications deleted        |
+-------------------------------------------+

+----------+-------------------+-----------------+---------------+
| clientId | clientName        | remaining_users | Safety_Check  |
+----------+-------------------+-----------------+---------------+
|       53 | Kurtovest Demo    |             668 | Client intact |
|      190 | Kapital Reporting |              56 | Client intact |
+----------+-------------------+-----------------+---------------+
```

---

## Actions Taken

| Action | Status |
|--------|--------|
| Investigation completed | Done |
| Safety checks completed | Done |
| Backups created | Pending |
| Peer review and approval | Pending |
| Deletion of 11 records | Pending |
| WarpdriveCache update | Pending |
| Verification | Pending |
| Ticket closure | Pending |
