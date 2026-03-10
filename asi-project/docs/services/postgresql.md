# PostgreSQL

[← Back to README](../../README.md) | [← Nextcloud](nextcloud.md)

---

## What Is It?

PostgreSQL (often called "Postgres") is one of the world's most widely used open-source relational databases. It stores structured data — think spreadsheets, but far more powerful, designed for applications to read and write data at high speed and scale.

It is used by companies of all sizes, from startups to Fortune 500 organisations. If you have ever used a web application that stores user accounts, files, or settings, it almost certainly has a database like PostgreSQL running behind it.

**Why it's in this project:** The default Nextcloud installation uses SQLite — a simple file-based database that is not suitable for production use. Using PostgreSQL instead is the first decision that signals production-grade thinking.

---

## Why We Need It

Two services in this platform require a database:

- **Nextcloud** — stores user accounts, file metadata, sharing permissions, calendar data
- **Gitea** — stores repositories, users, issues, pull requests

Running a single PostgreSQL instance for both, rather than two separate databases or SQLite files, is the efficient and maintainable approach. It also means database backups, monitoring, and maintenance are centralised in one place.

---

## Technical Implementation

### Container Configuration

PostgreSQL runs as a Docker container on the `internal` network only. It has no exposure to the host or internet — only the Nextcloud and Gitea containers can reach it.

```yaml
postgresql:
  image: postgres:15-alpine
  container_name: postgresql
  restart: unless-stopped
  environment:
    - POSTGRES_PASSWORD=${POSTGRES_ROOT_PASSWORD}
  volumes:
    - postgresql_data:/var/lib/postgresql/data
  networks:
    - internal
```

The Alpine-based image is used for its smaller footprint — important on constrained hardware.

### Database Layout

| Database | Owner | Used By |
|---|---|---|
| nextcloud | nextcloud_user | Nextcloud application |
| gitea | gitea_user | Gitea application |

### Initialisation

Database creation and user provisioning is handled by the Ansible role on first deployment. Subsequent runs skip this step (idempotent).

### Ansible Role

Provisioned by: `ansible/roles/postgresql/`

The role handles:
- Starting the PostgreSQL container
- Waiting for the database to accept connections
- Creating application databases and users
- Setting appropriate permissions

---

## Backup

PostgreSQL data is backed up using `pg_dump` — the standard PostgreSQL backup utility. Backups run nightly via a cron job, stored to the secondary drive (`/mnt/backup`), and rotated to keep 7 days of history.

```bash
# Backup command (run via cron, managed by Ansible)
pg_dump -U nextcloud_user nextcloud > /mnt/backup/nextcloud_$(date +%Y%m%d).sql
pg_dump -U gitea_user gitea > /mnt/backup/gitea_$(date +%Y%m%d).sql
```

See [Backup & Disaster Recovery](../operations/backup-dr.md) for the full backup strategy.

---

## Gotchas & Notes

- PostgreSQL 15 is pinned rather than using `latest` — prevents unexpected breaking changes during container updates
- The `POSTGRES_PASSWORD` in the compose file is the superuser password — application users are created separately with least-privilege access
- Never expose the PostgreSQL port (5432) to the host network — it is internal only

---

[Next: Nginx →](nginx.md)
