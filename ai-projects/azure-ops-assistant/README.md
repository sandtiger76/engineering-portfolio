# AI Infrastructure Ops — Giving an AI Agent Control of a Real Azure Environment

> *We all know production changes shouldn't be made unless you fully understand their impact. For this experiment, I deliberately stepped away from that rule — giving AI broad control of a test machine and an Azure lab environment, guided only by a defined set of instructions.*
>
> *The results were impressive, but not flawless. Several mistakes were made — most of them preventable — and they reinforced an important lesson: AI can execute quickly and confidently, but it lacks the situational awareness and judgment required to operate safely without supervision.*

---

## The Question

Can an AI agent fully administer a cloud environment from a simple natural language briefing — end to end, without manual intervention?

Not "can it answer questions about Azure" — but can it actually log in, deploy infrastructure, handle errors, document its work, and tear everything back down again?

This project is a direct attempt to find out.

---

## Background

This experiment builds on two earlier projects:

- **[AZ-104 Azure Lab](../aca-project/README.md)** — A hands-on Azure environment built to cover every domain of the AZ-104 exam. The infrastructure (VMs, networking, storage, Key Vault, monitoring) was proven to work and fully documented.
- **[AI Infrastructure Ops Assistant (Homelab)](../ai-projects/infra-ops-assistant/README.md)** — An earlier experiment giving an AI agent (JARVIS) access to a self-hosted homelab via SSH and MCP servers. That project explored what AI-assisted infrastructure operations looked like in practice.

The natural next step was to combine them: take the proven Azure environment from the first project, and hand it entirely to an AI agent to deploy, verify, document, and destroy — with no manual steps.

---

## How It Worked

The workflow had four components working together:

| Component | Role |
|---|---|
| **Claude (chat)** | Brainstormed the Azure architecture and wrote the `CLAUDE.md` briefing file |
| **`CLAUDE.md`** | A plain-text instruction file that gave Claude Code full context — what to deploy, how to verify it, what to document, and when to tear it down |
| **Claude Code** | The AI agent that executed everything: ran the deploy script, handled errors, wrote the implementation notes, ran teardown |
| **MCP Servers** | Gave Claude Code real access to the filesystem and Azure CLI tooling |

The process in plain terms:

1. In a Claude chat session, the Azure architecture was discussed and refined. Claude produced a `CLAUDE.md` file — a structured briefing document that described the environment, gave step-by-step instructions, and set the rules of engagement.
2. Claude Code was pointed at that file and told to execute it from start to finish.
3. Claude Code ran the deploy script, monitored output, fixed issues it encountered, verified each phase of the build, wrote implementation notes, and ran teardown — all autonomously.

---

## What Happened

### First Run — Impressive, But With Errors

The first end-to-end run produced a working Azure environment. Claude Code deployed the infrastructure, handled a transient Azure API error autonomously, and wrote detailed implementation notes.

However, on inspection, two problems were found:

**Wrong resource names.** Some resources were named differently from what had been agreed. Claude had drifted from the original spec — likely a consequence of a long chat session where early context was gradually lost.

**Paid services used instead of free-tier equivalents.** The instructions specified free-tier resources throughout. Claude Code provisioned alternatives that would incur charges. This was a significant failure: in a production context, an AI autonomously selecting paid services without prompting would be unacceptable.

Both issues were caught on review and the environment was torn down immediately.

### Second Run — Full Success

With a fresh context window and tightened instructions, the second run completed without errors. Claude Code:

- Deployed all seven phases of the Azure environment correctly
- Used the exact resource names specified
- Stayed within free-tier limits throughout
- Verified each phase with the prescribed CLI commands
- Wrote structured implementation notes
- Ran teardown and confirmed the resource group was gone

End to end, with no manual intervention.

---

## What This Tells Us

The experiment confirmed something important that is easy to underestimate: **AI agents can be genuinely capable operators — but the quality of their output is tightly coupled to the quality of the instructions they receive, and to how well context is managed across a session.**

The failures in the first run were not random. They were predictable consequences of:

1. **Context drift** — Long chat sessions cause earlier decisions to gradually lose influence. Instructions given at the start of a session carry less weight by the end. For complex multi-step tasks, shorter focused sessions produce better results.
2. **Instruction ambiguity** — "Use free-tier services" is less reliable than specifying exact SKUs and tiers. AI will fill in gaps — not always the way you would.
3. **No situational awareness** — The AI executed confidently without flagging that it had deviated from the agreed spec. It does not know what it does not know.

The second run succeeded precisely because those lessons were applied: fresh context, explicit instructions, exact resource names.

---

## The Honest Assessment

| What worked well | What didn't |
|---|---|
| End-to-end autonomous deployment | Drifted from agreed spec on first run |
| Handled transient cloud API errors without intervention | Selected paid services when free ones were specified |
| Wrote structured, accurate documentation | No self-awareness when deviating from instructions |
| Verified infrastructure state after each phase | Long context sessions are unreliable for complex tasks |
| Clean autonomous teardown | Requires human review before treating output as trustworthy |

This experiment confirmed that AI can be a powerful infrastructure operations assistant. It also confirmed it should not be given unchecked control in a production environment — not because it cannot execute, but because it lacks the judgment to know when it is making a mistake.

---

## Documents

| Document | What it covers |
|---|---|
| [experiment.md](./experiment.md) | Full walkthrough — setup, both runs, what went right and wrong |
| [claude-instructions.md](./claude-instructions.md) | Sanitised version of the `CLAUDE.md` briefing file Claude Code operated from |
| [implementation-notes.md](./implementation-notes.md) | Sanitised version of the implementation notes written autonomously by Claude Code |

---

## Related Projects

- [AZ-104 Azure Lab](../aca-project/README.md) — The Azure infrastructure this experiment deployed
- [AI Infrastructure Ops Assistant (Homelab)](../ai-projects/infra-ops-assistant/README.md) — The earlier homelab experiment that laid the groundwork for this one
