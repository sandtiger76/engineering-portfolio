# Gitea

[← Back to README](../../README.md) | [← Uptime Kuma](uptime-kuma.md)

---

## What Is It?

Gitea is a lightweight, self-hosted Git platform. It provides the same core functionality as GitHub or GitLab — code repositories, version history, issues, pull requests, and a web interface — but runs entirely on your own hardware.

Git is the version control system used by virtually every software and infrastructure team in the world. Hosting your own Git platform demonstrates that you understand and value version control as a discipline, not just as a tool.

**Why it's in this project:** The Ansible code that builds this entire platform is stored in Gitea. This is called "dogfooding" — using your own infrastructure to host itself. It means the platform is self-contained, self-referential, and a genuine demonstration of the technology.

---

## Why We Need It

Every infrastructure change in this project goes through Git. That means:
- A full history of every change made to the infrastructure
- The ability to roll back to any previous configuration
- A clear record of what changed, when, and why

Hosting this on Gitea rather than GitHub also means the code is version-controlled on the same platform it describes — the infrastructure literally hosts its own source of truth.

**Access:** Public via `https://gitea.qcbhomelab.online` — browse the repository without an account.

---

## Technical Implementation

```yaml
gitea:
  image: gitea/gitea:latest
  container_name: gitea
  restart: unless-stopped
  environment:
    - USER_UID=1000
    - USER_GID=1000
    - GITEA__database__DB_TYPE=postgres
    - GITEA__database__HOST=postgresql:5432
    - GITEA__database__NAME=gitea
    - GITEA__database__USER=${GITEA_DB_USER}
    - GITEA__database__PASSWD=${GITEA_DB_PASSWORD}
  volumes:
    - gitea_data:/data
  networks:
    - internal
    - proxy
```

### Ansible Role

Provisioned by: `ansible/roles/gitea/`

The role handles:
- Starting the Gitea container
- Waiting for the service to be ready
- Creating the initial admin user via the Gitea API
- Creating the `asi-platform` repository

---

## Gotchas & Notes

- Gitea's first-run installer must be completed or bypassed via environment variables — the Ansible role handles this via app.ini configuration
- The admin user must be created before the API is available — the role uses a retry loop with a wait condition
- SSH access to Gitea (for `git clone` via SSH) requires an additional port — this is intentionally disabled in this deployment in favour of HTTPS clone only, keeping the no-open-ports principle intact

---

[Next: Cloudflare DDNS →](cloudflare-ddns.md)
