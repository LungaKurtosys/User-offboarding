#!/bin/bash
# ============================================
# BACKUP SCRIPT
# Author: Lunga Ndzimande
# Ticket: Isaiah Adams Offboarding
# Environment: REL (Release)
# Date: 2026-06-24
# ============================================

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
