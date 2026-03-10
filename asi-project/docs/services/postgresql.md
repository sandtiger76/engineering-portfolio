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
    - asi_postgresql:/var/lib/postgresql/data
  networks:
    - internal
```

The Alpine-based image is used for its smaller footprint — important on constrained hardware.

### Database Layout

| Database | Owner | Used By | Created By |
|---|---|---|---|
| nextcloud | nextcloud_user | Nextcloud application | Auto-created by Nextcloud container on first run |
| gitea | gitea_user | Gitea application | Manual — see post-deploy steps below |

### Important: Nextcloud DB is auto-created, Gitea DB is not

The Nextcloud container creates its own database automatically using the `POSTGRES_*` env vars.
The Gitea database must be created manually after PostgreSQL is running:

```bash
# Create Gitea database and user
docker exec -it postgresql psql -U postgres -c \
  "CREATE USER gitea WITH PASSWORD 'your_gitea_db_password';"
docker exec -it postgresql psql -U postgres -c \
  "CREATE DATABASE gitea OWNER gitea ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8' TEMPLATE template0;"
docker exec -it postgresql psql -U postgres -c \
  "GRANT ALL PRIVILEGES ON DATABASE gitea TO gitea;"
```

### Credential Separation

`POSTGRES_PASSWORD` in the compose file is the **superuser** password — used only by the
`postgres` admin user to create other databases. Application users (nextcloud_user, gitea)
are created separately with access only to their own database. This is the principle of
least privilege applied to database access.

### Ansible Role

Provisioned by: `ansible/roles/postgresql/`

The role handles:
- Starting the PostgreSQL container
- Waiting for the database to accept connections
- Creating the Gitea database and user (Nextcloud's DB is handled by the Nextcloud role)
- Setting appropriate permissions

---

## Backup

PostgreSQL data is backed up using `pg_dump` nightly via cron, stored to `/mnt/backup`,
and rotated to keep 7 days of history:

```bash
pg_dump -U nextcloud_user nextcloud | gzip > /mnt/backup/nextcloud_$(date +%Y%m%d).sql.gz
pg_dump -U gitea_user gitea | gzip > /mnt/backup/gitea_$(date +%Y%m%d).sql.gz
```

See [Backup & Disaster Recovery](../operations/backup-dr.md) for the full backup strategy.

---

## Gotchas & Notes

**PostgreSQL 15 pinned — not `latest`**
Prevents unexpected breaking changes during container updates.

**Locale on Alpine — use TEMPLATE template0**
`postgres:15-alpine` has a limited locale set. If `LC_COLLATE='en_US.utf8'` causes errors
during database creation, use this safe fallback:
```sql
CREATE DATABASE mydb OWNER myuser ENCODING 'UTF8' TEMPLATE template0;
```
This omits the explicit locale — defaults to the server locale which is typically `en_US.UTF-8`
on the Alpine image if `LANG` is set, or `C` if not. Verified working in this deployment.

**Never expose port 5432 to the host**
PostgreSQL is `internal` network only — no `ports:` mapping in the compose file.

**`community.docker` collection required for Ansible**
```bash
ansible-galaxy collection install community.docker
```

---

[Next: Nginx →](nginx.md)
