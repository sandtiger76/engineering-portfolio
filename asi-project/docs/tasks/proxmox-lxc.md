# Proxmox LXC Setup

[← Back to README](../../README.md)

---

## What Is It?

LXC (Linux Containers) is a lightweight virtualisation technology built into the Linux kernel. Unlike a full virtual machine, an LXC container shares the host's operating system kernel — making it faster to start, lighter on resources, and almost as isolated as a full VM for most purposes.

Proxmox VE includes LXC support natively, with a web interface for creation and management.

**Why it's in this project:** Running services in a container rather than directly on the Proxmox host is good practice — it keeps the hypervisor clean, makes the workload portable, and means the entire platform can be destroyed and rebuilt without touching the Proxmox host itself.

---

## Prerequisites

Before Ansible can provision the LXC, the following must be completed manually on the Proxmox host. These are one-time bootstrap steps.

| Prerequisite | How |
|---|---|
| Proxmox VE installed | Manual installation on Intel NUC |
| Debian 12 LXC template downloaded | See note below — must be explicitly downloaded |
| Proxmox API token created | See below |
| SSH key added to Proxmox host | `ssh-copy-id root@192.168.1.7` |

> **Note:** Proxmox does not ship with a Debian 12 template pre-loaded. Run the following on the Proxmox host before the Ansible playbook:
> ```bash
> pveam update
> pveam download local debian-12-standard_12.12-1_amd64.tar.zst
> ```

### Creating a Proxmox API Token

Ansible uses the Proxmox API to create and manage the LXC. The API token is the authentication credential.

1. Log into Proxmox UI at `https://192.168.1.7:8006`
2. Navigate to Datacenter → Permissions → API Tokens
3. Add token for user `root@pam`, name it `ansible`
4. Copy the token secret — it is only shown once
5. Store in Ansible Vault:

```bash
ansible-vault edit ansible/group_vars/all/vault.yml
# Add: proxmox_api_token_secret: "YOUR_TOKEN_SECRET"
```

---

## Technical Implementation

### LXC Specification

| Setting | Value |
|---|---|
| VMID | 100 |
| Template | debian-12-standard_12.12-1_amd64 |
| vCPU | 2 |
| RAM | 4096 MB |
| Swap | 512 MB |
| Disk | 40GB on local-lvm |
| IP | 192.168.1.11/24 |
| Gateway | 192.168.1.1 |
| DNS | 192.168.1.3 (AdGuard) |
| Hostname | asi-platform |
| Unprivileged | Yes |
| Nesting | Enabled (required for Docker) |

### Commands Executed

```bash
# 1. Update template list and download Debian 12
pveam update
pveam download local debian-12-standard_12.12-1_amd64.tar.zst

# 2. Stage SSH key
grep "quintin@quintin-M70q" /root/.ssh/authorized_keys > /tmp/asi_ssh.pub

# 3. Create the LXC container
pct create 100 local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst \
  --hostname asi-platform \
  --cores 2 \
  --memory 4096 \
  --swap 512 \
  --rootfs local-lvm:40 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.11/24,gw=192.168.1.1 \
  --nameserver 192.168.1.3 \
  --searchdomain local \
  --unprivileged 1 \
  --features nesting=1 \
  --ssh-public-keys /tmp/asi_ssh.pub \
  --start 0

# 4. Start the container
pct start 100

# 5. Fix IPv6 apt issue (IPv4-only network)
pct exec 100 -- bash -c 'echo "Acquire::ForceIPv4 \"true\";" > /etc/apt/apt.conf.d/99force-ipv4'

# 6. Update OS and install base packages
pct exec 100 -- bash -c 'apt-get update -qq && apt-get upgrade -y -qq && \
  apt-get install -y curl wget git sudo ca-certificates'

# 7. Fix locale
pct exec 100 -- bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
  locale-gen && echo "LANG=en_US.UTF-8" > /etc/default/locale'
```

### SSH Access

```bash
ssh root@192.168.1.11
```

### Ansible Playbook

The LXC is created by the `community.general.proxmox` Ansible module:

```yaml
- name: Create ASI Platform LXC
  community.general.proxmox:
    api_host: "192.168.1.7"
    api_user: "root@pam"
    api_token_id: "ansible"
    api_token_secret: "{{ proxmox_api_token_secret }}"
    node: proxmox2
    vmid: 100
    hostname: asi-platform
    ostemplate: "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    cores: 2
    memory: 4096
    swap: 512
    disk: "local-lvm:40"
    netif: '{"net0":"name=eth0,ip=192.168.1.11/24,gw=192.168.1.1,bridge=vmbr0"}'
    nameserver: "192.168.1.3"
    unprivileged: true
    features:
      - nesting=1
    state: present
    started: true
```

### Important: Docker Inside LXC

Docker requires the `nesting` feature to be enabled on the LXC. Without it, Docker cannot create its internal network namespaces. This is set in the `features` parameter above and is a common gotcha.

---

## Gotchas & Notes

These issues were all encountered during the actual build and are handled automatically in the Ansible role.

**Template not pre-loaded on Proxmox**
Only a Debian 13 template was present on proxmox2. The Debian 12 template must be explicitly downloaded via `pveam` before provisioning. The Ansible role checks for the template and downloads it if missing.

**apt fails over IPv6**
On an IPv4-only network, apt attempts IPv6 addresses first and times out. Fixed by creating a persistent apt config file immediately after container creation:
```bash
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
```
This file persists across reboots. The Ansible role applies this before any `apt` tasks run.

**IP conflict — verify before assigning**
`192.168.1.10` was already in use on the network (MAC `bc:24:11:b0:30:03`). Container was assigned `192.168.1.11` instead. Always verify an IP is free before provisioning:
```bash
ping -c 2 192.168.1.11   # timeout = free, response = taken
```

**Locale warnings during apt**
Fresh Debian 12 LXC has no locale configured, causing `perl: warning: Setting locale failed` during package installs. The Ansible role generates `en_US.UTF-8` immediately after the OS update.

**Docker storage driver — fuse-overlayfs required**
Unprivileged LXCs cannot use Docker's default `overlay` storage driver. Install `fuse-overlayfs` and configure Docker explicitly — handled in the Docker role:
```json
{ "storage-driver": "fuse-overlayfs" }
```
If Docker Compose v2 or BuildKit has issues, also add `keyctl=1` to the LXC features.

**community.general collection required**
```bash
ansible-galaxy collection install community.general
```

---

[Next: Docker Installation →](docker.md)
