# AI Projects

**In theory, AI can act as a comprehensive personal assistant — capable of designing, building, and managing an IT infrastructure end-to-end. How easily is this to implement? What are the real capabilities, limitations, and risks?**

---

## About This Section

This section documents my hands-on attempt to answer that question. Rather than isolated demos, each project represents a genuine use case — built, tested, and evaluated in a real homelab environment.

The Infrastructure Ops Assistant came first, because it was the most immediate test: give AI real access to live systems, and see what happens. Each project that follows escalates the complexity — moving from infrastructure operations, to automating a real personal workflow, to assisting with complex professional engagements.

Where AI introduced risk — data privacy, credential exposure, over-reliance on generated output, or scraping and copyright considerations — those risks are documented honestly alongside the implementation.

---

## Projects

---

### 🖥️ [AI Infrastructure Ops Assistant](./infra-ops-assistant/README.md)

> *A natural language interface for homelab operations — query your infrastructure, interpret alerts, and surface diagnostics in plain English.*

**The question:** Can AI genuinely manage infrastructure, or does it just assist with it?

**AI role:** Claude Code + MCP servers providing natural language access to SSH, Docker, GitHub, and network monitoring across a real homelab environment.

**[→ View Project](./infra-ops-assistant/README.md)**

---

### 🔍 [Job Intelligence Pipeline](./jobhunt-portal/README.md)

> *A self-hosted job hunting pipeline — automated scraping, structured storage, AI classification, and a web UI for tracking applications.*

**The question:** Can AI automate a real personal workflow end-to-end?

**AI role:** Keyword-based classification with planned Claude API integration for CV-matched scoring and cover letter generation.

**[→ View Project](./jobhunt-portal/README.md)**

---

### 📋 [AI Migration Planner](./migration-planner/README.md)

> *Feed it an environment inventory and get back a structured migration assessment, risk register, and phased plan — grounded in real-world migration practice.*

**The question:** Can AI assist meaningfully with complex professional engagements, and where does human judgement remain essential?

**AI role:** Claude API for analysis and document generation, grounded by structured input from real migration scenarios.

**[→ View Project](./migration-planner/README.md)**

---

## A Note on AI-Assisted Development

Several projects in this section were built with direct AI assistance — including code generation, debugging, and documentation. This is intentional and acknowledged throughout.

Using AI effectively as an engineering tool is itself a skill. Knowing what to ask, how to validate the output, where to push back, and when not to trust it — that's the real competency. These projects document that process honestly.

---

*All projects represent genuine hands-on work. Lab environments and fictional scenarios are clearly labelled. No client data, credentials, or confidential information appears anywhere in this repository.*

