# The AI Experiment

There's no shortage of AI hype. AI will transform IT operations, automate professional work, accelerate development. But most of what gets written is abstract — capability benchmarks, theoretical frameworks, carefully constructed demos that never leave the controlled environment.

This section is different.

Each project starts with a question I have — something that couldn't be answered without actually building it and finding out for myself. The environments are real. The limitations are documented alongside the wins. And where AI introduced genuine risk — security exposure, legal grey areas, over-reliance on generated output — those risks are recorded honestly.

The through-line is the same question asked at increasing levels of complexity:

> *How much can AI actually do — and where does human judgement remain essential?*

---

## Projects

---

### 🖥️ [AI Infrastructure Ops Assistant](./infra-ops-assistant/README.md)

> *Give AI real SSH access to a live homelab. Ask it anything. See what happens.*

You've probably used AI to write infrastructure commands. But what happens when it can *run* them? This project connects Claude to a real multi-host homelab via MCP servers — SSH, Docker, DNS monitoring, GitHub — and explores what a natural language interface to live infrastructure actually looks like in practice.

The result is more capable, and more concerning, than expected.

**Core question:** Can AI genuinely *manage* infrastructure, or does it just assist with it?

**[→ View Project](./infra-ops-assistant/README.md)**

---

### 🔍 [Job Intelligence Pipeline](./jobhunt-portal/README.md)

> *A sysadmin with no development background builds a full-stack data pipeline — with AI as co-engineer.*

Eight job boards. Daily automated scraping. Deduplication, classification, and shortlisting. A self-hosted web portal for tracking applications. Zero cloud dependency. Built by someone who had never written a production application before.

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
