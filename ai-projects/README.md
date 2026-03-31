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

> *What happens when AI can actually run commands on live infrastructure, not just suggest them?*

Claude Code was given SSH access to a live multi-host homelab and asked to operate it through natural language. Some tasks worked first time. Others exposed real limitations. A few raised questions about what that level of access means if something goes wrong.

This documents what AI-assisted infrastructure operations looks like in practice, including where it earns trust and where it doesn't.

**[→ View Project](./infra-ops-assistant/README.md)**

---

### ☁️ [AI Agent Given Full Control of a Real Azure Environment](./azure-ops-assistant/README.md)

> *Deploy, verify, document, tear down. No manual steps. What actually happened?*

An AI agent was given a plain-English briefing and full control of an Azure lab. It deployed infrastructure across seven phases, handled errors without prompting, wrote its own documentation, and ran teardown. It also silently chose paid services when free ones were specified, and drifted from the agreed spec without flagging it.

Both runs are documented. The failure matters as much as the success.

**[→ View Project](./azure-ops-assistant/README.md)**

---

### 🔍 [AI as Co-Engineer: Building a Job Intelligence Pipeline](./jobhunt-portal/README.md)

> *Multiple job boards, daily scraping, automatic classification, a self-hosted tracking portal. Built by a sysadmin with no development background, using AI as co-engineer.*

The tool works. The more interesting story is what the build process actually looked like: where AI carried the work, where it needed constant correction, and where it lost the plot entirely. No cloud dependency, no ongoing cost.

**[→ View Project](./jobhunt-portal/README.md)**

---

### 🗂️ [AI Homelab Inventory: Asked for Documentation, Got a Security Audit](./homelab-inventory/README.md)

> *The brief was simple: connect to my homelab and document what's running. Hardware specs, software, versions.*

The AI did exactly that. It also came back with a security findings section nobody asked for, ordered by severity, with remediation commands attached. Two critical vulnerabilities were real. One had been forgotten about entirely.

This documents what the agent found, what it meant, and what the same access could produce with different intent.

**[→ View Project](./homelab-inventory/README.md)**

---

### 🔐 [AI Security Analyst vs AI Ethical Hacker: Can AI Security-Harden Your Systems?](./security-testing/README.md)

> *Two AI agents, two opposing briefs. One acts as a security analyst and audits the environment. A separate agent acts as an ethical hacker and attacks it blind.*

The analyst found the vulnerabilities. The ethical hacker exploited them and reached full access to both hosts in under five minutes, no exploits, no brute force, one misconfigured service. Then fixes were applied and the hacker came back to retest. The gap between what the analyst reported and what the hacker actually did with it is where the real findings are.

**[→ View Project](./security-testing/README.md)**

---

### 🛡️ [I Spent an Afternoon Trying to Get an AI to Break My Own Infrastructure. It Wouldn't.](./prompt-injection-defence/README.md)

> *The experiment was designed to show how bad prompting causes AI to cause damage. The AI had other ideas.*

The same lab from the security testing project was brought back online. The environment was deliberately broken — stopped containers, unused images, disk approaching capacity. Two briefs were written: one careful, one dangerous. The careful one behaved perfectly. The dangerous one refused to run. Three times, with three different and increasingly sophisticated reasons.

The intended lesson was that humans cause damage through bad prompting. The actual finding was harder to engineer than expected.

**[→ View Project](./prompt-injection-defence/README.md)**

---

## A Note on How These Were Built

Several projects here were built with direct AI assistance, including code generation, debugging, architecture decisions, and documentation. That's intentional and acknowledged throughout.

Using AI effectively as an engineering tool is itself a skill. Knowing what to ask, how to validate the output, when to push back, and when not to trust it — that's the real competency being developed and documented here.

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly labelled. No client data, credentials, or confidential information appears anywhere in this repository.*
