# Setup Guide

> ← [Back to README](../README.md)

This guide rebuilds the entire stack from scratch on a fresh Proxmox LXC container. Follow the steps in order.

> **Who this is for:** Anyone wanting to replicate this project on their own homelab. Commands are provided for every step. See [troubleshooting.md](troubleshooting.md) for issues encountered during the original build.

---

## Prerequisites

- Proxmox VE running on your homelab host
- A static DHCP reservation available for your chosen IP
- Debian 12 LXC template downloaded on Proxmox
- The project files from this repository cloned locally

---

## Step 1 — Create the LXC Container

Run from the Proxmox host shell:

```bash
# Download the Debian 12 template if not already present
pveam download local debian-12-standard_12.12-1_amd64.tar.zst

# Create the container
# Adjust VMID (103), storage names, and IP to suit your environment
pct create 103 local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname automation \
  --cores 2 \
  --memory 3072 \
  --swap 1024 \
  --rootfs local-lvm:40 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1,keyctl=1 \
  --unprivileged 1 \
  --start 1

# Verify IP assignment
pct exec 103 -- ip a
```

Create a static DHCP reservation in your router for the container's MAC address → `YOUR_HOMELAB_IP`.

> ⚠️ The `--features nesting=1,keyctl=1` flags are **required** for Docker to run inside an LXC container. Omitting them will cause Docker to start but fail silently when running containers. See [troubleshooting.md](troubleshooting.md) for detail.

---

## Step 2 — Configure the Container

```bash
# Enter the container
pct enter 103

# Update and install prerequisites
apt update && apt upgrade -y && apt install -y \
  curl wget git nano htop \
  ca-certificates gnupg lsb-release \
  apt-transport-https software-properties-common

# Set timezone to your local timezone
timedatectl set-timezone Europe/Your_Timezone
```

---

## Step 3 — Install Docker

```bash
# Add Docker's GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository
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

# Verify
docker --version
docker compose version

# Enable Docker on boot
systemctl enable docker
```

---

## Step 4 — Create Directory Structure

```bash
mkdir -p /opt/automation/{n8n,postgres,redis,nginx,gitea,grafana,prometheus,jobhunt-api}
mkdir -p /opt/automation/nginx/{conf,certs}
mkdir -p /opt/automation/n8n/data

# Fix n8n data folder permissions
# n8n runs as user 'node' (UID 1000) — the folder must be owned by UID 1000
chown -R 1000:1000 /opt/automation/n8n/data
```

> ⚠️ The `chown` step is easy to forget and causes a permission error on first n8n startup. See [troubleshooting.md](troubleshooting.md).

---

## Step 5 — Create Configuration Files

### `.env`

```bash
nano /opt/automation/.env
```

```env
# PostgreSQL
POSTGRES_USER=automation
POSTGRES_PASSWORD=CHANGE_ME
POSTGRES_DB=automation

# n8n
N8N_SECURE_COOKIE=false
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=CHANGE_ME
N8N_HOST=YOUR_HOMELAB_IP
N8N_PORT=5678
WEBHOOK_URL=http://YOUR_HOMELAB_IP:5678/
GENERIC_TIMEZONE=Europe/Your_Timezone

# Grafana
GRAFANA_ADMIN_PASSWORD=CHANGE_ME

# Gitea
GITEA_ADMIN_PASSWORD=CHANGE_ME

# JobHunt API
JOBHUNT_DB_PASSWORD=CHANGE_ME
```

> ⚠️ Replace all `CHANGE_ME` values with strong passwords before starting the stack. Never commit this file to Git — use `.env.example` as the committed template.

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

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
```

> ⚠️ This file must exist before running `docker compose up`. Prometheus will fail to start without it.

---

## Step 6 — Deploy Application Files

Copy the application files to the server:

```bash
# From your local machine
scp server.js root@YOUR_HOMELAB_IP:/opt/automation/jobhunt-api/
scp portal.html root@YOUR_HOMELAB_IP:/opt/automation/jobhunt-api/
scp package.json root@YOUR_HOMELAB_IP:/opt/automation/jobhunt-api/
scp schema.sql root@YOUR_HOMELAB_IP:/opt/automation/jobhunt-api/
scp docker-compose.yml root@YOUR_HOMELAB_IP:/opt/automation/
```

---

## Step 7 — Start the Stack

```bash
cd /opt/automation

# Validate the compose file before starting
docker compose config --quiet && echo "YAML OK"

# Start all containers
docker compose up -d

# Verify all containers are running
docker compose ps
```

Expected — all containers showing state `running`:

```
NAME            STATUS
cadvisor        running
gitea           running
grafana         running
jobhunt-api     running
n8n             running
portainer       running
postgres        running
prometheus      running
redis           running
```

> If `jobhunt-api` shows `Restarting` for 10–15 seconds, that's normal — the container runs `npm install` on startup. Check logs after it settles: `docker compose logs jobhunt-api --tail 20`

---

## Step 8 — Create the jobhunt Database

```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U automation -d automation

# Create the jobhunt database
CREATE DATABASE jobhunt;
\q
```

Apply the schema:

```bash
docker cp /opt/automation/jobhunt-api/schema.sql postgres:/tmp/schema.sql
docker exec -it postgres psql -U automation -d jobhunt -f /tmp/schema.sql
```

Verify:

```bash
# Should show 5 tables (jobs, job_status, scrape_log, sources, tags + job_tags)
docker exec -it postgres psql -U automation -d jobhunt -c "\dt"

# Should show 1 view (v_jobs)
docker exec -it postgres psql -U automation -d jobhunt -c "\dv"
```

---

## Step 9 — Verify the Portal

```bash
curl http://YOUR_HOMELAB_IP:3099/health
# Expected: {"status":"ok","jobs":0}
```

Open in a browser: `http://YOUR_HOMELAB_IP:3099`

On first visit, click **⚙ Config** and set:
- API Base URL: `http://YOUR_HOMELAB_IP:3099`
- API Key: leave blank

---

## Step 10 — Configure n8n

Open n8n at `http://YOUR_HOMELAB_IP:5678`

**Create the Postgres credential:**
- Host: `postgres`
- Port: `5432`
- Database: `jobhunt`
- User: `automation`
- Password: your `JOBHUNT_DB_PASSWORD` from `.env`
- SSL: disabled

**Import workflows:**
For each JSON workflow file in the `n8n-workflows/` directory:
1. Click the three-dot menu → Import
2. Select the JSON file
3. Update the Postgres credential to use the one you just created
4. Click Publish to activate

---

## Step 11 — Run First Scrape

Trigger each scraper workflow manually in n8n to populate the database for the first time. After all scrapers have run, trigger the Job Classifier manually.

Verify data:

```bash
docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT source, COUNT(*) FROM jobs GROUP BY source ORDER BY source;"

docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT status, COUNT(*) FROM job_status GROUP BY status;"
```

---

## Verification Checklist

```bash
# All containers running
docker compose ps

# Portal responding
curl http://YOUR_HOMELAB_IP:3099/health

# Jobs in database
docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT COUNT(*) FROM jobs;"

# n8n accessible
curl -s -o /dev/null -w "%{http_code}" http://YOUR_HOMELAB_IP:5678
# Expected: 200
```

---

## Quick Reference

```bash
# Enter LXC from Proxmox host
pct enter 103

# Navigate to stack
cd /opt/automation

# Container status
docker compose ps

# View logs
docker compose logs [service] --tail 30
docker compose logs -f [service]    # follow live

# Restart a service
docker compose restart [service]

# Full stack restart
docker compose down && docker compose up -d

# Resource usage
docker stats

# Database connection
docker exec -it postgres psql -U automation -d jobhunt

# Job counts by status
docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT status, COUNT(*) FROM v_jobs GROUP BY status;"
```

---

*← [Back to README](../README.md) | See [troubleshooting.md](troubleshooting.md) for issues encountered during the original build.*
