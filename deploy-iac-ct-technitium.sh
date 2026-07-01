#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="ct-technitium"
LXC_ID="102"
PROX_HOST="192.168.1.10"
CONTAINER_IP="192.168.1.15"

# Detect repo path regardless of where script is run from
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_PATH="$SCRIPT_DIR"
COMPOSE_FILE="${REPO_PATH}/docker-compose.yml"

# Helper: run commands inside the LXC
lxc() { ssh root@${PROX_HOST} "pct exec ${LXC_ID} -- /bin/sh -c '$*'"; }

# Helper: run commands on the Proxmox host (not inside LXC)
prox() { ssh root@${PROX_HOST} "$*"; }

echo "============================================================"
echo "  Technitium DNS Server Deployment"
echo "  Target: LXC ${LXC_ID} on ${PROX_HOST}"
echo "============================================================"

# ---------------------------------------------------------------
# PRE-FLIGHT CHECKS
# ---------------------------------------------------------------
echo ""
echo "--- Running pre-flight checks ---"

# 1. Check docker is available on the Proxmox host
echo "  [1/4] Checking docker is available..."
if ! lxc "docker --version" >/dev/null 2>&1; then
    echo "ERROR: docker is not installed or not in PATH on the Proxmox host (LXC ${LXC_ID})."
    echo "       Install docker first: https://docs.docker.com/engine/install/"
    exit 1
fi
echo "      OK: docker found"

# 2. Check docker compose is available
echo "  [2/4] Checking docker compose is available..."
if ! lxc "docker compose version" >/dev/null 2>&1; then
    echo "ERROR: docker compose plugin is not available on the Proxmox host."
    echo "       Install it first."
    exit 1
fi
echo "      OK: docker compose found"

# 3. Check connectivity to the Proxmox host
echo "  [3/4] Checking connectivity to ${PROX_HOST}..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes root@${PROX_HOST} "echo ok" >/dev/null 2>&1; then
    echo "ERROR: Cannot reach ${PROX_HOST}. Check SSH connectivity."
    exit 1
fi
echo "      OK: SSH to ${PROX_HOST} successful"

# 4. Check that port 53 is not already bound to the container's dedicated IP
echo "  [4/4] Checking that port 53 is free on ${CONTAINER_IP}..."
if prox "ss -tlnup | grep '${CONTAINER_IP}:53 ' 2>/dev/null" | grep -q .; then
    echo "WARNING: Port 53 on ${CONTAINER_IP} is already in use."
    read -r -p "  Continue anyway? [y/N] " choice
    case "$choice" in
        [yY]*) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
else
    echo "      OK: port 53 on ${CONTAINER_IP} is free"
fi

# ---------------------------------------------------------------
# STEP 1: BACKUP EXISTING CONFIG
# ---------------------------------------------------------------
echo ""
echo "--- Step 1: Backing up existing /etc/dns config ---"
if lxc "test -d /etc/dns" 2>/dev/null; then
    BACKUP_DIR="/etc/dns_backup_$(date +%Y%m%d_%H%M%S)"
    echo "  Backing up /etc/dns to ${BACKUP_DIR} ..."
    lxc "cp -a /etc/dns ${BACKUP_DIR}"
    echo "  Backup complete: ${BACKUP_DIR}"
else
    echo "  No existing /etc/dns directory found. Skipping backup."
fi

# ---------------------------------------------------------------
# STEP 2: ENSURE /etc/dns DIRECTORY EXISTS
# ---------------------------------------------------------------
echo ""
echo "--- Step 2: Ensuring /etc/dns directory exists ---"
# Create /etc/dns on the Proxmox host (shared with LXC via mount point)
prox "mkdir -p /etc/dns"
echo "  OK: /etc/dns ready"

# ---------------------------------------------------------------
# STEP 3: SYNC CONFIG FILES
# ---------------------------------------------------------------
echo ""
echo "--- Step 3: Syncing configuration files ---"
# Copy config files
scp -o StrictHostKeyChecking=accept-new "${REPO_PATH}"/config/Dns.conf root@${PROX_HOST}:/etc/dns/ 2>/dev/null || true
scp -o StrictHostKeyChecking=accept-new "${REPO_PATH}"/config/Settings.json root@${PROX_HOST}:/etc/dns/ 2>/dev/null || true
# Copy docker-compose.yml to /etc/dns so the LXC can run it
scp -o StrictHostKeyChecking=accept-new "${REPO_PATH}"/docker-compose.yml root@${PROX_HOST}:/etc/dns/docker-compose.yml
echo "  OK: Config files synced"

# ---------------------------------------------------------------
# STEP 4: REMOVE EXISTING CONTAINER (IF ANY)
# ---------------------------------------------------------------
echo ""
echo "--- Step 4: Removing existing container (if any) ---"
lxc "docker rm -f ${CONTAINER_NAME}" 2>/dev/null || true

# ---------------------------------------------------------------
# STEP 5: DEPLOY VIA DOCKER-COMPOSE
# ---------------------------------------------------------------
echo ""
echo "--- Step 5: Deploying via Docker Compose ---"
# Run docker-compose directly on the Proxmox host (/etc/dns lives on the host,
# not mounted into the LXC). The container is created by docker on the host.
prox "docker compose -f /etc/dns/docker-compose.yml --project-name ${CONTAINER_NAME} up -d"

# ---------------------------------------------------------------
# STEP 6: WAIT FOR CONTAINER TO START
# ---------------------------------------------------------------
echo ""
echo "--- Step 6: Waiting for container to start ---"
MAX_WAIT=90
ELAPSED=0
IS_RUNNING=false

while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(lxc "docker ps -q --filter name=${CONTAINER_NAME}" 2>/dev/null || true)
    if [ -n "$STATUS" ]; then
        CONTAINER_STATE=$(lxc "docker inspect -f '{{.State.Status}}' ${CONTAINER_NAME}" 2>/dev/null || true)
        if [ "$CONTAINER_STATE" = "running" ]; then
            echo "  Container is running."
            IS_RUNNING=true
            break
        fi
    fi
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ "$IS_RUNNING" = false ]; then
    echo "ERROR: Container ${CONTAINER_NAME} failed to start within ${MAX_WAIT} seconds."
    echo "--- Container Logs ---"
    lxc "docker logs ${CONTAINER_NAME} 2>&1 | tail -30"
    exit 1
fi

# ---------------------------------------------------------------
# STEP 7: SERVICE-LEVEL HEALTH CHECKS
# ---------------------------------------------------------------
echo ""
echo "--- Step 7: Service-level health checks ---"

# Wait a bit for DNS and web UI to be ready
sleep 10

# Check DNS port 53 is listening on the container's dedicated IP
echo "  [1/2] Checking DNS service (port 53 on ${CONTAINER_IP})..."
if prox "ss -tlnup | grep '${CONTAINER_IP}:53 ' 2>/dev/null" | grep -q .; then
    echo "      OK: DNS port 53 is listening on ${CONTAINER_IP}"
else
    echo "  WARNING: DNS port 53 on ${CONTAINER_IP} not yet listening. The service may still be starting."
fi

# Check web UI port 5380 on the container's dedicated IP
echo "  [2/2] Checking Web UI (port 5380 on ${CONTAINER_IP})..."
if prox "ss -tlnup | grep '${CONTAINER_IP}:5380 ' 2>/dev/null" | grep -q .; then
    echo "      OK: Web UI port 5380 is listening on ${CONTAINER_IP}"
else
    echo "  WARNING: Web UI port 5380 on ${CONTAINER_IP} not yet listening. The service may still be starting."
fi

# ---------------------------------------------------------------
# STEP 8: SHOW STATUS
# ---------------------------------------------------------------
echo ""
echo "--- Container Status ---"
lxc "docker ps --filter name=${CONTAINER_NAME}"

echo ""
echo "============================================================"
echo "  Deployment complete!"
echo ""
echo "  DNS:    ${CONTAINER_IP}:53 (TCP/UDP)"
echo "  Web UI: http://${CONTAINER_IP}:5380"
echo ""
echo "  NOTE: Ports are bound to ${CONTAINER_IP} only — no host conflict."
echo "============================================================"
echo ""
echo "  Config files are in: /etc/dns/ (backups in /etc/dns_backup_YYYYMMDD_HHMMSS/)"

exit 0
