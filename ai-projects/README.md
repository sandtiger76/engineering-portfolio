# The AI Experiment

I wanted to find out what AI can actually do in a real IT environment — not in demos or
controlled benchmarks, but on live systems with real constraints and real consequences.

Each project starts with a question I couldn't answer without building something. The
work runs on my homelab rather than production, but the systems and problems are genuine.
I document what worked, what didn't, and where human judgement still mattered.

> *How much can AI actually do — and does human judgement remain essential?*

---

## Projects

---

### 🖥️ [AI Infrastructure Ops Assistant](./infra-ops-assistant/README.md)

> *Give AI real SSH access to a live homelab. Ask it anything. See what happens.*

You've probably used AI to write infrastructure commands. But what happens when it can *run* them? This project connects Claude Code to a real multi-host homelab via MCP servers, SSH, Docker, DNS monitoring, and GitHub, and explores what a natural language interface to live infrastructure actually looks like in practice.

The result is more capable, and more concerning, than expected.



**[→ View Project](./infra-ops-assistant/README.md)**

---

### ☁️ [Giving an AI Agent Control of a Real Azure Environment](./azure-ops-assistant/README.md)

> *What happens when you stop asking AI to help with infrastructure and let it run the whole thing?*

Production changes shouldn't be made unless you fully understand their impact. For this experiment, I deliberately stepped away from that rule, giving an AI agent full control of a test machine and an Azure environment to deploy, verify, document, and destroy.



**[→ View Project](./azure-ops-assistant/README.md)**

---

### 🔍 [Job Intelligence Pipeline](./jobhunt-portal/README.md)

> *A sysadmin with no development background builds a full-stack data pipeline, with AI as co-engineer.*

Multiple job boards. Daily automated scraping. Deduplication, classification, and shortlisting. A self-hosted web portal for tracking applications. Zero cloud dependency. Built by someone who had never written a production application before.

This project is two things at once: a useful job hunting tool, and an honest account of what it's like to build something real with AI when you're working outside your area of expertise.


**[→ View Project](./jobhunt-portal/README.md)**

---

### 🔐 [AI Homelab Inventory](./homelab-inventory/README.md)

> *I asked an AI agent to document my homelab. What came back was not what I had in mind.*

I deleberately gave AI ssh access to audit my homelab and documents it. One prompt asking for a hardware and software inventory. What the agent returned was a 527-line report covering every service, every container, every config file it could reach — and a security findings section nobody asked for, ordered by severity, with remediation commands attached.



**[→ View Project](./homelab-inventory/README.md)**

---
### 🔐 [AI Security Lab — Analyst vs Ethical Hacker](./security-testing/README.md)

> *Can AI do the job of a security analyst and an ethical hacker at the same time?*

One agent audited a real network. A separate agent attacked it blind. Then remediation and a retest. This documents what each found, what each missed, and whether AI can replace specialist security skills.

**[→ View Project](./security-testing/README.md)**

---
## A Note on How These Were Built

Several projects here were built with direct AI assistance, including code generation, debugging, architecture decisions, and documentation. That's intentional and acknowledged throughout.

Using AI effectively as an engineering tool is itself a skill. Knowing what to ask, how to validate the output, when to push back, and when not to trust it, that's the real competency being developed and documented here.

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly labelled. No client data, credentials, or confidential information appears anywhere in this repository.*