#!/bin/bash
set -e

REPO_PATH="git/iac-ct-technitium"
CONTAINER_NAME="ct-technitium"
LXC_ID="102"
COMPOSE_FILE="${REPO_PATH}/docker-compose.yml"

echo "--- Starting deployment script for Technitium DNS Server ---"

# 1. Ensure we are in the project directory
cd "${REPO_PATH}" || { echo "Error: Could not navigate to ${REPO_PATH}"; exit 1; }

echo "--- 2. Entering target container (LXC ID ${LXC_ID}) ---"
# Use pct enter as specified by user clarification
pct enter "${LXC_ID}" -- /bin/bash || { echo "Error: Failed to enter container ${LXC_ID}. Is pct installed and ID correct?"; exit 1; }

echo "--- 3. Pulling latest Technitium image ---"
docker pull technitium/dns-server:latest

echo "--- 4. Running Docker Compose up -d ---"
docker compose -f "${COMPOSE_FILE}" up -d

echo "--- 5. Verifying container health (Waiting for container to start) ---"
MAX_WAIT_TIME=60
ELAPSED_TIME=0
IS_RUNNING=false

while [ $ELAPSED_TIME -lt $MAX_WAIT_TIME ]; do
    STATUS=$(docker ps -q --filter "name=${CONTAINER_NAME}")
    if [ -n "$STATUS" ]; then
        # Check status to ensure it's 'running'
        CONTAINER_STATE=$(docker inspect -f '{{status}}' "$STATUS")
        if [ "$CONTAINER_STATE" == "running" ]; then
            echo "Success: Container ${CONTAINER_NAME} is running."
            IS_RUNNING=true
            break
        fi
    fi
    sleep 5
    ELAPSED_TIME=$((ELAPSED_TIME + 5))
done

if [ "$IS_RUNNING" = false ]; then
    echo "Error: Container ${CONTAINER_NAME} failed to start within ${MAX_WAIT_TIME} seconds."
    exit 1
fi

echo "--- Deployment successful. Container is running and healthy. ---"

# Return to host shell if needed, though the script ends here.
exit 0