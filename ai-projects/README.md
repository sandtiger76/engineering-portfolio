# The AI Experiment

AI is everywhere right now. It’s pitched as a game changer for IT operations, development, and professional work — often with bold claims and very little practical context.

I didn’t want to take those claims at face value. I wanted to see for myself what actually works, how easy it really is, and where the risks start to appear.

This section of my portfolio is a collection of hands‑on experiments where I use AI as a tool and see what happens when it’s applied to real problems. Each project starts with a simple question — usually something I’m curious about, or something I’ve wondered whether AI could genuinely help with — and the only way to answer it is to build something and try it.

The work is done in my homelab rather than live production environments, but the systems, constraints, and problems are real. Along the way, I document what worked, what didn’t, what felt genuinely useful, and what raised concerns — including limitations, risks, and security trade‑offs.

> *How much can AI actually do — and where does human judgement remain essential?*


---

## Projects

---

### 🖥️ [AI Infrastructure Ops Assistant](./infra-ops-assistant/README.md)

> *Give AI real SSH access to a live homelab. Ask it anything. See what happens.*

You've probably used AI to write infrastructure commands. But what happens when it can *run* them? This project connects Claude code to a real multi-host homelab via MCP servers — SSH, Docker, DNS monitoring, GitHub — and explores what a natural language interface to live infrastructure actually looks like in practice.

The result is more capable, and more concerning, than expected.

**Core question:** Can AI genuinely *manage* infrastructure, or does it just assist with it?

**[→ View Project](./infra-ops-assistant/README.md)**

---
### ☁️ [AI Azure Ops — Giving an AI Agent Control of a Real Azure Environment](./azure-ops-assistant/README.md)

> *What happens when you stop asking AI to help with infrastructure — and let it run the whole thing?*

We all know production changes shouldn't be made unless you fully understand their impact. For this experiment, I deliberately stepped away from that rule — giving an AI agent full control of a test machine and an Azure environment to deploy, verify, document, and destroy.

**Core question:** Can AI fully administer a cloud environment from a natural language briefing — and what does it get wrong when left unsupervised?

**[→ View Project](./azure-ops-assistant/README.md)**

---

### 🔍 [Job Intelligence Pipeline](./jobhunt-portal/README.md)

> *A sysadmin with no development background builds a full-stack data pipeline — with AI as co-engineer.*

Multiple job boards. Daily automated scraping. Deduplication, classification, and shortlisting. A self-hosted web portal for tracking applications. Zero cloud dependency. Built by someone who had never written a production application before.

This project is two things at once: a useful job hunting tool, and an honest account of what it's like to build something real with AI when you're working outside your area of expertise.

**Core question:** Can AI carry a complete end-to-end build — and what does the human actually need to bring?

**[→ View Project](./jobhunt-portal/README.md)**

---

### 📋 [AI Migration Planner](./migration-planner/README.md)

> *Feed it an environment inventory. Get back a structured assessment, risk register, and phased migration plan.*

Infrastructure migrations are complex, high-stakes professional engagements. They require domain knowledge, client context, and hard-won judgement that doesn't compress easily into a prompt. This project tests how far AI can go — generating real migration artefacts from structured input, grounded in actual migration scenarios.

**Core question:** Can AI assist meaningfully with complex professional work — and where does it fall apart without human expertise behind it?

**[→ View Project](./migration-planner/README.md)**

---

## A Note on How These Were Built

Several projects here were built with direct AI assistance — code generation, debugging, architecture decisions, documentation. That's intentional and acknowledged throughout.

Using AI effectively as an engineering tool is itself a skill. Knowing what to ask, how to validate the output, when to push back, and when not to trust it — that's the real competency being developed and documented here.

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly labelled. No client data, credentials, or confidential information appears anywhere in this repository.*
