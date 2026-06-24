# User Offboarding - REL Environment

This repository contains all scripts and documentation for user offboarding tasks 
in the Kurtosys Release (REL) environment.

## Repository Structure

```
User-offboarding/
    Isaiah-Adams/
        DOCUMENTATION.md        - Full step by step investigation and findings
        scripts/
            script1_safety_checks_and_backup.sql  - Safety checks and row counts
            script1_backup.sh                     - mysqldump backup script
            script2_delete.sql                    - Delete records and update cache
            script3_verify.sql                    - Verify cleanup successful
```

## Process Overview

Every offboarding task follows this process:

```
1. Investigate - Find all records associated with the user
2. Safety Check - Confirm clients are shared before deletion
3. Backup - Create mysqldump backups of all records
4. Peer Review - Get approval before deletion
5. Delete - Remove records in correct order (children first, parent last)
6. Cache Update - Update WarpdriveCache after deletion
7. Verify - Confirm all records are removed
8. Close Ticket - Update and close the ticket
```

## Connection Details

| Field | Details |
|-------|---------|
| Environment | REL - Ireland (eu-west-1) |
| Database Host | ew1r-aggr-03.rel.kurtosys-internal.net |
| Port | 3306 |
| Database | UDM__ |
| Connection Method | AWS Session Manager - Jumpbox |

## Offboarding Tickets

| User | Date | Status |
|------|------|--------|
| Isaiah Adams | 2026-06-24 | In Progress |

## Important Rules

- Always backup before deletion
- Always delete child tables before parent tables
- Never delete clients that are shared with other users
- Always update WarpdriveCache after deletion
- Always get peer review before running delete scripts
