#!/bin/bash
# ============================================
# BACKUP SCRIPT: Isaiah Adams Offboarding
# Author: Lunga Ndzimande
# Ticket: Isaiah Adams Offboarding
# Environment: REL (Release)
# Date: 2026-06-24
# NOTE: Clients are SHARED - backup by userId only
# RUN FROM: Jumpbox via AWS Session Manager
# ============================================

DB_HOST="ew1r-aggr-03.rel.kurtosys-internal.net"
DB_USER="FundPressSupport"
DB_NAME="UDM__"
DATE="2026-06-24"
BACKUP_DIR="/tmp/Isaiah-Adams-Offboarding"
USER_IDS="userId IN (6274, 5999)"

# Create backup folder
mkdir -p $BACKUP_DIR
cd $BACKUP_DIR

echo "Starting backups for Isaiah Adams userId 6274 and 5999..."

# Backup User table
mysqldump -h $DB_HOST -u $DB_USER -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="$USER_IDS" \
$DB_NAME User > User_$DATE.sql
echo "User backup done"

# Backup UserRole table
mysqldump -h $DB_HOST -u $DB_USER -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="$USER_IDS" \
$DB_NAME UserRole > UserRole_$DATE.sql
echo "UserRole backup done"

# Backup UserApplication table
mysqldump -h $DB_HOST -u $DB_USER -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="$USER_IDS" \
$DB_NAME UserApplication > UserApplication_$DATE.sql
echo "UserApplication backup done"

# Backup UserConfiguration table
mysqldump -h $DB_HOST -u $DB_USER -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="$USER_IDS" \
$DB_NAME UserConfiguration > UserConfiguration_$DATE.sql
echo "UserConfiguration backup done"

# Backup Tokens table
mysqldump -h $DB_HOST -u $DB_USER -p --hex-blob --no-create-info \
--max_allowed_packet=512M \
--where="$USER_IDS" \
$DB_NAME Tokens > Tokens_$DATE.sql
echo "Tokens backup done"

# Verify all backups created
echo ""
echo "Backup files created:"
ls -lh $BACKUP_DIR/
echo ""
echo "All backups complete. Ready for peer review."
