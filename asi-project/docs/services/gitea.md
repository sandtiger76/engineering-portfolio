# Gitea

[← Back to README](../../README.md) | [← Uptime Kuma](uptime-kuma.md)

---

## What Is It?

Gitea is a lightweight, self-hosted Git platform. It provides the same core functionality as GitHub or GitLab — code repositories, version history, issues, pull requests, and a web interface — but runs entirely on your own hardware.

Git is the version control system used by virtually every software and infrastructure team in the world. Hosting your own Git platform demonstrates that you understand and value version control as a discipline, not just as a tool.

**Why it's in this project:** The Ansible code that builds this entire platform is stored in Gitea. This is called "dogfooding" — using your own infrastructure to host itself. The platform is self-contained and self-referential — it hosts its own source of truth.

---

## Why We Need It

Every infrastructure change in this project goes through Git — a full history of every change, the ability to roll back, and a clear record of what changed, when, and why. Hosting this on Gitea rather than GitHub means the code lives on the same platform it describes.

**Access:** Public via `https://gitea.qcbhomelab.online` — browse without an account. Registration is disabled — accounts are admin-created only.

---

## Technical Implementation

### Container Configuration

```yaml
gitea:
  image: gitea/gitea:latest
  container_name: gitea
  restart: unless-stopped
  environment:
    - GITEA__database__DB_TYPE=postgres
    - GITEA__database__HOST=postgresql:5432
    - GITEA__database__NAME=${GITEA_DB_NAME}
    - GITEA__database__USER=${GITEA_DB_USER}
    - GITEA__database__PASSWD=${GITEA_DB_PASSWORD}
    - GITEA__server__DISABLE_SSH=true
    - GITEA__server__START_SSH_SERVER=false
    - GITEA__security__INSTALL_LOCK=true
    - GITEA__service__DISABLE_REGISTRATION=true
    - GITEA__service__REQUIRE_SIGNIN_VIEW=true
  volumes:
    - ./data/gitea:/data
  networks:
    - internal
    - proxy
  depends_on:
    postgresql:
      condition: service_healthy
```

### Database Setup

The Gitea database and user must be created before starting the container. The PostgreSQL superuser in this deployment is `nextcloud` with default database `nextcloud_db` — specify both explicitly:

```bash
# Create Gitea user
docker exec -i postgresql psql -U nextcloud -d nextcloud_db \
  -c "CREATE USER gitea_user WITH PASSWORD 'your_password';"

# Create Gitea database
docker exec -i postgresql psql -U nextcloud -d nextcloud_db \
  -c "CREATE DATABASE gitea OWNER gitea_user;"
```

> **Gotcha:** Running `psql -U nextcloud` without `-d nextcloud_db` fails with "database nextcloud does not exist" — the default database name is `nextcloud_db`, not `nextcloud`.

### Security Configuration

| Setting | Value | Purpose |
|---|---|---|
| `DISABLE_SSH` | true | No SSH git clone — HTTPS only |
| `START_SSH_SERVER` | false | Don't start built-in SSH server |
| `INSTALL_LOCK` | true | Skip interactive web installer |
| `DISABLE_REGISTRATION` | true | Admin-created accounts only |
| `REQUIRE_SIGNIN_VIEW` | true | No anonymous browsing |

### Admin User Creation

```bash
docker exec -u git gitea gitea admin user create \
  --username admin \
  --email admin@qcbhomelab.online \
  --password 'your_strong_password' \
  --admin \
  --must-change-password=false
```

### Repository Creation via API

```bash
curl -X POST "https://gitea.qcbhomelab.online/api/v1/user/repos" \
  -u "admin:your_password" \
  -H "Content-Type: application/json" \
  -d '{"name":"asi-platform","private":true,"auto_init":true,"default_branch":"main"}'
```

### Ansible Role

Provisioned by: `ansible/roles/gitea/`

The role handles: creating the database and user, deploying the container, waiting for health, creating the admin user, and creating the initial repository.

> **Idempotency warning:** The Gitea API does not prevent duplicate token names. Running the Ansible role twice creates a second token with the same name. Add a check or delete old tokens before creating new ones.

---

## Gotchas & Notes

**SQLite init must be wiped before switching to PostgreSQL**
If Gitea starts even once without the correct database env vars, it writes `app.ini` with SQLite. Switching to PostgreSQL requires deleting the data directory and restarting fresh — the env vars only apply to settings not yet written to `app.ini`:
```bash
docker compose stop gitea && docker compose rm -f gitea
rm -rf /opt/asi-platform/data/gitea
docker compose up -d gitea
```

**PostgreSQL connection — specify the correct default database**
The PostgreSQL superuser is `nextcloud` but the default database is `nextcloud_db`. Always use `-d nextcloud_db` when connecting as the superuser, otherwise psql fails with "database nextcloud does not exist".

**SSH daemon in container is not Gitea's SSH**
Even with `DISABLE_SSH=true`, the container OS runs its own OpenSSH daemon on port 22. This is not Gitea's built-in SSH server — it is not exposed to the host (no `ports:` mapping) and not accessible externally.

**API auth required even for version endpoint**
With `REQUIRE_SIGNIN_VIEW=true` enabled, even `/api/v1/version` returns 403 for unauthenticated requests. Always pass credentials with API calls.

**`INSTALL_LOCK=true` is mandatory**
Without this, Gitea shows an interactive web installer on first visit. Any visitor could configure the instance before you do. Always set `INSTALL_LOCK=true` in the env vars.

---

[Next: Cloudflare DDNS →](cloudflare-ddns.md)
