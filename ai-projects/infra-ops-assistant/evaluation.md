# Evaluation

**An honest assessment of JARVIS — what works, what doesn't, and where the real risks are.**

---

## The Central Question, Revisited

*Can AI act as a comprehensive personal assistant for managing IT infrastructure?*

The short answer: **partially, and with important caveats.**

The longer answer is what this page documents. JARVIS is genuinely useful. It also has real limitations and introduces security considerations that any engineer should think carefully about before deploying a similar setup.

---

## Personal Experience & Lessons Learned

*This section is deliberately subjective — it reflects direct, hands-on experience rather than general observations.*

### Hallucinations Are Real

The term "hallucination" describes confident but false, inaccurate, or nonsensical output from an AI model. It is not a rare edge case. It happens regularly, and the danger is not that Claude says something obviously wrong — it is that it says something wrong with exactly the same confidence and tone as when it is right.

In infrastructure work, this matters. A hallucinated command, a fabricated configuration value, or a misremembered hostname can cause real problems if acted on without verification. Treat every output as a draft, not a fact.

### AI Gets Worse the Longer You Chat

This was one of the more surprising discoveries. In a long session — brainstorming an Azure project while implementing it simultaneously — Claude was asked to produce a comprehensive automation script based on everything discussed. By the time the script was written, Claude had effectively lost track of the earlier conversation. The script used new resource names that had never been agreed on, contradicting decisions made earlier in the same session.

The lesson: for complex, multi-step projects, do not rely on a single long conversation. Break work into shorter focused sessions. Agree on names, structure, and decisions early, and document them outside the chat — in a file Claude can read — rather than assuming it will remember.

### Token Limits Have Cost Implications

It is easy to get carried away. Each tool call, each SSH connection, each file read consumes tokens. A long session with many MCP interactions can accumulate cost quickly, especially if you are iterating or exploring rather than executing a clear plan.

Keep an eye on session length and token usage. Claude Code has a `/cost` command that shows consumption for the current session. Use it.

### Automation Is Where It Gets Genuinely Impressive

The most compelling real-world example from this project: building a complete self-hosted infrastructure platform — Proxmox LXC, Debian OS, PostgreSQL, Redis, Nginx, Prometheus, Grafana, and Portainer — provisioned from a single Ansible command.

The Ansible code was written with AI assistance. JARVIS was then asked, in plain English, to run it against the homelab. It did. When two issues arose during deployment, JARVIS diagnosed them, applied fixes, and made notes for the documentation — without being asked to. The entire platform came up cleanly.

That is a genuine preview of what AI-assisted infrastructure automation can look like. It is also a good illustration of why careful human oversight matters: the same capability that deployed a working platform could, with a misunderstood instruction or a hallucinated value, have done significant damage instead.

### The Danger of Just Pasting Commands

This is a hard-won lesson. Early in homelab experimentation — before JARVIS, before proper caution — commands suggested by AI were pasted and run without fully understanding what they did. The result was a broken environment that took significant time to recover.

The homelab survived. A production environment might not have.

AI suggestions should be read, understood, and verified before execution. "It looks right" is not sufficient. The combination of AI confidence and engineer haste is a genuinely dangerous one.

### The Homelab Is Fully Open to JARVIS — By Design, With Eyes Open

For this project, JARVIS has been given broad access: SSH into any device, run commands, read and write files, commit to GitHub. This is a deliberate choice to explore the full capability of the tooling.

It is also a significant security exposure, and one that would be completely unacceptable in a production environment. In a homelab behind a home router with no sensitive data, the risk is manageable. The moment that changes — external exposure, sensitive credentials, real business data — the access model needs to change with it.

### AI Is Still in Its Infancy

The possibilities are genuinely impressive. The risks are equally real. What makes AI tooling valuable in an infrastructure context — its ability to take action, make changes, and operate autonomously — is exactly what makes it dangerous when things go wrong.

The engineers who will use this well are the ones who stay engaged, verify outputs, understand what is being done and why, and never mistake confidence for correctness. AI is a powerful tool. Like all powerful tools, it requires respect.

---

## What Works Well

### Natural Language Operations
The most immediately valuable capability is turning plain English into infrastructure operations. Asking "are any containers down?" and getting a consolidated answer across multiple hosts — without opening terminals, SSHing into systems manually, or running commands yourself — is a genuine productivity gain.

For ad-hoc queries and diagnostics, JARVIS performs well. It handles the mechanics of connecting to the right host, running the right command, and presenting the output clearly.

### Documentation Generation
This was the biggest surprise. Given real infrastructure — a running Docker Compose stack, live container output, an existing documentation repo — Claude produces accurate, well-structured markdown documentation that requires minimal editing. The combination of SSH access to pull live config and GitHub access to commit the results makes documentation feel like a first-class outcome rather than an afterthought.

### Lowering the Barrier to Routine Tasks
Tasks that are slightly tedious — checking logs, verifying service status, pulling image updates, reviewing recent commits — become conversational. The friction of context-switching between terminals, browser tabs, and documentation is reduced significantly.

### Learning Acceleration
For someone building homelab skills, having an AI that can explain what a command does, suggest the right approach to a problem, and generate working configuration is genuinely useful. JARVIS accelerates experimentation.

---

## What Doesn't Work Well

### No Persistent Memory
Every Claude Code session starts completely fresh. CLAUDE.md provides environmental context, but it cannot capture what happened in previous sessions — decisions made, problems encountered, changes implemented. If something was done last Tuesday, JARVIS has no knowledge of it unless it was documented.

This is a fundamental architectural limitation, not a configuration problem. The mitigation is disciplined documentation — which JARVIS can help write, but which still requires the engineer to initiate.

### Confidence Without Accuracy
Claude will sometimes state things confidently that are subtly wrong. In infrastructure operations, subtle inaccuracies matter. Log output misinterpreted, a service dependency incorrectly described, a command that is almost right but not quite — these can cause problems if acted on without verification.

This is not unique to Claude, but it is important to understand. JARVIS is not an authoritative source. It is a capable assistant that still requires human judgement to validate its outputs.

### Context Window Degradation
In long sessions involving many tool calls — SSH connections, file reads, API queries — Claude can begin to lose track of earlier context. Responses become less coherent, or earlier decisions are forgotten. For complex multi-step tasks, breaking work into shorter sessions produces better results.

### Not a Monitoring Platform
JARVIS is useful for on-demand queries. It is not a substitute for a proper monitoring stack. It does not alert, it does not trend, it does not page you at 3am when a container crashes. Prometheus and Grafana remain essential. JARVIS complements them; it does not replace them.

---

## Security Considerations

This is the most important section for anyone considering a similar setup.

### You Are Giving AI Write Access to Live Systems

This is not a sandbox. When JARVIS SSH's into a host and runs a command, it is running on real infrastructure. When it restarts a container, that container actually restarts. When it commits to GitHub, that commit is real.

The MCP servers provide genuine, unrestricted access. The guardrails are:
- The `CLAUDE.md` instruction to confirm before destructive changes
- Your own review of what Claude proposes before saying yes
- Your own judgement about what tasks to delegate

These are soft guardrails. They rely on Claude behaving as expected and on the engineer staying engaged. Neither is guaranteed.

**Mitigation:** Never leave a Claude Code session running unattended. Treat every proposed change as something to review, not rubber-stamp. For anything genuinely destructive — deleting data, modifying firewall rules, changing credentials — consider whether JARVIS should be involved at all.

### Docker API Exposure (Port 2375)

The homelab MCP requires the Docker API to be accessible on port 2375. This port is unauthenticated — anyone who can reach it on the network can control Docker on that host.

Enabling this on a trusted home LAN behind a firewall is an acceptable risk for a homelab. It would be unacceptable in any environment with external exposure, shared network access, or guest WiFi on the same segment.

**Mitigation:** Confirm that port 2375 is firewalled at the router and not exposed externally. Verify with `nmap` from outside the LAN if in doubt. Never enable this in a production or shared environment.

### CLAUDE.md Contains Your Network Topology

The `CLAUDE.md` file describes your entire infrastructure — every host, IP, role, and SSH login. It is designed to be comprehensive, which is exactly what makes it sensitive.

If this file is committed to a public repository, your network topology is public. If it is stored insecurely on your workstation, it is a target.

**Mitigation:** Never commit a real `CLAUDE.md` to a public repository. Use representative IPs and a pseudonym in any published documentation (as this project does). Store the real file locally only.

### GitHub PAT Scope

The GitHub Personal Access Token used by the MCP server has `repo` scope — full access to all repositories, including private ones. If this token is leaked, an attacker has read and write access to everything in your GitHub account.

**Mitigation:** Store the PAT as an environment variable, never hardcoded. Rotate it periodically. Consider using a fine-grained PAT scoped to specific repositories if your GitHub account contains sensitive content.

### Prompt Injection Risk

If JARVIS reads external content — log files, web pages, emails — that content could theoretically contain instructions designed to manipulate Claude's behaviour. This is a known attack vector for AI agents with tool access.

In a homelab context the risk is low, but it is worth being aware of. Be cautious about asking JARVIS to summarise or act on content from untrusted sources.

---

## Verdict

| Capability | Assessment |
|---|---|
| Ad-hoc infrastructure queries | ✅ Genuinely useful |
| Log inspection and diagnostics | ✅ Good, verify outputs |
| Documentation generation | ✅ Surprisingly capable |
| Routine operational tasks | ✅ Useful with human review |
| Autonomous infrastructure management | ⚠️ Possible, but not advisable without oversight |
| Replacing a monitoring stack | ❌ Not a substitute |
| Production environment use | ❌ Not appropriate without additional controls |

JARVIS works best as a force multiplier for an experienced engineer — someone who knows what the right answer should look like and can recognise when Claude gets it wrong. In that context, it is a genuine productivity tool.

It works poorly as a black box that you trust without verification, or as a system operating without human oversight. The risks in that scenario are real.

The most honest summary: **AI can assist with infrastructure management effectively. It cannot yet manage infrastructure autonomously, safely, and reliably.** The gap between those two things is where human judgement still lives — and for now, that gap matters.

---

*This evaluation reflects direct experience with the setup described in this project. Results will vary depending on environment complexity, task type, and how carefully the engineer stays engaged with what the AI is doing.*
