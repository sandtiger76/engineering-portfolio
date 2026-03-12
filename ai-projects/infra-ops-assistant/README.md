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
| [CLAUDE.md](./CLAUDE.md) | Example context file — the configuration that gives JARVIS its environmental awareness |
| [installation.md](./installation.md) | Setting up Claude Code, CLAUDE.md, and all MCP servers |
| [usage.md](./usage.md) | Real examples — what was asked, what JARVIS did, what the results were |
| [evaluation.md](./evaluation.md) | Honest assessment: capabilities, limitations, and security risks |

---

## What's Next

This project is actively evolving. Two areas are planned for exploration:

### AI-Assisted Monitoring Automation

The current setup handles ad-hoc queries well — ask a question, get an answer. The next step is closing the loop: using n8n as a workflow orchestrator to trigger Claude automatically in response to infrastructure events. Rather than asking JARVIS "are any containers down?", the goal is for JARVIS to tell you — diagnose the issue, attempt remediation, and document what it did, all without manual intervention.

This raises interesting questions about trust, oversight, and what level of autonomy is appropriate for an AI agent operating on live infrastructure. Those questions will be documented honestly as the work progresses.

### JARVIS in Your Pocket — WhatsApp and Telegram Integration

One of the more compelling possibilities: integrating WhatsApp or Telegram with Claude Code so that JARVIS can be controlled directly from a phone. Send a message to yourself, JARVIS acts on it. The infrastructure assistant becomes a true personal assistant — available anywhere, not just at a workstation.

The implications go well beyond homelab management. A natural language interface to your entire infrastructure, reachable from any device, at any time. The possibilities are significant. So are the security considerations, which will be explored in detail when this is implemented.

---

*This project runs against a real homelab environment. All IPs and hostnames shown are representative examples for documentation purposes.*
