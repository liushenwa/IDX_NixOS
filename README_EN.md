# IDX Multi-Container Proxy Service Deployment Project
Documentation: English version | [中文版](https://github.com/fscarmen2/IDX_NixOS/blob/main/README.md)

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Component Details](#component-details)
  - [Container Environment](#1-container-environment)
  - [Network Proxy Service](#2-network-proxy-service)
  - [Network Tunneling Service](#3-network-tunneling-service)
  - [Monitoring Service](#4-monitoring-service)
- [Deployment Steps](#deployment-steps)
  - [Download Project](#1-download-project)
  - [Modify Configuration](#2-modify-configuration)
  - [Save Files](#3-save-files)
  - [Deploy to IDX](#4-deploy-to-idx)
  - [Verify Deployment](#5-verify-deployment)
  - [Notes](#notes)
- [OpenWrt FRPC Quick Deployment](#openwrt-frpc-quick-deployment)
  - [OpenWRT Deployment Steps](#openwrt-deployment-steps)
  - [Uninstallation](#uninstallation)
  - [OpenWRT Notes](#openwrt-notes)

## Project Overview
This project is a multi-container proxy service deployment solution based on the IDX development environment. It integrates various network tools and services, including Sing-Box, Cloudflare Argo Tunnel, FRP intranet penetration, and multiple Linux container environments. The project uses Nix configuration files for automated deployment and management, providing a complete network proxy and remote access solution.

## Features
1. **Multi-Container Environment**: Simultaneously deploy Debian, Ubuntu, CentOS, and Alpine Linux containers
2. **Network Proxy Service**: Integrate Sing-Box with support for 6 protocols
3. **Network Tunneling**: Enable external access to internal services via Cloudflare Argo Tunnel and FRP
4. **Service Monitoring**: Integrate Nezha monitoring agent for real-time service status tracking
5. **Automated Deployment**: One-click deployment and startup using IDX's Nix configuration
6. **Secure Access**: All containers configured with SSH remote access, supporting password authentication

## Component Details
### 1. Container Environment
The project deploys four mainstream Linux containers, each configured with SSH service for remote login:

- **Debian**: General Linux environment suitable for most application deployments
- **Ubuntu**: User-friendly interface with rich package support
- **CentOS 9**: Enterprise-grade stability for long-running services
- **Alpine**: Lightweight container with minimal resource usage

### 2. Network Proxy Service
Using Sing-Box to provide high-performance network proxy services:

- **Protocol Support**: VMess + WebSocket + TLS, VLESS + WebSocket + TLS, VLESS + Reality, AnyTLS, Hysteria2, TUIC
- **Multi-Client Support**: Auto-generate configurations for Clash, V2rayN, NekoBox, Shadowrocket, and SingBox

### 3. Network Tunneling Service
- **Cloudflare Argo Tunnel**: Securely expose internal services to the internet without public IP.
- **FRP Intranet Penetration**: Provide external access ports for each container's SSH service.

### 4. Monitoring Service
- **Nezha Monitoring**: Real-time server status monitoring, including CPU, memory, network metrics.

## Deployment Steps
1. **Download Project**
   
   - Download the project archive file locally.

2. **Modify Configuration**
   
   - Open .idx/dev.nix file.
   - Modify parameters according to comments.
   - Important: Beginners should maintain default settings except for the env section.

3. **Save Files**
   
   - Save the modified .idx/dev.nix file.
   - Ensure all necessary files are included in the archive.

4. **Deploy to IDX**
   
   - Visit https://idx.google.com.
   - Create new custom workspace.
   - Upload the modified project archive.
   - Wait approximately 2 minutes for automatic deployment.

5. **Verify Deployment**
   
   - Access services through configured domain.
   - Access containers using configured ports and passwords.
   - Check Nezha dashboard for service status.

### Notes:

- Ensure parameter formats are correct and quotes are complete.
- Use strong passwords for sensitive information.
- Test all services immediately after deployment.

## OpenWrt FRPC Quick Deployment

This project provides a one-click deployment script for quickly deploying and managing FRP client on OpenWrt systems.

### OpenWRT Deployment Steps

1. **Download and Execute Installation Script**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/fscarmen2/IDX_NIXOS/main/install-frpc.sh)
```

2. **Configure FRPC**
   - The script will prompt you to input FRPC configuration content
   - Press Ctrl+D when finished to save

3. **Service Management**
   - Start service: `/etc/init.d/idx-frpc start`
   - Stop service: `/etc/init.d/idx-frpc stop`
   - Restart service: `/etc/init.d/idx-frpc restart`

### Uninstallation

To uninstall the FRPC service, simply execute:
```bash
uninstall-idx-frpc
```

This command will:
- Stop FRPC service
- Remove all configuration files
- Remove service scripts
- Clean up log files

### OpenWRT Notes

1. Ensure either curl or wget is installed on the system
2. Configuration file is saved at `/etc/frpc/idx-frpc.toml`
3. Log file location: `/var/log/idx-frpc.log`
4. Supports configuration file hot reload
5. Process automatically restarts on abnormal exit