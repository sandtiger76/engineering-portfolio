# Setup Guide — Homelab Automation Stack

**Date:** 2026-03-02  
**Author:** Quintin Boshoff  
**Host:** proxmox (192.168.1.2)  
**Container:** automation LXC (192.168.1.9)

> ← [Back to Project README](../README.md)

---

## Contents

- [Environment Overview](#environment-overview)
- [New LXC Container Spec](#new-lxc-container-spec)
- [Installation Steps](#installation-steps)
- [Configuration Files](#configuration-files)
- [Starting the Stack](#starting-the-stack)
- [Verification](#verification)
- [Useful Commands](#useful-commands)

---

## Environment Overview

### Proxmox Server 1 — Main Host

| Property | Value |
|---|---|
| Hostname | proxmox |
| IP | 192.168.1.2 |
| CPU | Intel Core i5-7500T @ 2.70 GHz (4 cores) |
| RAM | 16 GB DDR4-2400 |
| NVMe | 238.5 GB (Proxmox OS + pve-data LVM) |
| SATA SSD | 111.8 GB (`/mnt/sata-ssd` — Backups) |
| USB Drive | 238.5 GB (`/mnt/usbdrive` — Syncthing) |

### Proxmox Server 2 — NUC

| Property | Value |
|---|---|
| Hostname | proxmox2 |
| IP | 192.168.1.7 |
| CPU | Intel Celeron N2830 (2 cores) |
| RAM | 8 GB DDR3 |
| SSD | 128 GB SATA |

### Existing Containers & VMs

| VMID | Name | Type | Host | IP |
|---|---|---|---|---|
| 100 | cosmos | LXC | proxmox2 | — |
| 101 | adguard | LXC | proxmox | 192.168.1.3 |
| 102 | debian | LXC | proxmox | 192.168.1.5 |
| 201 | docker | VM | proxmox | 192.168.1.6 |

---

## New LXC Container Spec

| Setting | Value |
|---|---|
| VMID | 103 |
| Hostname | automation |
| IP | 192.168.1.9 (DHCP → static reservation) |
| MAC | bc:24:11:33:88:67 |
| Template | debian-12-standard_12.12-1_amd64.tar.zst |
| vCPU | 2 |
| RAM | 3072 MiB |
| Swap | 1024 MiB |
| Disk | 40 GB (local-lvm) |
| Features | nesting=1, keyctl=1 |
| Unprivileged | Yes |

---

## Installation Steps

### Step 1 — Download LXC Template

Run from the Proxmox host shell:

```bash
pveam download sata-ssd debian-12-standard_12.12-1_amd64.tar.zst
```

### Step 2 — Create the LXC Container

```bash
pct create 103 sata-ssd:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname automation \
  --cores 2 \
  --memory 3072 \
  --swap 1024 \
  --rootfs local-lvm:40 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1,keyctl=1 \
  --unprivileged 1 \
  --start 1
```

### Step 3 — Verify IP Assignment

```bash
pct exec 103 -- ip a
```

Note the assigned IP and create a static DHCP reservation in your router for MAC `bc:24:11:33:88:67` → `192.168.1.9`.

### Step 4 — Enter the Container

```bash
pct enter 103
```

### Step 5 — Update System & Install Prerequisites

```bash
apt update && apt upgrade -y && apt install -y \
  curl wget git nano htop \
  ca-certificates gnupg lsb-release \
  apt-transport-https software-properties-common
```

### Step 6 — Install Docker

```bash
# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker apt repository
echo \
  "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose plugin
apt update && apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

### Step 7 — Verify Docker Installation

```bash
docker --version
docker compose version
docker run hello-world
```

### Step 8 — Enable Docker on Boot

```bash
systemctl enable docker
```

### Step 9 — Create Directory Structure

```bash
mkdir -p /opt/automation/{n8n,postgres,redis,nginx,gitea,grafana,prometheus}
mkdir -p /opt/automation/nginx/{conf,certs}
mkdir -p /opt/automation/n8n/data
cd /opt/automation
```

### Step 10 — Fix n8n Data Folder Permissions

n8n runs as user `node` (UID 1000). The data folder must be owned by UID 1000 or n8n will fail to start.

```bash
chown -R 1000:1000 /opt/automation/n8n/data
```

---

## Configuration Files

### `.env` File

```bash
nano /opt/automation/.env
```

```env
# PostgreSQL
POSTGRES_USER=automation
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD
POSTGRES_DB=automation

# n8n
N8N_SECURE_COOKIE=false
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=YOUR_SECURE_PASSWORD
N8N_HOST=192.168.1.9
N8N_PORT=5678
WEBHOOK_URL=http://192.168.1.9:5678/

# Grafana
GRAFANA_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD

# Gitea
GITEA_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD
```

> ⚠️ Never commit this file. The `.env.example` version (with placeholder values) is committed instead.

---

### `prometheus/prometheus.yml`

```bash
nano /opt/automation/prometheus/prometheus.yml
```

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
    static_configs:
      - targets: ['host.docker.internal:9323']
```

> ⚠️ This file must exist before running `docker compose up`. Prometheus will fail to start if the config file is missing.

---

### `docker-compose.yml`

```bash
nano /opt/automation/docker-compose.yml
```

```yaml
services:

  postgres:
    image: postgres:16
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres:/var/lib/postgresql/data
    networks:
      - automation

  redis:
    image: redis:7-alpine
    container_name: redis
    restart: unless-stopped
    networks:
      - automation

  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_SECURE_COOKIE=false
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}
      - DB_POSTGRESDB_USER=${POSTGRES_USER}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - QUEUE_BULL_REDIS_HOST=redis
    volumes:
      - ./n8n/data:/home/node/.n8n
    depends_on:
      - postgres
      - redis
    networks:
      - automation

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer:/data
    networks:
      - automation

  gitea:
    image: gitea/gitea:latest
    container_name: gitea
    restart: unless-stopped
    ports:
      - "3000:3000"
      - "2222:22"
    volumes:
      - ./gitea:/data
    networks:
      - automation

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    networks:
      - automation

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
    networks:
      - automation

volumes:
  prometheus_data:
  grafana_data:

networks:
  automation:
    driver: bridge
```

---

## Starting the Stack

```bash
cd /opt/automation
docker compose up -d
```

---

## Verification

```bash
# Check all containers are running
docker compose ps

# Verify service URLs (from a browser on the same network)
# n8n          → http://192.168.1.9:5678
# Portainer    → http://192.168.1.9:9000
# Gitea        → http://192.168.1.9:3000
# Prometheus   → http://192.168.1.9:9090
# Grafana      → http://192.168.1.9:3001
```

Expected output of `docker compose ps` — all 7 containers with state `running`.

---

## Useful Commands

```bash
# Enter the LXC from the Proxmox host
pct enter 103

# Navigate to the project directory
cd /opt/automation

# Check status of all containers
docker compose ps

# View logs for a specific service (last 30 lines)
docker logs n8n --tail 30

# Follow logs in real time
docker logs -f n8n

# Restart a single service
docker compose restart n8n

# Full stack restart
docker compose down && docker compose up -d

# Check resource usage
docker stats
```

---

*See [troubleshooting.md](./troubleshooting.md) for issues encountered during setup.*  
*← [Back to Project README](../README.md)*
