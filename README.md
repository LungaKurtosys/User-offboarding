# User Offboarding - REL Environment

This repository contains all scripts and documentation for user offboarding tasks
in the Kurtosys Release (REL) environment.

---

## Repository Structure

```
User-offboarding/
└── Isaiah-Adams/
    ├── DOCUMENTATION.md               - Full investigation, findings and process
    └── scripts/
        ├── script1_safety_checks_and_backup.sql  - Safety checks and row counts
        ├── script1_backup.sh                     - mysqldump backup script
        ├── script2_delete.sql                    - Delete children first, parent last
        └── script3_verify.sql                    - Verify cleanup successful
```

---

## Key Concept — Multi-Tenant Database

UDM__ is a **multi-tenant database**:
```
One database holds data for MANY clients
Every table has a clientId column separating tenants
NEVER delete another client's data
```

---

## Two Offboarding Scenarios

### Scenario A — Dedicated Client
Used when the client belongs to ONE user only (e.g. Louise Dobson TECH-1718):
```
→ Delete everything by clientId across ALL 160+ tables
→ Use INFORMATION_SCHEMA to auto-generate scripts
→ Client record is also deleted
```

### Scenario B — Shared Client
Used when the client is shared with many other users (e.g. Isaiah Adams):
```
→ Delete by userId ONLY across 5 tables
→ Never touch the Client table
→ Always delete children before parent
```

---

## Decision — Which Scenario to Use

```sql
-- Always run this check first
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) as total_users,
    CASE
        WHEN COUNT(u.userId) = 1
        THEN 'DEDICATED - Scenario A'
        ELSE 'SHARED - Scenario B'
    END as Process_To_Follow
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN (<clientIds>)
GROUP BY c.clientId, c.clientName;
```

---

## Parent and Child Table Order

Always delete in this order:
```
CHILDREN first:
  1. UserRole
  2. UserApplication
  3. UserConfiguration
  4. Tokens

PARENT last:
  5. User

Why? Deleting parent first creates ORPHANED RECORDS
     (children pointing to a userId that no longer exists)
```

---

## Process Overview

```
1. Investigate    - Find all records associated with the user
2. Safety Check   - Confirm if client is shared or dedicated
3. Row Counts     - Count all records before deletion
4. Backup         - Create mysqldump backups of all records
5. Peer Review    - Get approval before deletion
6. Delete         - Remove records (children first, parent last)
7. Verify         - Confirm all records are removed
8. Close Ticket   - Update and close the ticket
```

---

## Connection Details

| Field | Details |
|-------|---------|
| Environment | REL - Ireland (eu-west-1) |
| Database Host | ew1r-aggr-03.rel.kurtosys-internal.net |
| Port | 3306 |
| Database | UDM__ |
| Connection Method | AWS Session Manager - Jumpbox |
| Jumpbox | ew1r-jump-01.rel.kurtosys-internal.net |

---

## Offboarding Tickets

| User | Date | Client Type | Scenario | Status |
|------|------|-------------|----------|--------|
| Isaiah Adams | 2026-06-24 | Shared (clientId 53, 190) | Scenario B | In Progress |

---

## Important Rules

- Always check if client is shared or dedicated FIRST
- Always backup before deletion
- Always delete child tables before parent table
- Never delete clients that are shared with other users
- Always get peer review before running delete scripts
- Always verify all counts are 0 after deletion
