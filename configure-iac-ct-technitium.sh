#!/bin/bash
set -e

PROX_HOST="192.168.1.10"
LXC_ID="102"
REPO_PATH="/home/pricekev/git/iac-ct-technitium"

echo "============================================================"
echo "  Technitium DNS Server - Configuration Only"
echo "  Target: LXC ${LXC_ID} on ${PROX_HOST}"
echo "============================================================"

# ---------------------------------------------------------------
# STEP 1: ENSURE /etc/dns DIRECTORY EXISTS
# ---------------------------------------------------------------
echo ""
echo "--- Step 1: Ensuring /etc/dns directory exists ---"
ssh root@${PROX_HOST} "mkdir -p /etc/dns"
echo "  OK: /etc/dns ready"

# ---------------------------------------------------------------
# STEP 2: BACKUP EXISTING CONFIG
# ---------------------------------------------------------------
echo ""
echo "--- Step 2: Backing up existing /etc/dns config ---"
if ssh root@${PROX_HOST} "test -d /etc/dns && ls -A /etc/dns" 2>/dev/null | grep -q .; then
    BACKUP_DIR="/etc/dns_backup_$(date +%Y%m%d_%H%M%S)"
    echo "  Backing up /etc/dns to ${BACKUP_DIR} ..."
    ssh root@${PROX_HOST} "cp -a /etc/dns ${BACKUP_DIR}"
    echo "  Backup complete: ${BACKUP_DIR}"
else
    echo "  No existing config files found. Skipping backup."
fi

# ---------------------------------------------------------------
# STEP 3: SYNC CONFIG FILES
# ---------------------------------------------------------------
echo ""
echo "--- Step 3: Syncing configuration files ---"
scp -o StrictHostKeyChecking=accept-new "${REPO_PATH}"/config/Dns.conf root@${PROX_HOST}:/etc/dns/
scp -o StrictHostKeyChecking=accept-new "${REPO_PATH}"/config/Settings.json root@${PROX_HOST}:/etc/dns/
echo "  OK: Config files synced"

# ---------------------------------------------------------------
# STEP 4: RESTART CONTAINER IF RUNNING
# ---------------------------------------------------------------
echo ""
echo "--- Step 4: Restarting container to apply config ---"
if ssh root@${PROX_HOST} "docker ps -q --filter name=ct-technitium" 2>/dev/null | grep -q .; then
    echo "  Container is running. Restarting..."
    ssh root@${PROX_HOST} "docker restart ct-technitium"
    echo "  OK: Container restarted"
else
    echo "  Container not running. Configuration synced but container not started."
    echo "  Run deploy-iac-ct-technitium.sh to deploy, or start manually:"
    echo "    ssh root@${PROX_HOST} 'docker start ct-technitium'"
fi

# ---------------------------------------------------------------
# STEP 5: SHOW STATUS
# ---------------------------------------------------------------
echo ""
echo "--- Container Status ---"
ssh root@${PROX_HOST} "docker ps --filter name=ct-technitium" 2>/dev/null || echo "  Container is not running."

echo ""
echo "============================================================"
echo "  Configuration complete!"
echo ""
echo "  Config files: /etc/dns/Dns.conf, /etc/dns/Settings.json"
echo "  Backup: /etc/dns_backup_YYYYMMDD_HHMMSS/"
echo "============================================================"

exit 0
