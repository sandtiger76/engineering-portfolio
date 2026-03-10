# Nextcloud

[← Back to README](../../README.md) | [← Security Overview](../SECURITY.md)

---

## What Is It?

Nextcloud is an open-source, self-hosted collaboration platform. Think of it as your own private version of Microsoft SharePoint, OneDrive, or Google Drive — but running on your own hardware, with no subscription fee, and with full control over your data.

It provides file storage and sync, calendar, contacts, document editing, and more. It is used by organisations worldwide including universities, governments, and businesses that need to keep data on-premises for compliance or cost reasons.

**Why it's in this project:** Nextcloud is a realistic, enterprise-adjacent application. Deploying it correctly — with a proper database, reverse proxy, SSL, and automated backups — demonstrates real infrastructure competency, not just running a hello-world container.

---

## Why We Need It

In this project, Nextcloud serves as the headline application — the tangible thing the infrastructure exists to support. It is publicly accessible at `nextcloud.qcbhomelab.online`, meaning anyone can see a live running service, not just code in a repository.

It also creates real operational requirements: database management, backup procedures, certificate renewal, and performance tuning on constrained hardware. These are exactly the challenges that exist in production environments.

---

## Technical Implementation

### Container Configuration

Nextcloud runs as a Docker container alongside PostgreSQL and Redis. It connects to PostgreSQL for data storage and Redis for file locking and caching — the database is never exposed outside the container network.

```yaml
nextcloud:
  image: nextcloud:latest
  container_name: nextcloud
  restart: unless-stopped
  environment:
    - POSTGRES_HOST=postgresql
    - POSTGRES_DB=nextcloud
    - POSTGRES_USER=${NEXTCLOUD_DB_USER}
    - POSTGRES_PASSWORD=${NEXTCLOUD_DB_PASSWORD}
    - NEXTCLOUD_ADMIN_USER=${NEXTCLOUD_ADMIN_USER}
    - NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
    - NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.qcbhomelab.online
    - REDIS_HOST=redis
    - OVERWRITEPROTOCOL=https
    - OVERWRITECLIURL=https://nextcloud.qcbhomelab.online
    - OVERWRITEHOST=nextcloud.qcbhomelab.online
    - TRUSTED_PROXIES=172.20.0.0/16
    - PHP_MEMORY_LIMIT=512M
    - PHP_UPLOAD_LIMIT=512M
  volumes:
    - asi_nextcloud:/var/www/html
  networks:
    - internal
    - proxy
  depends_on:
    - postgresql
    - redis
```

### Important: Credential Behaviour

`NEXTCLOUD_ADMIN_USER` and `NEXTCLOUD_ADMIN_PASSWORD` are **write-once** — they only apply during the very first installation. After that, `config.php` inside the volume is the source of truth. To change the admin password post-install:

```bash
docker exec -u www-data nextcloud php occ user:resetpassword admin
```

### Networking

Nextcloud is on two Docker networks:
- `internal` — communicates with PostgreSQL and Redis
- `proxy` — receives traffic from Nginx

The `proxy` network is declared `external: true` in the compose file — it must exist before
`docker compose up`. Create it once with:

```bash
docker network create proxy
```

### Trusted Proxies

Nextcloud must be told which IP ranges to trust as reverse proxies. The `TRUSTED_PROXIES`
env var must match the actual Docker bridge subnet for the `proxy` network:

```bash
# Check actual subnet
docker network inspect proxy | grep Subnet
# Update .env accordingly — default is usually 172.20.0.0/16
```

### Performance on Constrained Hardware

The Intel NUC Celeron N2820 is limited. Nextcloud is tuned accordingly:
- PHP memory limit: 512MB
- Redis for file locking — critical on low-memory systems to prevent WebDAV corruption
- APCu for local caching
- Preview generation disabled (CPU-intensive, poor experience on this hardware):

```bash
docker exec -u www-data nextcloud php occ config:system:set enable_previews --value=false --type=bool
```

First boot takes 3–8 minutes on this hardware — normal behaviour, not a failure.

### Post-Deployment Steps

After `docker compose up -d`, several steps must be completed. See [Post-Deployment Commands](../../3_Nextcloud_PostgreSQL_Deployment/post-deploy.md) for the full procedure. Key steps:

```bash
# Verify Nextcloud is ready
docker exec -u www-data nextcloud php occ status

# Add missing database indices (always needed after fresh install)
docker exec -u www-data nextcloud php occ db:add-missing-indices
docker exec -u www-data nextcloud php occ db:add-missing-columns
docker exec -u www-data nextcloud php occ db:add-missing-primary-keys

# Switch background jobs to system cron
docker exec -u www-data nextcloud php occ background:cron

# Add host cron entry
echo "*/5 * * * * docker exec -u www-data nextcloud php -f /var/www/html/cron.php" | crontab -
```

> **Always run occ as www-data** — running as root causes permission issues and incorrect output.

### Ansible Role

Provisioned by: `ansible/roles/nextcloud/`

Requires: `ansible-galaxy collection install community.docker`

---

## Accessing Nextcloud

| Method | URL |
|---|---|
| Public browser | https://nextcloud.qcbhomelab.online |
| Admin panel | https://nextcloud.qcbhomelab.online/settings/admin |

---

## Gotchas & Notes

All issues below were encountered during the actual build.

**Redirect loops / mixed content**
Nextcloud generates `http://` URLs internally unless told otherwise. `OVERWRITEPROTOCOL=https`
is mandatory behind a reverse proxy. Without it: redirect loops, CalDAV/CardDAV failures,
browser mixed content warnings.

**Untrusted domain error**
`NEXTCLOUD_TRUSTED_DOMAINS` must match exactly what the browser sends in the `Host` header —
no trailing slash, no port unless non-standard.

**PostgreSQL locale on Alpine**
`postgres:15-alpine` has a limited locale set. `LC_COLLATE='en_US.utf8'` in CREATE DATABASE
may fail. Safe fallback:
```sql
CREATE DATABASE nextcloud OWNER nextcloud ENCODING 'UTF8' TEMPLATE template0;
```

**Redis locking — both keys required**
`REDIS_HOST` env var sets up the connection but may not set `memcache.locking` and
`memcache.distributed` in all image versions. Verify after deploy:
```bash
docker exec -u www-data nextcloud php occ config:system:get memcache.locking
# Should return: \OC\Memcache\Redis
```

**WebDAV / CalDAV / CardDAV — .well-known redirects required**
Desktop and mobile sync clients require these Nginx redirects or they silently fail:
```nginx
location /.well-known/carddav { return 301 $scheme://$host/remote.php/dav; }
location /.well-known/caldav  { return 301 $scheme://$host/remote.php/dav; }
```

**Missing database indices**
Nextcloud always reports missing indices after a fresh install. Run the `db:add-missing-*`
occ commands as part of every deployment — handled automatically by the Ansible role.

---

[Next: PostgreSQL →](postgresql.md)
