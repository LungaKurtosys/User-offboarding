# Multi-User Offboarding - REL Environment

**Author:** Lunga Ndzimande
**Date:** 2026-07-01
**Environment:** REL (Release) - Ireland (eu-west-1)
**Database:** SingleStore - UDM__
**Account:** KurtosysApp_Non-Prod
**Connection:** AWS Session Manager → Jumpbox (ew1r-jump-01) → DB (ew1r-aggr-03)

---

## Background

Six users have left the organization. This ticket covers the full investigation,
identification, backup, cleanup and verification of all user accounts and associated
data in the Release (REL) environment.

**Users to Offboard:**

| User | In REL? | Confirmed By |
|------|---------|--------------|
| Mashaole Mogale | ✅ Yes | Found in DB |
| Zelda Miller | ✅ Yes | Found in DB |
| Divashan Naicker | ✅ Yes | Found in DB |
| Maahir Petersen | ❌ No | Confirmed by Rayhaan |
| Anneliese Thomas | ❌ No | Confirmed by Rayhaan |
| Richard Fitzmaurice | ❌ No | Confirmed by Rayhaan |

---

## Connection Method

```
Local Mac → Cloudflare (blocks direct DB access)
         → AWS Console → EC2 → eu-west-1
         → Session Manager → ew1r-jump-01.rel.kurtosys-internal.net
         → mysql -h ew1r-aggr-03.rel.kurtosys-internal.net -u CSE -p UDM__
```

Note: Cannot SCP files or access S3 from jumpbox. Files created using `cat > file << 'EOF'` method.

---

## Step 1 — User and Client Discovery

Search queries used to find all accounts:

```sql
SELECT u.userId, u.clientId, u.userName, u.name, u.email, u.status, c.clientName
FROM User u JOIN Client c ON u.clientId = c.clientId
WHERE u.name LIKE '%Mashaole%' OR u.email LIKE '%mashaole%'
OR u.name LIKE '%Zelda%' OR u.email LIKE '%zelda%'
OR u.name LIKE '%Divashan%' OR u.email LIKE '%divashan%';
```

**Full User/Client Map Confirmed:**

| userId | clientId | clientName | userName | User |
|--------|----------|------------|----------|------|
| 2894 | 1096 | k102.zelda | WordPress Editor | Zelda Miller |
| 2894 | 1412 | Test Mash | WordPress Editor | Mashaole Mogale (also userId 2894 on clientId 1) |
| 5442 | 1 | Kurtosys | mashaole.mogale | Mashaole Mogale — ⚠️ PENDING manager confirmation |
| 5553 | 1360 | SFI QA | mashaole.mogale | Mashaole Mogale |
| 5554 | 53 | Kurtovest Demo | mashaole.mogale | Mashaole Mogale |
| 5814 | 1449 | Training Divashan Naicker | training_divashan_api_user | Divashan Naicker |
| 5819 | 1449 | Training Divashan Naicker | divashan.naicker | Divashan Naicker |
| 6114 | 53 | Kurtovest Demo | zelda.miller | Zelda Miller |
| 6183 | 1360 | SFI QA | zelda.miller | Zelda Miller |

---

## Step 2 — Scenario Classification

```sql
SELECT c.clientId, c.clientName, COUNT(u.userId) AS total_users,
    CASE WHEN COUNT(u.userId) = 1 THEN 'DEDICATED - Scenario A'
         ELSE 'SHARED - Scenario B'
    END AS Scenario
FROM Client c JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (1, 53, 1096, 1360, 1412, 1449)
GROUP BY c.clientId, c.clientName;
```

**Results:**

| clientId | clientName | total_users | Scenario |
|----------|------------|-------------|----------|
| 1 | Kurtosys | 149 | SHARED - Scenario B |
| 53 | Kurtovest Demo | 670 | SHARED - Scenario B |
| 1096 | k102.zelda | 2 | SHARED - Scenario B |
| 1360 | SFI QA | 77 | SHARED - Scenario B |
| 1412 | Test Mash | 1 | DEDICATED - Scenario A |
| 1449 | Training Divashan Naicker | 4 | SHARED - Scenario B |

**clientId 1096 investigation:**
```
userId 2883 — zelda — alauddin.tajoodien@kurtosys.com — NOT Zelda Miller
userId 2894 — WordPress Editor — zelda.miller@kurtosys.com — IS Zelda Miller
→ Scenario B: delete userId 2894 only, client stays
```

**clientId 1449 investigation:**
```
userId 5814 — training_divashan_api_user — Divashan ✅
userId 5819 — divashan.naicker — Divashan ✅
userId 5821 — ryan.bunn@kurtosys.com — DO NOT TOUCH
userId 5823 — derrick.rheeder@kurtosys.com — DO NOT TOUCH
→ Scenario B: delete userId 5814 and 5819 only
→ Client cannot be deleted — Ryan Bunn and Derrick Rheeder are still active
→ Documented: clientId 1449 named 'Training Divashan Naicker' but shared with
  other active users. Client record stays. Only Divashan's userIds deleted.
```

---

## Scenario Summary

### Scenario A — Dedicated Client (delete everything by clientId)

| clientId | clientName | Action |
|----------|------------|--------|
| 1412 | Test Mash | Delete all data across all tables where clientId = 1412 |

### Scenario B — Shared Clients (delete by userId only)

| clientId | clientName | userIds to Delete |
|----------|------------|-------------------|
| 1 | Kurtosys | 5442 ⚠️ PENDING manager confirmation |
| 53 | Kurtovest Demo | 5554, 6114 |
| 1096 | k102.zelda | 2894 |
| 1360 | SFI QA | 5553, 6183 |
| 1449 | Training Divashan Naicker | 5814, 5819 |

**Scenario B userIds confirmed for deletion (excluding 5442):**
```
5819, 5814, 6114, 5554, 5553, 6183, 2894
```

---

## Step 3 — Tokens Check

```sql
SELECT 'Scenario A - userId 2894 (Test Mash)' AS Scope, COUNT(*) AS token_count
FROM Tokens WHERE userId = 2894
UNION ALL
SELECT 'Scenario B userIds', COUNT(*) FROM Tokens
WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
```

**Results:**

| Scope | token_count |
|-------|-------------|
| Scenario A - userId 2894 (Test Mash) | 0 |
| Scenario B userIds | 2 |

---

## Step 4 — Row Counts Before Deletion

### Scenario B Row Counts

| TableName | Row_Count |
|-----------|-----------|
| User | 7 |
| UserRole | 18 |
| UserApplication | 7 |
| UserConfiguration | 2 |
| Tokens | 2 |
| Activity | 609 |
| KAPP_human_users_audit | 3 |
| KAPP_non_human_users_audit | 1 |
| UserPasswordHistory | 13 |
| VersionHistory | 30 |
| WorkflowRunItemStatusHistory | 29 |
| DocumentNotificationDelivery | 6 |
| FailureLog | 7 |
| SavedSearch | 1 |
| ApplicationUpgrade | 1 |

Note: Activity, KAPP audit, VersionHistory etc. are audit/log tables — backed up but deletion scope to be confirmed.

### Scenario A Row Counts (clientId 1412 — non-zero tables only)

| TableName | Row_Count |
|-----------|-----------|
| Activity | 41 |
| Client | 1 |
| ClientConfiguration | 4 |
| DomainWhitelist | 1 |
| KAPP_human_users_audit | 1 |
| Strategies | 1 |
| User | 1 |
| WarpdriveCache | 1 |

All other tables = 0.

---

## Step 5 — Backup

### Scripts

- `run_checks.sh` — interactive safety checks runner (read only)
- `backup.sh` — mysqldump backup script (Scenario A + Scenario B)

### Backup Location on Jumpbox

```
/tmp/multi-user-offboarding/
```

### How Backup Script Works

Uses `INFORMATION_SCHEMA` to dynamically find all tables with `clientId` or `userId` columns — same principle as company standard (TECH-3310). Script is fully reusable for future tickets by changing only the clientId and userIds at the top.

```bash
mkdir -p /tmp/multi-user-offboarding && cd /tmp/multi-user-offboarding
bash backup.sh
```

### Backup Files Expected

```
Scenario B:
  User2026-07-01.sql
  UserRole2026-07-01.sql
  UserApplication2026-07-01.sql
  UserConfiguration2026-07-01.sql
  Tokens2026-07-01.sql
  ... (all tables with userId column)

Scenario A:
  Activity_clientId1412_2026-07-01.sql
  Client_clientId1412_2026-07-01.sql
  ClientConfiguration_clientId1412_2026-07-01.sql
  ... (all tables with clientId column)
```

### Backup Taken

```
(paste ls -lh output here after running backup.sh)
```

---

## Step 6 — Peer Review

```
STOP — Do not proceed until peer review approved.

Share with reviewer:
1. This documentation
2. Scenario classification results
3. Row counts from Step 4
4. Confirmation backups were created (ls -lh output)
```

| Field | Details |
|-------|---------|
| Reviewed by | _______________ |
| Date | _______________ |
| Approved | YES / NO |

---

## Step 7 — Delete

### Scenario B — Delete by userId

**ONLY run after peer review approval and backups verified.**

Children first, parent last:

```sql
-- CHILDREN FIRST
DELETE FROM UserRole          WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
DELETE FROM UserApplication   WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
DELETE FROM UserConfiguration WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
DELETE FROM Tokens            WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);

-- PARENT LAST
DELETE FROM User              WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
```

### Scenario A — Delete by clientId 1412

Uses `INFORMATION_SCHEMA` to generate delete statements across all tables:

```sql
SELECT CONCAT('DELETE FROM ', TABLE_NAME, ' WHERE clientId = 1412;')
FROM (SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'UDM__' AND COLUMN_NAME LIKE '%clientId%'
ORDER BY TABLE_NAME ASC) t;
```

Run the generated statements. Client record is deleted last.

### Delete Output

```
(paste mysql output here after deletion)
```

---

## Step 8 — Verification

### Scenario B Verify

```sql
SELECT 'User'              AS TableName, COUNT(*) AS Remaining FROM User              WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894) UNION ALL
SELECT 'UserRole',          COUNT(*) FROM UserRole          WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894) UNION ALL
SELECT 'UserApplication',   COUNT(*) FROM UserApplication   WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894) UNION ALL
SELECT 'UserConfiguration', COUNT(*) FROM UserConfiguration WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894) UNION ALL
SELECT 'Tokens',            COUNT(*) FROM Tokens            WHERE userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894);
```

### Scenario A Verify

```sql
SELECT CONCAT('SELECT ''', TABLE_NAME, ''' AS TableName, COUNT(*) AS Remaining FROM `', TABLE_NAME, '` WHERE clientId = 1412 UNION ALL')
FROM (SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'UDM__' AND COLUMN_NAME LIKE '%clientId%'
ORDER BY TABLE_NAME ASC) t;
```

### Verify Shared Clients Still Intact

```sql
SELECT c.clientId, c.clientName, COUNT(u.userId) AS remaining_users
FROM Client c JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (1, 53, 1096, 1360, 1449)
GROUP BY c.clientId, c.clientName;
```

### Verification Results

```
(paste verification output here)
```

---

## Step 9 — Ticket Closure

| Field | Details |
|-------|---------|
| Date closed | _______________ |
| Closed by | Lunga Ndzimande |
| Notes | userId 5442 (Mashaole on clientId 1 — Kurtosys) excluded pending manager confirmation |

---

## Actions Tracker

| Action | Status |
|--------|--------|
| Users identified in REL | ✅ Done |
| 3 users confirmed NOT in REL (Rayhaan) | ✅ Done |
| Client/userId map established | ✅ Done |
| Scenario classification done | ✅ Done |
| clientId 1449 shared users investigated | ✅ Done |
| Safety checks script (run_checks.sh) | ✅ Done |
| Row counts gathered | ✅ Done |
| Backup script ready (backup.sh) | ✅ Done |
| Backups taken | ⏳ Pending |
| Peer review | ⏳ Pending |
| Deletion | ⏳ Pending |
| Verification | ⏳ Pending |
| userId 5442 manager confirmation | ⏳ Pending |
| Ticket closed | ⏳ Pending |
