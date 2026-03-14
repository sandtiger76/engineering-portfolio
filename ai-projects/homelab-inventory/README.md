# AI Homelab Reconnaissance & Security Audit

> *I asked an AI agent to document my homelab. I expected a list of hostnames, OS versions and installed software. What came back in 6 minutes and 31 seconds was not what I had in mind.*

---

## The Task

My homelab is simple from a hardware perspective — one router and two Proxmox hypervisors running a mix of LXCs and VMs. I do have documentation, but there are times you install something to test, it works, you leave it running, and six months later you have forgotten it is there.

I wanted Claude Code to SSH into the three hardware hosts and produce a current snapshot of what was actually running. Hardware specs, OS versions, installed software. I was hoping to supplement my existing documentation and flag a few forgotten installs that were never cleaned up.

That was it. A basic documentation exercise. Nothing more.

### The Claude Code Prompt

I ran Claude Code with `--dangerously-skip-permissions` so it would work through the task without stopping to ask for confirmation at every step.

```
I'd like you to connect to my homelab infrastructure and build me a complete
inventory of what's running. I've given you SSH access to three hosts:

- root@openwrt  — my router
- root@proxmox  — primary hypervisor
- root@proxmox2 — secondary hypervisor

Start by logging into each one and getting a feel for what's there. From
there, use your judgement — go as deep as you think is useful to give me
a thorough picture of my environment.

I'm curious what you find.
```

---

## What Came Back

**Runtime: 6 minutes and 31 seconds.**

The agent produced a 527-line structured markdown report covering every layer of the environment. Hardware specs, OS versions, storage pools, network configuration, every running service across every guest, every Docker container, every compose stack. Exactly the support reference I was after.

It also produced a findings section at the end. Ordered by severity. With specific remediation commands for each item.

I had not asked for any of that. The agent had simply kept reading, understood what it was looking at, and flagged what concerned it.

| Layer | What the agent mapped |
|-------|-----------------------|
| Router | Hardware, firmware version, WAN config, 18 active DHCP clients with hostnames and device types |
| Proxmox 1 | CPU, RAM, 3 storage pools, physical disks, 5 guests (3 LXC + 2 VM) |
| Proxmox 2 | CPU, RAM, 2 storage pools, physical disks, 1 guest |
| LXC containers | AdGuard Home, file server, full automation stack, ASI platform |
| VMs | Docker host (20+ containers), Windows Server DC lab |
| Compose stacks | All stacks read — services, ports, environment config |
| Network | Full DHCP lease table — every device on the network by hostname, IP, and type |

---

## The Security Findings I Did Not Ask For

This is where it got uncomfortable.

The inventory came back exactly as expected. But appended to it was a findings section I never requested. The agent had been reading config files to build a hardware list, recognised what it was seeing, and documented it.

I cannot publish the full report. It contains a complete map of my home network — IPs, MAC addresses, every device, software versions, open ports. Publishing that would be its own security problem. The table below gives an accurate picture of what was found, with hostnames anonymised.

None of this came from a dedicated security scan. It came from a documentation request.

### Vulnerability Summary

| Severity | Finding | Host(s) |
|----------|---------|---------|
| 🔴 CRITICAL | Docker TCP API exposed on port 2375 — unauthenticated, bound to all interfaces | `automation` LXC + `docker` VM |
| 🔴 CRITICAL | Automation stack (8 services) will not start after a reboot — `onboot` not set | `automation` LXC |
| 🟠 HIGH | Samba share anonymously writable — no credentials required from any LAN device | `debian` LXC |
| 🟠 HIGH | ISP PPPoE credentials in plaintext — router compromise = ISP account compromise | OpenWrt router |
| 🟡 MEDIUM | Container crashlooping since deployment — missing setup, restarting every 67 seconds | `docker` VM |
| 🟡 MEDIUM | n8n running as two independent instances with separate databases | `automation` + `docker` VM |
| 🟡 MEDIUM | Gitea running as two independent instances on separate hosts | `automation` + `asi-platform` |
| 🟡 MEDIUM | Windows Server evaluation copy — expires and force-reboots; ISO still attached; orphaned disk in storage | APEX-DC01 VM |
| 🟡 MEDIUM | Proxmox API token — no expiry, no privilege separation (`privsep=0`) | Proxmox 1 |
| 🟡 MEDIUM | n8n session cookie not restricted to HTTPS (`N8N_SECURE_COOKIE=false`) | `automation` LXC |
| 🔵 LOW | Docker installed directly on Proxmox 2 hypervisor — only `hello-world` ever ran, 3 months ago | Proxmox 2 |
| 🔵 LOW | WiFi adapter present on hypervisor, unconfigured, state DOWN | Proxmox 2 |
| 🔵 LOW | `wpa_supplicant` running on a VM with no WiFi hardware | `docker` VM |
| 🔵 LOW | SNMP daemon on router — community string unverified, may be default `public` | OpenWrt router |
| 🔵 LOW | LAN clients querying DNS over plain port 53 despite encrypted upstream | AdGuard LXC |
| 🔵 LOW | Router flash storage at 100% capacity | OpenWrt router |

Two findings stood out.

**The Docker TCP API on port 2375** was something I had configured for a monitoring integration and forgotten about. On two separate hosts. Any device on the network could issue arbitrary Docker commands to either host with no credentials whatsoever. The agent found it by reading `/etc/docker/daemon.json` inside guest VMs it had reached through the Proxmox hosts. It did not just see an open port. It read the config, understood what it meant, and explained the consequence.

**The missing onboot flag** is a quieter finding but would have caused real pain. Eight services on one LXC, including Postgres and Redis with live data, would have silently vanished on the next Proxmox reboot. One command to fix. The agent provided it.

---

## What Could Go Catastrophically Wrong

The report also mapped the network topology, including which VLANs existed and how devices were segmented. In a homelab, VLAN boundaries are often less strict than in a production environment — devices that probably should not be able to reach each other sometimes can. The report made that visible. A phone, a laptop, or anything else on the same VLAN as an infrastructure host could potentially reach services that were never intended to be accessible from client devices. That is not a configuration mistake unique to homelabs. It is extremely common.

The agent was given instructions to document and flag. It did exactly that. But it is worth being direct about what the same access could produce with different instructions.

**With port 2375 open on two hosts, an attacker with LAN access could:**

- Spawn a privileged container mounting the host root filesystem — full read and write access to everything on that host
- Read environment variables from every running container, including database passwords and API keys
- Deploy a persistent backdoor that survives container restarts
- Do all of this with no authentication log entry, because there is no authentication

**A determined attacker working through the full report could, in sequence:**

1. Connect to the Docker API on port 2375 — no credentials needed
2. Read secrets from running container environment variables
3. Mount the host filesystem via a privileged container
4. Use the Proxmox API token (no expiry, no privilege separation) to manage or destroy hypervisor guests
5. Write to the anonymous Samba share — plant files, exfiltrate data, corrupt backups
6. Read ISP credentials from the router config
7. Pivot to the Tailscale-connected host, now reachable from anywhere outside the network
8. Reach the Windows Server domain controller

**What AI adds to this that traditional tooling does not:**

A port scanner finds port 2375 open. It does not know what that means in context. An AI agent reads the config file, understands that an unauthenticated TCP socket means full remote control, identifies which containers hold sensitive environment variables, maps the relationships between services, and explains the complete attack chain in plain language. That happened here as a side effect of building a hardware inventory.

The access required was not special. Three SSH credentials. The same access you would hand a support contractor.

---

## What I Fixed

I fixed all the security issues before publishing this. Some findings were deliberate choices made during setup. Most were things configured at some point, never revisited, sitting quietly on a list of things to sort out eventually.

The agent flagged them. I then used it to work through the fixes. The same tool that found the problems helped resolve them.

---

## Reflections

**On the documentation task:** It worked. The inventory is exactly the support reference I wanted — hardware, software, versions, open ports, config highlights in one place. The prompt matters though. A vague question will get a broad answer. In infrastructure, a broad answer from an AI agent with root access covers a lot of ground quickly.

**On the security findings:** I did not ask for them and I am glad I got them. The Docker TCP API issue alone justified the exercise. A manual audit would have needed deliberate effort and prior knowledge of where to look. The agent found it while doing something else entirely.

**On the bigger picture:** This does not require expensive tooling or specialist knowledge. SSH access and a Claude subscription. The agent does the rest — reads the environment, understands what it finds, identifies what matters, and explains the implications without being asked. That is useful for anyone doing legitimate audit work. It is the same capability regardless of intent.

**Two questions this raises that I want to explore further:**

1. Security auditing has traditionally required specialist skills most people do not have. If AI can surface critical misconfigurations from a documentation request, what does that mean for how smaller organisations and individuals approach security?

2. The other side of that: what happens when the instructions are wrong, the agent makes an error, or someone with access and bad intent points the same tooling at a network they should not be on?

Those questions are the starting point for the follow-on projects below.

---

## What Comes Next

This was never meant to be a project. I wanted to document my network.

That simple task raised enough questions that I want to keep going. Specifically:

- **Prompt Injection via Infrastructure** — What happens when malicious content in the environment manipulates the agent mid-run? Log entries, config file comments, and DNS TXT records as potential attack vectors.
- **Unsupervised Agent Drift** — Leave the agent running with broad access and no human review. Come back and audit what it actually did versus what was asked.
- **AI-Assisted Red Team** — Take the findings from this report and instruct the agent to act on them rather than document them. Where does it go, and where does it stop?
- **Network Segmentation as Defence** — Tighten the network segmentation and repeat this exact experiment. Compare what the agent can and cannot reach.

---

## Files

| File | Description |
|------|-------------|
| `CLAUDE.md` | The prompt given to Claude Code to initiate the task |
| `README.md` | This document |

---

*This experiment was conducted on my own infrastructure in a controlled homelab environment. All findings are genuine. Sensitive details including WAN IP, ISP credentials, MAC addresses, and personal device identifiers have been redacted from all published materials.*
