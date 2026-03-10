# Ansible — Project Structure & Vault

[← Back to README](../../README.md) | [← SSL Certificate Setup](ssl-certificates.md)

---

## What Is It?

Ansible is an open-source automation tool that manages infrastructure configuration through declarative YAML files called playbooks. It connects to servers over SSH, executes tasks in order, and ensures the system reaches a defined state — regardless of what state it started in.

Ansible Vault is Ansible's built-in secrets management system. It encrypts sensitive values (passwords, API tokens, auth keys) so they can be safely stored in version control alongside the rest of the infrastructure code.

**Why it's in this project:** Every manual step in this build is codified as an Ansible role. The entire platform can be rebuilt from scratch on a fresh LXC by running a single command. This is the difference between a homelab and infrastructure-as-code.

---

## Project Structure

```
ansible/
├── ansible.cfg                    # remote_user=root, pipelining, inventory path
├── .gitignore                     # protects vault.yml from git
├── site.yml                       # master playbook (2 plays)
├── inventory/
│   └── hosts.yml                  # localhost + asi_platform group
├── group_vars/
│   └── all/
│       ├── vars.yml               # all non-sensitive variables
│       └── vault.yml.example      # template — copy, fill, encrypt
└── roles/
    ├── proxmox_lxc/               # Proxmox API, TUN config, wait for SSH
    ├── security/                  # UFW + fail2ban
    ├── docker/                    # Docker CE, networks, /opt/asi-platform tree
    ├── ssl/                       # certbot + Cloudflare DNS-01 wildcard cert
    ├── postgresql/                # docker-compose.yml template + .env
    ├── nextcloud/                 # container start + occ post-config
    ├── gitea/                     # container start + admin user + repo
    ├── nginx/                     # vhost configs + container start
    ├── portainer/                 # management UI (9000/9443)
    ├── uptime_kuma/               # monitoring (3001)
    ├── cloudflare_ddns/           # DDNS container
    ├── tailscale/                 # install + idempotent auth
    └── backup/                    # daily pg_dump + tar cron job
```

13 roles covering the full stack. Each role is independently runnable via tags.

---

## Role Execution Order

The order is deliberate — each role depends on the one before it:

| # | Role | Reason |
|---|---|---|
| 1 | `proxmox_lxc` | Creates LXC before anything else — runs on localhost via Proxmox API |
| 2 | `security` | UFW + fail2ban before opening ports or installing services |
| 3 | `docker` | Required by all container roles |
| 4 | `ssl` | Cert must exist before Nginx can serve HTTPS |
| 5 | `postgresql` | Deploys docker-compose.yml — DB must be up before apps start |
| 6 | `nextcloud` | Depends on postgresql + redis |
| 7 | `gitea` | Depends on postgresql |
| 8 | `nginx` | Proxies Nextcloud + Gitea — they must be up first |
| 9 | `portainer` | Independent — Docker management UI |
| 10 | `uptime_kuma` | Independent — monitoring |
| 11 | `cloudflare_ddns` | Independent — DDNS updates |
| 12 | `tailscale` | Independent — run last, non-critical path |
| 13 | `backup` | Cron jobs — run last |

---

## Architecture Decisions

**Single docker-compose.yml for all services** — the `postgresql` role deploys a master `docker-compose.yml.j2` template defining all services. Each subsequent role uses `docker_compose_v2` with `services: [service_name]` to start only its own containers. One compose file is easier to maintain and Docker understands the full dependency graph.

**Two plays in site.yml** — Play 1 runs on `localhost` (Proxmox API calls to create the LXC). Play 2 runs on `asi_platform` (SSH into the LXC to deploy services). This split is necessary because the Proxmox API is called from the laptop, not from inside the container.

**TUN device via delegate_to** — the `proxmox_lxc` role adds TUN device lines to `/etc/pve/lxc/100.conf` on `proxmox2` using `delegate_to: proxmox2`. This happens before starting the container so Tailscale works on first boot.

**.env file from vault template** — all Docker Compose secrets are injected via `.env` (mode 0600, root:root), generated from `roles/postgresql/templates/env.j2` with vault variables substituted at deploy time.

---

## Setup

### Install Ansible

```bash
# pip — recommended (gets latest version)
pip3 install --user ansible
ansible --version
```

### Install required collections

```bash
ansible-galaxy collection install community.general community.docker community.proxmox
```

Collections used in this project: `community.general` (proxmox module, ufw, locale_gen), `community.docker` (docker_compose_v2, docker_container_exec), `ansible.builtin` (everything else).

### Vault setup

```bash
cd ansible/
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
nano group_vars/all/vault.yml   # fill in all CHANGEME values
ansible-vault encrypt group_vars/all/vault.yml
```

To edit later: `ansible-vault edit group_vars/all/vault.yml`

### Vault secrets required

```yaml
vault_proxmox_api_token_secret: ""
vault_cloudflare_api_token: ""
vault_tailscale_auth_key: ""
vault_postgres_root_password: ""
vault_nextcloud_db_password: ""
vault_nextcloud_admin_password: ""
vault_gitea_db_password: ""
vault_gitea_admin_password: ""
vault_admin_email: ""
```

---

## Running the Playbook

```bash
# Always dry-run first
ansible-playbook site.yml --ask-vault-pass --check

# Full deployment (fresh LXC)
ansible-playbook site.yml --ask-vault-pass

# LXC already exists — skip provisioning
ansible-playbook site.yml --ask-vault-pass --skip-tags proxmox_lxc

# Single role
ansible-playbook site.yml --ask-vault-pass --tags nginx

# Multiple roles
ansible-playbook site.yml --ask-vault-pass --tags "ssl,nginx"

# Specific host
ansible-playbook site.yml --ask-vault-pass --limit asi-platform --tags nginx
```

### Useful ad-hoc commands

```bash
ansible asi_platform -m ping
ansible asi_platform -m command -a "docker ps"
```

---

## Manual Prerequisites

Two steps that cannot be fully automated on a fresh LXC:

**1. Proxmox TUN device for Tailscale**

`pct set --features tun=1` does not work on Proxmox 6.17+ (removed from schema). The `proxmox_lxc` role handles this via `delegate_to`. If skipping LXC creation, add manually on proxmox2:

```bash
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> /etc/pve/lxc/100.conf
echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >> /etc/pve/lxc/100.conf
pct restart 100
```

**2. Portainer and Uptime Kuma first-run setup**

No CLI pre-authentication is available for either service. After the playbook runs, visit within 5 minutes of first start:

- Portainer: `http://192.168.1.11:9000` (via Tailscale or LAN)
- Uptime Kuma: `http://192.168.1.11:3001` (via Tailscale or LAN)

Both services auto-lock after a timeout if no admin account is created.

---

## Gotchas & Notes

**`community.general.proxmox` is deprecated**
Use `community.proxmox.proxmox` from the separate `community.proxmox` collection. Install with `ansible-galaxy collection install community.proxmox`.

**`trusted_proxies` subnet may differ on rebuild**
The `proxy` Docker network subnet (`172.19.0.0/16` on this deployment) is assigned dynamically. On a fresh deploy verify with `docker network inspect proxy | grep Subnet` and update `trusted_proxies` in `group_vars/all/vars.yml` if needed, then re-run `--tags nextcloud`.

**`--check` mode fails on dependent tasks**
Dry-run mode fails on tasks that depend on previous tasks' results — for example, the `nextcloud` role tries to run `docker exec` on a container that doesn't exist yet in check mode. This is expected. Use `--check` on individual roles against a live system rather than a full check on a fresh LXC.

**Gitea API token idempotency**
The Gitea role creates a temporary token named `ansible-setup` for repository creation. If a re-run fails on this step, delete the token manually:
```bash
curl -X DELETE https://gitea.qcbhomelab.online/api/v1/users/admin/tokens/ansible-setup \
  -u admin:yourpassword
```

**Nextcloud `occ` always exits 0**
The `occ config:system:set` tasks use `changed_when` to detect whether the value was actually changed. This ensures idempotent runs correctly report `ok` instead of `changed`.

**Vault password — no recovery**
If the vault password is lost, `vault.yml` is permanently unreadable. Store it in a password manager. Optionally configure a vault password file to avoid typing it each run:
```bash
echo "your-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass
# Uncomment in ansible.cfg: vault_password_file = ~/.vault_pass
```

**`.gitignore` protects vault.yml**
The `ansible/.gitignore` excludes `vault.yml` from git. Never commit the unencrypted vault file — only commit `vault.yml.example` or the encrypted version.

---

## Post-Deployment Verification

```bash
# From laptop
curl -I https://nextcloud.qcbhomelab.online    # HTTP 302 → /login
curl -I https://gitea.qcbhomelab.online        # HTTP 200

# From LXC
docker ps                   # all containers Up
tailscale status            # asi-platform connected
ufw status verbose          # rules enabled
```

---

[← Back to README](../../README.md)
