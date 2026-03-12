# JARVIS — Global Claude Code Configuration

## About
- Name: JARVIS
- Workstation: Linux Mint, hostname `homelab-ws`
- GitHub: https://github.com/jarvis-lab

## Network Overview
- Router: OpenWrt
- Network: `172.17.17.x` IPv4 only
- DNS: AdGuard at `172.17.17.3` (primary), `9.9.9.9` (fallback)
- DHCP range: `172.17.17.100–250`, lease 12h

## SSH Hosts

| Hostname      | IP            | Login                                             | Role                                                        |
|---------------|---------------|---------------------------------------------------|-------------------------------------------------------------|
| openwrt       | 172.17.17.1   | `ssh root@openwrt`                                | Router and firewall                                         |
| proxmox       | 172.17.17.2   | `ssh root@proxmox`                                | Proxmox hypervisor #1                                       |
| adguard       | 172.17.17.3   | `ssh root@adguard`                                | AdGuard + primary LAN DNS                                   |
| homeassistant | 172.17.17.4   | —                                                 | Home Assistant                                              |
| debian        | 172.17.17.5   | `ssh jarvis@debian` / `ssh root@debian-root`      | OneDrive + Syncthing + web server + automation scripts      |
| docker        | 172.17.17.6   | `ssh root@docker`                                 | VM dedicated to multiple Docker instances                   |
| proxmox2      | 172.17.17.7   | `ssh root@proxmox2`                               | Proxmox hypervisor #2                                       |
| cosmos        | 172.17.17.8   | `ssh root@cosmos`                                 | Cosmos Cloud                                                |
| automation    | 172.17.17.9   | `ssh root@automation`                             | Docker + full stack project                                 |

> **Note on debian:** Use `jarvis` (user) for application-level tasks like OneDrive and Syncthing.
> Use `root` via `debian-root` for system administration and package management.

## Proxmox Infrastructure

### Proxmox Server 1 (`proxmox` — 172.17.17.2)

| VMID | Hostname   | SSH Login                                        | Role                                            |
|------|------------|--------------------------------------------------|-------------------------------------------------|
| 101  | adguard    | `ssh root@adguard`                               | AdGuard + primary DNS for LAN clients           |
| 102  | debian     | `ssh jarvis@debian` / `ssh root@debian-root`     | OneDrive + Syncthing + web server + automation  |
| 103  | automation | `ssh root@automation`                            | Docker + full stack project                     |
| 201  | docker     | `ssh root@docker`                                | VM dedicated to multiple Docker instances       |

### Proxmox Server 2 (`proxmox2` — 172.17.17.7)

| VMID | Hostname | SSH Login         | Role         |
|------|----------|-------------------|--------------|
| 100  | cosmos   | `ssh root@cosmos` | Cosmos Cloud |

## GitHub Repositories
- All local repos are under: `~/Documents/IT/GitHub/`
- Engineering portfolio (public): `~/Documents/IT/GitHub/engineering-portfolio`
- Push changes with standard git workflow after edits

## Documentation Standards
- All documentation is written in Markdown
- Use clear headings, tables for structured data, and code blocks for commands and configs
- Imperative tone, concise, sysadmin-friendly
- After creating or editing docs, remind me to `git add`, `git commit`, and `git push`

## General Preferences
- Be concise and practical — skip basic explanations unless asked
- Prefer key-based SSH auth (already configured on all hosts)
- Prefer clarity over cleverness in scripts and configs
- Always confirm before making destructive changes (deleting files, stopping services, modifying firewall rules)
- When documenting, pull real config and output from live systems where possible
- Keep sessions focused — long sessions with many tool calls degrade context quality and increase cost
