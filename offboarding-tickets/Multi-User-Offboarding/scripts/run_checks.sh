#!/bin/bash
# ============================================
# SAFETY CHECKS & ROW COUNTS - Interactive Runner
# Author: Lunga Ndzimande
# Ticket: Multi-User Offboarding
# Environment: REL (Release)
# RUN FROM: Jumpbox via AWS Session Manager
# NOTE: userId 5442 excluded pending manager confirmation
# ============================================

DB_HOST="ew1r-aggr-03.rel.kurtosys-internal.net"
DB_USER="CSE"
DB_NAME="UDM__"
CLIENT_IDS="1, 53, 1096, 1360, 1412, 1449"
USER_IDS="5819, 5814, 6114, 5554, 5553, 6183, 2894"
CLIENT_ID_A="1412"

MYSQL="mysql -h $DB_HOST -u $DB_USER -p $DB_NAME"

prompt_proceed() {
    echo ""
    read -p ">>> Proceed to next step? (yes/no): " answer
    if [[ "$answer" != "yes" ]]; then
        echo "Stopped. No changes have been made."
        exit 0
    fi
    echo ""
}

# ============================================
echo "============================================"
echo " STEP 1: CLIENT CONFIRMATION"
echo "============================================"
$MYSQL -e "
SELECT clientId, clientName, s3Folder
FROM Client
WHERE clientId IN ($CLIENT_IDS);"

prompt_proceed

# ============================================
echo "============================================"
echo " STEP 2: SCENARIO CLASSIFICATION"
echo "============================================"
$MYSQL -e "
SELECT
    c.clientId,
    c.clientName,
    COUNT(u.userId) AS total_users,
    CASE
        WHEN COUNT(u.userId) = 1 THEN 'DEDICATED - Scenario A - Delete by clientId'
        ELSE 'SHARED - Scenario B - Delete by userId only'
    END AS Scenario
FROM Client c
JOIN User u ON c.clientId = u.clientId
WHERE c.clientId IN ($CLIENT_IDS)
GROUP BY c.clientId, c.clientName;"

prompt_proceed

# ============================================
echo "============================================"
echo " STEP 3: TOKENS CHECK"
echo "============================================"
$MYSQL -e "
SELECT 'Scenario A - userId 2894 (Test Mash)' AS Scope, COUNT(*) AS token_count
FROM Tokens WHERE userId = 2894
UNION ALL
SELECT 'Scenario B userIds', COUNT(*) FROM Tokens
WHERE userId IN ($USER_IDS);"

prompt_proceed

# ============================================
echo "============================================"
echo " STEP 4: ROW COUNTS - SCENARIO B"
echo "============================================"
# Build dynamic query from INFORMATION_SCHEMA then execute it
QUERY=$($MYSQL -N -e "
SELECT GROUP_CONCAT(
    CONCAT('SELECT ''', TABLE_NAME, ''' AS TableName, COUNT(*) AS Row_Count FROM \`', TABLE_NAME, '\` WHERE userId IN ($USER_IDS)')
    SEPARATOR ' UNION ALL ')
FROM (SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '$DB_NAME'
AND COLUMN_NAME LIKE '%userId%'
ORDER BY TABLE_NAME ASC) t;")

$MYSQL -e "$QUERY"

prompt_proceed

# ============================================
echo "============================================"
echo " STEP 5: ROW COUNTS - SCENARIO A (clientId $CLIENT_ID_A)"
echo "============================================"
# Build dynamic query from INFORMATION_SCHEMA then execute it
QUERY=$($MYSQL -N -e "
SELECT GROUP_CONCAT(
    CONCAT('SELECT ''', TABLE_NAME, ''' AS TableName, COUNT(*) AS Row_Count FROM \`', TABLE_NAME, '\` WHERE clientId = $CLIENT_ID_A')
    SEPARATOR ' UNION ALL ')
FROM (SELECT DISTINCT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = '$DB_NAME'
AND COLUMN_NAME LIKE '%clientId%'
ORDER BY TABLE_NAME ASC) t;")

$MYSQL -e "$QUERY"

echo ""
echo "============================================"
echo " ALL STEPS COMPLETE - READ ONLY, NO CHANGES MADE"
echo "============================================"
