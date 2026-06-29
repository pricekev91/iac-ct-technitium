#!/bin/bash
# Configuration script for iac-ct-technitium
set -e

echo "Configuring iac-ct-technitium..."

# Add configuration logic here
echo "Configuration for iac-ct-technitium completed successfully."

# Create a basic docker-compose file
cat > technitium-docker-compose.yml << EOF
version: '3.8'
services:
  technitium:
    image: technitium/technitium:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "8080:8080"
EOF