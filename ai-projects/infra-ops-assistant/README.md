# AI Infrastructure Ops Assistant

**Can AI act as a personal assistant for managing IT infrastructure — and what happens when you actually give it access to live systems?**

---

## The Question

There is a lot of discussion about AI transforming IT operations. The claims range from cautious ("AI will assist engineers") to ambitious ("AI will replace them"). Rather than take either position at face value, this project is a direct, hands-on attempt to find out.

The setup is straightforward: a real homelab environment, real infrastructure, and an AI agent with genuine access to it. The question is not whether AI can answer questions about infrastructure in theory — it is whether it can actually operate infrastructure in practice.

---

## Meet JARVIS

JARVIS is the name given to the AI assistant in this project — a nod to Tony Stark's AI system, and an appropriately ambitious reference point. Like the fictional JARVIS, the goal is a natural language interface to an entire infrastructure environment: ask a question, get an answer; give an instruction, have it carried out.

Unlike the fictional version, this one has real constraints, real failure modes, and real security implications. Those are documented honestly throughout.

---

## The Environment

The homelab is a self-hosted infrastructure platform running across two Proxmox hypervisors, several LXC containers, and multiple Docker stacks. It includes:

| Host | Role |
|---|---|
| `openwrt` | Router and firewall |
| `proxmox` / `proxmox2` | Hypervisors |
| `adguard` | DNS and ad blocking |
| `debian` | OneDrive, Syncthing, web server, automation |
| `docker` | Multiple Docker stacks |
| `automation` | Full stack project environment |
| `cosmos` | Cosmos Cloud platform |
| `homeassistant` | Home automation |

All hosts are on a private `/24` network with SSH key-based authentication throughout.

---

## The Tooling

JARVIS is built on three components working together:

**Claude Code** — An AI coding and operations assistant that runs locally on the workstation. It reads a configuration file (`CLAUDE.md`) that gives it full context about the homelab — every host, every role, every preference.

**CLAUDE.md** — A plain-text context file that acts as JARVIS's memory. It describes the entire environment: hostnames, IPs, SSH login details, documentation standards, and working preferences. Every Claude Code session starts by reading this file.

**MCP Servers** — Model Context Protocol servers that give Claude Code real reach into the infrastructure. Rather than just answering questions, Claude can SSH into hosts, inspect Docker containers, query DNS stats, commit to GitHub, and read and write files — all from a single natural language prompt.

| MCP Server | What it enables |
|---|---|
| `mcp-ssh` | SSH into any homelab host and run commands |
| `github` | Commit, push, and manage GitHub repositories |
| `homelab-mcp` | Docker monitoring, AdGuard stats, network health |
| `filesystem` | Read and write local files (built into Claude Code) |

---

## What This Project Documents

This is not a tutorial for a finished product. It is an honest account of building, using, and evaluating an AI-assisted infrastructure operations workflow — including where it works well, where it falls short, and where it introduces genuine risk.

| Document | What it covers |
|---|---|
| [installation.md](./installation.md) | Setting up Claude Code, CLAUDE.md, and all MCP servers |
| [usage.md](./usage.md) | Real examples — what was asked, what JARVIS did, what the results were |
| [evaluation.md](./evaluation.md) | Honest assessment: capabilities, limitations, and security risks |

---

*This project runs against a real homelab environment. All IPs and hostnames shown are representative examples for documentation purposes.*
