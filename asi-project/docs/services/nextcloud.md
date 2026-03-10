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

Nextcloud runs as a Docker container, defined in `docker-compose.yml`. It connects to a PostgreSQL database container on an internal Docker network — the database is never exposed outside the container network.

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
  volumes:
    - nextcloud_data:/var/www/html
  networks:
    - internal
    - proxy
  depends_on:
    - postgresql
```

### Networking

Nextcloud is on two Docker networks:
- `internal` — to communicate with PostgreSQL and Redis
- `proxy` — to receive traffic from Nginx

It has no direct exposure to the host network or the internet.

### Performance Considerations

The Intel NUC Celeron N2820 is limited hardware. Nextcloud is configured with:
- PHP memory limit set to 512MB
- APCu for local caching
- Redis container for file locking (prevents database contention)
- Data storage is not the focus — this is a platform demonstration, not a data hosting service

### Ansible Role

Provisioned by: `ansible/roles/nextcloud/`

The role handles:
- Creating required Docker volumes
- Deploying the compose configuration
- Waiting for the container to be healthy before proceeding
- Running the initial Nextcloud setup via `occ` commands

---

## Accessing Nextcloud

| Method | URL |
|---|---|
| Public browser | https://nextcloud.qcbhomelab.online |
| Admin panel | https://nextcloud.qcbhomelab.online/settings/admin |

---

## Gotchas & Notes

- Nextcloud's first-run setup can take 2-3 minutes on low-end hardware — the Ansible role includes a wait condition
- The `NEXTCLOUD_TRUSTED_DOMAINS` variable must match your domain exactly or you will receive a 403 error
- Nextcloud generates a `config.php` on first run — some settings must be applied via the `occ` command-line tool after startup rather than via environment variables

---

[Next: PostgreSQL →](postgresql.md)
