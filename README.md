# iac-ct-technitium

Infrastructure as Code for Technitium DNS Server deployment.

## Overview

This repository contains the infrastructure as code for deploying [Technitium DNS Server](https://technitium.com/dns/) on a Proxmox LXC container using Docker Compose. The server provides DNS resolution with a web-based management console.

## Features

1. Proper Technitium configuration (Dns.conf + Settings.json)
2. Automated deployment with health checks
3. Backup and restore support
4. Pre-flight checks before deployment

## Files

- `deploy-iac-ct-technitium.sh` - Full deployment script (provision + deploy + config sync)
- `docker-compose.yml` - Docker Compose configuration
- `config/Dns.conf` - Technitium DNS server configuration
- `config/Settings.json` - Technitium web console settings

## Quick Start

### Deploy the service

```bash
./deploy-iac-ct-technitium.sh
```

To sync config changes to an existing deployment:
```bash
# Copy updated config files, then restart:
scp config/Dns.conf root@192.168.1.10:/etc/dns/
scp config/Settings.json root@192.168.1.10:/etc/dns/
ssh root@192.168.1.10 "docker restart ct-technitium"
```

## Access

- **DNS Server:** Port 53 (TCP/UDP)
- **Web UI:** http://<container-ip>:5380

To find the container IP:
```bash
ssh root@192.168.1.10 "docker inspect -f '{{.NetworkSettings.IPAddress}}' ct-technitium"
```

## Configuration

Technitium configuration files are located in the `config/` directory:

### Dns.conf

INI-style configuration for DNS server behavior. Key settings:

- **Forwarders:** Upstream DNS servers (8.8.8.8, 1.1.1.1 by default)
- **Interface:** IP to bind to (0.0.0.0 = all interfaces)
- **LogLevel:** Logging verbosity
- **BlockCategoryFilters:** Content blocking categories

### Settings.json

JSON configuration for the web console and application settings:

- **UpdateChannel:** stable, beta, or testing
- **DNS Recursion:** Enable/disable recursive queries
- **NTP:** Network time synchronization settings
- **Logging:** Log level and rotation

## Deployment Details

The deployment targets LXC container 102 on Proxmox host 192.168.1.10. This can be changed by editing the `LXC_ID` and `PROX_HOST` variables in the deploy script.

The container requires:
- Docker and Docker Compose on the host
- Port 53 (TCP/UDP) for DNS
- Port 5380 (TCP) for the web UI
- `NET_ADMIN` capability for DNS binding

## Backups

When configuration is synced or deployed, existing `/etc/dns` data is automatically backed up to `/etc/dns_backup_YYYYMMDD_HHMMSS/` on the Proxmox host.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
