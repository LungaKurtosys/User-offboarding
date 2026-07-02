#!/bin/bash
# ============================================
# BACKUP SCRIPT: Multi-User Offboarding
# Author: Lunga Ndzimande
# Environment: REL (Release)
# Date: 2026-07-01
# RUN FROM: DB server inside /tmp/multi-user-offboarding/
# mkdir -p /tmp/multi-user-offboarding && cd /tmp/multi-user-offboarding
# NOTE: userId 5442 excluded pending manager confirmation
# ============================================

DATE="2026-07-01"
DB="UDM__"

# ============================================
# SCENARIO A - Dedicated client (clientId 1412 - Test Mash)
# Dynamically gets all tables with clientId column
# ============================================

for TABLE in $(mysql -h0 -uroot -p'' -N -e "
  SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = '$DB' AND COLUMN_NAME LIKE '%clientId%'
  ORDER BY TABLE_NAME ASC;"); do
  mysqldump -h0 -uroot -p'' --hex-blob --no-create-info --max_allowed_packet=512M \
    --where="clientId = 1412" $DB $TABLE > ${TABLE}_clientId1412_${DATE}.sql
done

# ============================================
# SCENARIO B - Shared clients (backup by userId)
# Users: Mashaole Mogale, Zelda Miller, Divashan Naicker
# Dynamically gets all tables with userId column
# ============================================

for TABLE in $(mysql -h0 -uroot -p'' -N -e "
  SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = '$DB' AND COLUMN_NAME LIKE '%userId%'
  ORDER BY TABLE_NAME ASC;"); do
  mysqldump -h0 -uroot -p'' --hex-blob --no-create-info --max_allowed_packet=512M \
    --where="userId IN (5819, 5814, 6114, 5554, 5553, 6183, 2894)" $DB $TABLE > ${TABLE}_${DATE}.sql
done
