# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.1.0] - 2026-06-30

### Added
- Pre-flight checks in deploy script (docker, docker compose, SSH connectivity, port 53)
- Service-level health checks (DNS on port 53, Web UI on port 5380)
- Automatic backup of existing /etc/dns config before deployment
- Separate configuration-only script (configure-iac-ct-technitium.sh) with distinct functionality
- Proper Technitium config files: Dns.conf (INI format) and Settings.json (JSON format)
- Container IP lookup tip in deployment output
- Updated README with full documentation

### Changed
- Replaced YAML config (default.yaml) with native Technitium format (Dns.conf + Settings.json)
- Updated deploy script with 8-step process including backup, pre-flight, health checks
- Updated configure script to be truly configuration-focused (sync + restart only)
- Enhanced changelog with detailed version history

### Fixed
- Config format incompatible with Technitium DNS Server
- No backup of existing data before overwrite
- No service-level verification after container start
- Deploy and configure scripts were duplicates

## [v1.0.1] - Previous
- Bug fix for deployment script

## [v1.0.0] - Previous
- Initial project setup
