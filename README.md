# User Offboarding - REL Environment

**Author:** Lunga Ndzimande
**Environment:** REL - Ireland (eu-west-1)
**Database:** SingleStore - UDM__

---

## Repository Structure

```
user-offboarding-version-2/
│
├── offboarding-tickets/
│   ├── Isaiah-Adams/
│   │   ├── DOCUMENTATION.md
│   │   └── scripts/
│   │       ├── script1_safety_checks_and_backup.sql
│   │       ├── script1_backup.sh
│   │       ├── script2_delete.sql
│   │       └── script3_verify.sql
│   │
│   └── Multi-User-Offboarding/
│       ├── DOCUMENTATION.md
│       ├── Tech-XXXX.txt
│       └── scripts/
│           ├── run_checks.sh
│           ├── backup.sh
│           ├── script1_safety_checks.sql
│           ├── script2a_delete_dedicated.sql
│           ├── script2b_delete_shared.sql
│           └── script3_verify.sql
│
└── ai-agent-proposal/
    └── AI-Agent-Proposal.md
```

---

## Key Concept — Kurtosys KAPP Application Database

```
UDM__ holds ALL Kurtosys client data across 180+ tables
Every table has a clientId column linking data to a specific client
NEVER delete data belonging to another client
One wrong delete by clientId can affect hundreds of real client users
```

---

## Two Offboarding Scenarios

### Scenario A — Dedicated Client
```
→ Client belongs to ONE user only
→ Delete everything by clientId across ALL tables
→ Use INFORMATION_SCHEMA to auto-generate scripts
→ Client record is also deleted
```

### Scenario B — Shared Client
```
→ Client is shared with many other users
→ Delete by userId ONLY
→ Never touch the Client table
→ Always delete children before parent
```

---

## Parent and Child Table Deletion Order

```
CHILDREN first:
  1. UserRole
  2. UserApplication
  3. UserConfiguration
  4. Tokens

PARENT last:
  5. User

Why? Deleting parent first creates ORPHANED RECORDS
```

---

## Process Overview

```
1. Investigate    - Find all records associated with the user
2. Safety Check   - Confirm if client is shared or dedicated
3. Row Counts     - Count all records before deletion
4. Backup         - mysqldump backups of all records
5. Peer Review    - Get approval before deletion
6. Delete         - Remove records (children first, parent last)
7. Verify         - Confirm all records are removed
8. Close Ticket   - Update and close the Jira ticket
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

| Ticket | Users | Date | Scenario | Status |
|--------|-------|------|----------|--------|
| Isaiah Adams | Isaiah Adams | 2026-06-24 | Scenario B (shared) | In Progress |
| Multi-User | Mashaole Mogale, Zelda Miller, Divashan Naicker | 2026-07-01 | Scenario A + B | In Progress |

---

## Important Rules

- Always check if client is shared or dedicated FIRST
- Always backup before deletion
- Always delete child tables before parent table
- Never delete clients shared with other users
- Always get peer review before running delete scripts
- Always verify all counts are 0 after deletion
