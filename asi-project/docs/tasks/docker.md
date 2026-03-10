# Docker Installation

[← Back to README](../../README.md) | [← Proxmox LXC Setup](proxmox-lxc.md)

---

## What Is It?

Docker is a containerisation platform that packages applications and their dependencies into isolated, portable units called containers. Instead of installing software directly on a server — with all the version conflicts and configuration drift that entails — Docker runs each service in its own self-contained environment.

**Why it's in this project:** Docker is the foundation that all services in this platform run on. It is the industry standard for application deployment and is a core skill expected in DevOps, cloud, and infrastructure roles.

---

## Why We Need It

Without Docker, installing Nextcloud, PostgreSQL, Nginx, Gitea and the other services would mean managing conflicting dependencies, different configuration file locations, and manual update procedures for each service. Docker makes each service declarative, portable, and independently manageable.

Docker Compose extends this by defining all services together in a single `docker-compose.yml` file — making the entire stack deployable in one command.

---

## Technical Implementation

### Versions Installed

| Package | Version |
|---|---|
| Docker CE | 29.3.0 |
| Docker Compose plugin | v5.1.0 |

Docker is installed from the official Docker apt repository — not the Debian package manager version, which is significantly out of date.

### Service User

A dedicated non-root user `appuser` (uid 1001) owns and runs all application services. This follows the principle of least privilege — no service runs as root.

```bash
useradd -m -s /bin/bash -u 1001 appuser
usermod -aG docker appuser
```

> **Note:** Do not use the `-r` (system account) flag with uid 1001. On Debian, system accounts are ≤ uid 999 — combining `-r` with uid 1001 produces a warning and is contradictory. The Ansible role omits `system: true` for this reason.

### Docker Network Layout

Two dedicated networks isolate traffic between services:

| Network | Purpose | Services |
|---|---|---|
| `internal` | Backend communication | PostgreSQL, all app containers |
| `proxy` | Nginx routing | Nginx, Nextcloud, Gitea |

No container except Nginx has ports exposed to the host.

### Named Volumes

Persistent data is stored in Docker named volumes — not bind mounts — ensuring data survives container rebuilds:

| Volume | Used By |
|---|---|
| `asi_nextcloud` | Nextcloud application data |
| `asi_postgresql` | PostgreSQL database files |
| `asi_gitea` | Gitea repository data |

### Project Directory Structure

```
/opt/asi-platform/
├── docker-compose.yml
├── .env                  (secrets — never committed to Git)
├── .gitignore
├── nginx/
│   ├── conf.d/
│   └── ssl/
├── data/
│   ├── nextcloud/
│   ├── postgresql/
│   └── gitea/
└── backups/
```

### Ansible Role

Provisioned by: `ansible/roles/docker_setup/`

```yaml
- name: Install Docker prerequisites
  ansible.builtin.apt:
    name: [ca-certificates, curl, gnupg]
    state: present

- name: Add Docker GPG key
  ansible.builtin.shell:
    cmd: curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    creates: /etc/apt/keyrings/docker.gpg

- name: Add Docker apt repository
  ansible.builtin.apt_repository:
    repo: "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable"
    state: present

- name: Install Docker CE and Compose plugin
  ansible.builtin.apt:
    name: [docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin]
    state: present
    update_cache: true

- name: Create appuser
  ansible.builtin.user:
    name: appuser
    uid: 1001
    shell: /bin/bash
    create_home: true
    groups: docker
    append: true
    # Note: do NOT set system: true — uid 1001 is not a system account UID on Debian

- name: Create Docker networks
  community.docker.docker_network:
    name: "{{ item }}"
    state: present
  loop:
    - internal
    - proxy

- name: Create named volumes
  community.docker.docker_volume:
    name: "{{ item }}"
    state: present
  loop:
    - asi_nextcloud
    - asi_postgresql
    - asi_gitea

- name: Create project directory structure
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    owner: appuser
    mode: '0755'
  loop:
    - /opt/asi-platform
    - /opt/asi-platform/nginx/conf.d
    - /opt/asi-platform/nginx/ssl
    - /opt/asi-platform/data/nextcloud
    - /opt/asi-platform/data/postgresql
    - /opt/asi-platform/data/gitea
    - /opt/asi-platform/backups
```

---

## Gotchas & Notes

**nesting=1 must be set on the LXC**
Docker inside an unprivileged LXC requires `features: nesting=1` — confirmed enabled in [Proxmox LXC Setup](proxmox-lxc.md). No issues observed.

**iptables backend**
Docker defaulted to `iptables-nft` on Debian 12 — correct behaviour, no legacy iptables workaround needed.

**cgroups v2**
Debian 12 uses cgroups v2 by default. Docker 29.x handles this natively — no extra configuration required.

**AppArmor in LXC**
AppArmor installs as a Docker dependency. On an unprivileged LXC, kernel-level AppArmor enforcement depends on the Proxmox host. No issues observed during install or operation.

**Always use `docker compose` not `docker-compose`**
The v1 standalone binary is not installed. Use the v2 plugin syntax throughout: `docker compose up -d`, `docker compose logs` etc.

**SSH config entry needed for Ansible**
Add `asi-platform` to `~/.ssh/config` on your control node so Ansible can resolve it by hostname:
```
Host asi-platform
    HostName 192.168.1.11
    User root
    IdentityFile ~/.ssh/id_rsa
```

---

[Next: OpenWrt Network Configuration →](openwrt-network.md)
