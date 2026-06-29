#!/bin/bash
# Deploy script for iac-ct-technitium
set -e

echo "Starting deployment for iac-ct-technitium..."

# Add deployment logic here
echo "Deployment for iac-ct-technitium completed successfully."

# Deploy using docker-compose
docker-compose -f technitium-docker-compose.yml up -d