# Experiment Walkthrough

*A detailed account of both runs — what was attempted, what happened, and what it means.*

---

## The Setup

### The Infrastructure

The Azure environment being deployed was already proven. It had been built manually as part of an earlier AZ-104 study project and covered all five exam domains:

| Phase | What Gets Built |
|---|---|
| 01 — Resource Groups | Resource group with tags |
| 02 — Networking | VNet, two subnets, NSGs |
| 03 — Compute | Linux VM (nginx) + Windows VM, no public IPs |
| 04 — Storage | Storage account, blob containers, TLS 1.2 |
| 05 — Identity | Managed identity, RBAC role assignments |
| 06 — Key Vault | Key Vault (RBAC mode), secrets, identity-based access |
| 07 — Monitoring | Log Analytics workspace, action group, CPU metric alert |

A deploy script (`deploy-all.sh`) and a teardown script (`destroy-all.sh`) already existed and had been tested. The question was not whether the infrastructure worked — it was whether an AI agent could manage the entire lifecycle without human involvement.

### The AI Toolchain

Three components worked together:

**Claude (chat session)** — Used to brainstorm the architecture, discuss the approach, and produce the `CLAUDE.md` briefing file. This was the design and planning layer.

**`CLAUDE.md`** — A plain-text instruction file that acted as Claude Code's operating brief. It described the Azure environment, gave step-by-step instructions for deploying and verifying it, specified what to document and how, and mandated teardown at the end. Think of it as a runbook written specifically for an AI agent.

**Claude Code** — The execution layer. An AI coding and operations assistant that runs locally. It read the `CLAUDE.md` file and executed everything autonomously: deploy, verify, document, teardown.

Before either full run, basic Azure CLI commands were tested with Claude Code to confirm it could authenticate and interact with the Azure control plane. It passed without issue.

---

## First Run — What Happened

### The Plan

A `CLAUDE.md` file was produced in a Claude chat session after a thorough discussion of the architecture. The instructions covered authentication checks, running the deploy script without modification, verifying each phase with specific CLI commands, writing structured implementation notes, and running teardown.

Claude Code was pointed at the file and told to execute it from start to finish.

### Deployment

Claude Code authenticated successfully and ran the deploy script. It worked through all seven phases and handled a real-world complication along the way: a transient Azure API error caused the script to exit at Phase 04 on the first attempt. Claude Code recognised the failure, understood it was transient, and re-ran the script. The second attempt succeeded.

This was a genuine positive result — an AI agent encountering an unexpected error in a live cloud environment and recovering from it autonomously, correctly.

### The Problems

The environment was up and verified. Claude Code had written implementation notes. On review, two problems emerged.

**Wrong resource names.** Several resources had been given names that differed from the agreed specification. The names were plausible — they followed Azure naming conventions — but they were not what had been discussed. Claude had quietly deviated from the spec without flagging it.

**Paid services used instead of free-tier equivalents.** The instructions were explicit: all resources should fall within Azure's free tier. On inspection, some of the provisioned resources would have incurred charges. Claude Code had substituted alternatives without noting it had done so.

The environment was torn down immediately. No charges were incurred because the deviation was caught quickly, but in any real-world context — where someone might not scrutinise every resource — this would have been a costly mistake.

### Why It Happened

The most likely explanation is context drift.

The `CLAUDE.md` file was produced at the end of a long brainstorming chat session. By that point, early decisions — exact resource names, free-tier constraints — had drifted to the edge of the context window. The instructions in `CLAUDE.md` were correct, but they were not specific enough to override Claude Code's tendency to fill in gaps with plausible alternatives.

AI models have a finite context window. In a long session, earlier information carries less weight. Instructions given at the start — "use only free-tier resources", "use exactly these names" — gradually become less influential as the session grows. The model does not know it is drifting; it continues executing with confidence.

The second compounding factor was instruction ambiguity. "Use free-tier services" leaves room for interpretation. An AI will fill that gap. "Use Standard_B1s for both VMs — this is within the Azure free account 750 hours/month allowance" does not.

---

## Second Run — What Happened

### What Changed

Two things changed for the second run:

1. **Fresh context window.** A new chat session was started. No accumulated context from the earlier brainstorming session.
2. **Tightened instructions.** The `CLAUDE.md` file was revised. Resource names were specified explicitly. Free-tier SKUs were named precisely rather than described generally. Rules were tightened: do not invent alternatives, do not rename resources, do not use anything not in the script.

### Deployment

Claude Code ran through all seven phases cleanly. No errors. Every resource was created with the correct name, the correct SKU, and within free-tier limits.

Post-deployment verification confirmed everything was in order:

- VMs running on correct private IPs, no public IPs assigned
- nginx serving the expected response on vm-web
- Managed identity correctly assigned with Blob Data Reader and Key Vault Secrets User roles
- Key Vault secret stored and accessible
- Log Analytics workspace active, CPU alert configured

Claude Code wrote structured implementation notes covering what worked, what edge cases were encountered (a required 30-second IAM propagation wait, a harmless Azure CLI deprecation warning), and a free-tier confirmation table.

Teardown ran cleanly. The resource group was gone within minutes.

### The Result

End to end, with no manual steps, the AI agent deployed a seven-phase Azure environment, verified it, documented it, and destroyed it — correctly.

---

## Side-by-Side Comparison

| | First Run | Second Run |
|---|---|---|
| Deployment completed | Yes | Yes |
| Transient error handled autonomously | Yes | N/A (no errors) |
| Correct resource names | No | Yes |
| Free-tier resources used | No | Yes |
| Documentation written autonomously | Yes | Yes |
| Teardown completed | Yes | Yes |
| Human intervention required | Review + teardown only | Review only |

---

## Key Lessons

### 1 — Context window length affects reliability

Long sessions introduce drift. The AI does not flag when it is losing track of earlier decisions — it continues executing. For complex multi-step tasks, shorter focused sessions with tightly scoped instructions produce significantly better results.

### 2 — Specificity in instructions is not optional

Ambiguous instructions get filled in. "Use free-tier services" is a guideline; an AI will interpret it. "Use Standard_B1s — this SKU is within the free account 750 hours/month allowance" is a constraint. The difference matters when the AI is operating autonomously.

### 3 — AI executes confidently, not cautiously

There was no warning when resources were renamed or when paid services were selected. The AI completed the task and reported success. Confidence in output is not the same as correctness of output. Human review is not optional — it is the control layer.

### 4 — Autonomous error recovery is genuinely useful

The transient Azure API failure in the first run was handled well. The AI identified the failure type, understood it was recoverable, and re-ran the script. This is exactly the kind of operational work that is tedious for humans and well-suited to automation.

### 5 — The workflow scales

The combination of a well-structured briefing file and a capable AI agent can handle real cloud operations work. The infrastructure was non-trivial — seven phases, multiple Azure services, RBAC, Key Vault, monitoring. The AI managed it end to end. The ceiling for this kind of workflow is not obvious yet.

---

## What This Means for Production Use

This experiment used a disposable test environment. The stakes were low: worst case, a few unexpected cloud charges and some time wasted. In a production context, the failure modes are different.

An AI that quietly renames resources or selects unintended SKUs in a production environment could cause service disruption, compliance failures, or unexpected costs at scale. The confidence with which it operates — without flagging deviations — makes it harder to catch, not easier.

The conclusion from this experiment is not that AI agents cannot be used for infrastructure operations. They clearly can. The conclusion is that they require:

- **Tight, explicit instructions** — not guidelines, not descriptions, but constraints
- **Fresh, focused context** for each significant task
- **Human review at defined checkpoints** — especially before any action that cannot easily be reversed
- **Test environments first** — always

An AI agent with the right guardrails is a genuine force multiplier for infrastructure work. Without them, it is a confident agent operating without full situational awareness — and that is a risk profile that belongs in a lab, not production.
