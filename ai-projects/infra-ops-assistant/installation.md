# Installation Guide

**Setting up Claude Code, CLAUDE.md, and MCP servers to create a natural language interface for your homelab.**

---

## Overview

The JARVIS setup has three layers:

1. **Claude Code** — the AI agent that runs on your workstation
2. **CLAUDE.md** — the context file that tells Claude about your environment
3. **MCP Servers** — the integrations that give Claude real access to your infrastructure

All three are required for the full experience. Claude Code alone can answer questions. CLAUDE.md gives it accurate context. MCP servers give it actual reach.

---

## Prerequisites

- Linux workstation (this guide uses Linux Mint)
- SSH key-based authentication already configured to all homelab hosts
- A Claude Pro account (required for Claude Code)
- Node.js 18+ installed
- Python 3 installed

Check Node.js:
```bash
node --version
```

If not installed:
```bash
sudo apt update
sudo apt install -y nodejs npm
```

---

## Step 1 — Install Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Verify the installation:
```bash
claude doctor
```

This will open a browser window to authenticate with your Claude account. Once authenticated, Claude Code is ready.

---

## Step 2 — Create Your Working Directory

Create a dedicated directory for Claude Code sessions:

```bash
mkdir -p ~/Documents/claude
```

This is where you will launch Claude Code from. It keeps sessions organised and separate from your project repositories.

---

## Step 3 — Create CLAUDE.md

`CLAUDE.md` is the most important file in this setup. It is automatically read by Claude Code at the start of every session — giving it full context about your environment without you having to re-explain it each time.

Create the file at the root of your working directory:

```bash
nano ~/Documents/claude/CLAUDE.md
```

A well-structured `CLAUDE.md` should include:

- **Who you are** — name, workstation hostname, GitHub username
- **Network overview** — router, DNS, DHCP range
- **SSH hosts table** — every host with IP, login, and role
- **Proxmox inventory** — VMID, hostname, login, role
- **GitHub repositories** — where your repos live locally
- **Documentation standards** — how you want docs written
- **General preferences** — tone, behaviour, what to confirm before doing

See the [example CLAUDE.md](./CLAUDE.md) in this repository for a full reference.

> **Security note:** CLAUDE.md will contain your network topology, hostnames, and SSH usernames. Treat it like any infrastructure documentation — do not commit real IP addresses or passwords to a public repository. The example in this repo uses representative IPs for illustration only.

---

## Step 4 — Configure SSH

Ensure your `~/.ssh/config` has entries for all homelab hosts. Claude Code's SSH MCP reads this file directly to discover available hosts.

```bash
nano ~/.ssh/config
```

Example structure:
```
Host proxmox
    HostName 172.17.17.2
    User root

Host adguard
    HostName 172.17.17.3
    User root

Host automation
    HostName 172.17.17.9
    User root

Host openwrt
    HostName 172.17.17.1
    User root
```

Test each connection manually before proceeding:
```bash
ssh root@proxmox
ssh root@automation
```

---

## Step 5 — Install MCP Servers

### MCP 1 — SSH

Gives Claude Code the ability to SSH into any host in your `~/.ssh/config` and run commands.

```bash
claude mcp add --scope user --transport stdio mcp-ssh -- npx -y @aiondadotcom/mcp-ssh
```

### MCP 2 — GitHub

Gives Claude Code the ability to commit, push, and manage your GitHub repositories.

**Create a Personal Access Token:**
1. Go to https://github.com/settings/tokens
2. Generate a new classic token with `repo` scope
3. Copy it immediately

**Store it securely:**
```bash
echo 'export GITHUB_PAT="ghp_your_token_here"' >> ~/.bashrc
source ~/.bashrc
```

**Add the MCP:**
```bash
claude mcp add --scope user --transport http github \
  https://api.githubcopilot.com/mcp \
  -H "Authorization: Bearer ${GITHUB_PAT}"
```

> **Security note:** Never hardcode your PAT in a script or config file. Always use an environment variable.

### MCP 3 — Homelab MCP

Gives Claude Code monitoring access to Docker containers, AdGuard DNS stats, and network connectivity.

**Clone and install:**
```bash
cd ~
git clone https://github.com/bjeans/homelab-mcp
cd homelab-mcp
pip3 install -r requirements.txt --break-system-packages
```

**Create the host inventory:**
```bash
cp ansible_hosts.example.yml ansible_hosts.yml
nano ansible_hosts.yml
```

```yaml
all:
  hosts:
    proxmox:
      ansible_host: 172.17.17.2
      ansible_user: root
    automation:
      ansible_host: 172.17.17.9
      ansible_user: root
    docker:
      ansible_host: 172.17.17.6
      ansible_user: root
    adguard:
      ansible_host: 172.17.17.3
      ansible_user: root
```

**Create the .env file:**
```bash
cp .env.example .env
nano .env
```

Key settings:
```env
DOCKER_SERVER1_ENDPOINT=172.17.17.6:2375
DOCKER_SERVER2_ENDPOINT=172.17.17.9:2375
ADGUARD_HOST=172.17.17.3
ADGUARD_PORT=3000
ADGUARD_USERNAME=admin
ADGUARD_PASSWORD=your_adguard_password
ANSIBLE_INVENTORY_PATH=/home/jarvis/homelab-mcp/ansible_hosts.yml
```

> **Security note:** The `.env` file contains service credentials. Never commit it to a public repository. Add it to `.gitignore` immediately.

**Enable Docker API on host systems:**

The homelab MCP requires port 2375 to be open on Docker hosts. This is disabled by default.

On each Docker host (`docker`, `automation`):
```bash
nano /etc/docker/daemon.json
```

```json
{
  "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
}
```

```bash
systemctl restart docker
```

> **Security note:** Port 2375 is unauthenticated. This is acceptable on a trusted home LAN behind a firewall. Never expose this port to the internet. See [evaluation.md](./evaluation.md) for a full discussion of this risk.

**Add to Claude Code:**
```bash
claude mcp add --scope user --transport stdio homelab \
  -- python3 /home/jarvis/homelab-mcp/homelab_unified_mcp.py
```

---

## Step 6 — Verify Everything

```bash
claude mcp list
```

Expected output:
```
mcp-ssh      stdio   active
github       http    active
homelab      stdio   active
```

Or from inside Claude Code:
```
/mcp
```

---

## Step 7 — Launch

```bash
cd ~/Documents/claude
claude
```

Claude Code will read `CLAUDE.md` automatically. You are ready.

Try a first command:
```
List all my SSH hosts and confirm you can see the homelab layout
```

Then try a live test:
```
SSH into proxmox and show me the running VMs
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| MCP shows as inactive | Run `node --version` — needs 18+. Restart terminal and retry. |
| SSH MCP not finding hosts | Check `~/.ssh/config` exists and is readable. Test SSH manually first. |
| GitHub MCP auth failing | Run `echo $GITHUB_PAT` to verify the variable is set. Re-add the MCP if needed. |
| Homelab MCP errors | Run `python3 ~/homelab-mcp/homelab_unified_mcp.py` directly to see error output. |
| Claude doesn't know your hosts | Check `CLAUDE.md` is in the directory you launched Claude from. |
