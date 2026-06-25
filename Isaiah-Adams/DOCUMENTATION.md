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

## Key Learning — Why This Ticket Differs From TECH-1718

This ticket is different from the Louise Dobson offboarding (TECH-1718) because:

| | Louise Dobson (TECH-1718) | Isaiah Adams |
|--|--------------------------|--------------|
| Client type | Dedicated (1 user only) | Shared (many users) |
| Process | Delete everything by clientId | Delete by userId only |
| Tables | ALL 160+ tables | 5 tables only |
| Client record | Deleted | Left intact |

**UDM__ is a multi-tenant database:**
```
One database holds data for MANY clients
Every table has a clientId column separating tenants
NEVER delete another client's data
```

**Parent and Child table order:**
```
Always delete CHILDREN first → PARENT last

Children = UserRole, UserApplication, UserConfiguration, Tokens
Parent   = User

Reason: Deleting parent first creates ORPHANED RECORDS
        (children pointing to a userId that no longer exists)
```

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
Cloudflare IP `172.69.107.98` is intercepting traffic instead of routing to internal network.
AWS Session Manager required to access the internal REL environment.

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

Performed a port scan on the aggregator node to identify open ports.

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

---

## Step 6 - Connect to SingleStore

**Command:**
```bash
mysql -h ew1r-aggr-03.rel.kurtosys-internal.net -P 3306 -u FundPressSupport -p
```

**Result:**
```
Welcome to the MySQL monitor.
Server version: 5.7.32 SingleStoreDB source distribution
```

**Conclusion:** Successfully connected to SingleStore REL environment.

---

## Step 7 - Search for Isaiah Adams

Searched for Isaiah Adams across all key columns.

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
    OR u.email LIKE '%isaiah%'
    OR u.userName LIKE '%isaiah%';
```

**Result:**
```
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
| userId | clientId | userName                  | name         | email                     | status      | clientName        |
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
|   6274 |       53 | isaiah.adams@kurtosys.com | isaiah.adams | isaiah.adams@kurtosys.com | Deactivated | Kurtovest Demo    |
|   5999 |      190 | isaiah.adams@kurtosys.com | Isaiah Adams | isaiah.adams@kurtosys.com | Deactivated | Kapital Reporting |
+--------+----------+---------------------------+--------------+---------------------------+-------------+-------------------+
```

**Isaiah Adams accounts identified:**

| userId | clientId | clientName | Status |
|--------|----------|------------|--------|
| 6274 | 53 | Kurtovest Demo | Deactivated |
| 5999 | 190 | Kapital Reporting | Deactivated |

---

## Step 8 - Safety Check (Confirm Clients are Shared)

**This is the critical step — must be done before any deletion.**

**Command:**
```sql
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Safe to delete by clientId'
        ELSE 'SHARED - Delete by userId only'
    END as Safety_Check
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (53, 190)
GROUP BY c.clientId, c.clientName;
```

**Result:**
```
+----------+-------------------+-------------+----------------------------------+
| clientId | clientName        | total_users | Safety_Check                     |
+----------+-------------------+-------------+----------------------------------+
|       53 | Kurtovest Demo    |         669 | SHARED - Delete by userId only   |
|      190 | Kapital Reporting |          57 | SHARED - Delete by userId only   |
+----------+-------------------+-------------+----------------------------------+
```

**Conclusion:**
- Kurtovest Demo has 669 other users — client NOT to be deleted
- Kapital Reporting has 57 other users — client NOT to be deleted
- Must delete by userId only — NOT by clientId
- This is a SHARED client scenario

---

## Step 9 - Row Count Before Deletion

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
FROM UserConfiguration WHERE userId IN (6274, 5999)
UNION ALL
SELECT 'Tokens', COUNT(*)
FROM Tokens WHERE userId IN (6274, 5999);
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
| Tokens            |         0 |
+-------------------+-----------+
Total: 11 records to be deleted across 3 tables
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
| Client Type | SHARED — delete by userId only |

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
| Tokens | 0 |
| Total | 11 |

**Safety checks:**
- Kurtovest Demo has 669 other users — client NOT deleted
- Kapital Reporting has 57 other users — client NOT deleted
- Only Isaiah's user records to be removed by userId

---

## Scripts

| Script | File | Purpose |
|--------|------|---------|
| Script 1 | script1_safety_checks_and_backup.sql | Safety checks and row counts |
| Backup | script1_backup.sh | mysqldump backups by userId |
| Script 2 | script2_delete.sql | Delete children first then parent |
| Script 3 | script3_verify.sql | Verify cleanup successful |

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
