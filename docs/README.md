# Technitium DNS Server Deployment Guide

This repository contains the Infrastructure as Code (IaC) definition for deploying the Technitium DNS Server.

## Overview
The deployment utilizes Docker Compose for streamlined, declarative deployment. The server exposes DNS (UDP/TCP on port 53) and a Web UI (TCP on port 5380).

## Quick Start (Docker Compose)
1. Ensure Docker and Docker Compose are installed on the host machine.
2. Run: `docker compose up -d`

## Alternative: Direct Docker Run Command
For quick testing or environments without Docker Compose, use the following command. Ensure to replace `<CONFIG_PATH>` with your actual configuration volume path.

\`\`\`bash
docker run --name ct-technitium \
  -p 53:53/tcp -p 53:53/udp -p 5380:5380/tcp \
  -v <CONFIG_PATH>:/etc/dns \
  --restart always \
  technitium/dns-server:latest
\`\`\`

## Configuration
The server configuration is managed via the `/config` directory, which mounts into the container at `/etc/dns`. The baseline settings are defined in `config/default.yaml`.

## Deployment Script
The primary deployment mechanism is the `deploy-iac-ct-technitium.sh` script, which handles pulling the image, running the services, and verifying health within the target LXC environment.