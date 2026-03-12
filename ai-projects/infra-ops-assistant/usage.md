# Usage Guide

**Real examples of JARVIS in action — what was asked, what happened, and what it tells us.**

---

## How to Use It

Launch Claude Code from your working directory:

```bash
cd ~/Documents/claude
claude
```

Claude Code reads `CLAUDE.md` automatically and has full context about your environment from the first prompt. No setup required each session — just start talking.

There are no special commands to learn. You interact in plain English. Claude decides which tools to use, which hosts to connect to, and how to structure the response.

---

## Example Interactions

The examples below are drawn from real sessions. They are grouped by type to show the range of what is possible.

---

### Infrastructure Queries

These are the simplest use case — asking questions about the state of the environment.

**Prompt:**
```
Give me a summary of all running VMs and containers across both Proxmox hosts
```

**What JARVIS did:**
SSH'd into both Proxmox hosts, ran `qm list` and `pct list`, and returned a consolidated summary table with VMID, name, status, and host.

**Why this is useful:**
A task that would normally require opening two browser tabs, logging into two Proxmox UIs, and mentally consolidating the output — done in one prompt.

---

**Prompt:**
```
Are any Docker containers down on automation or docker?
```

**What JARVIS did:**
Used the homelab MCP to query both Docker hosts simultaneously and returned a list of container names, status, and uptime — flagging anything not in a running state.

---

### Diagnostic Tasks

**Prompt:**
```
Nextcloud on automation is running slowly. Check the container resource usage and look at the last 50 lines of the Nextcloud log
```

**What JARVIS did:**
SSH'd into `automation`, ran `docker stats --no-stream` to capture resource usage, then ran `docker logs nextcloud --tail 50`. Returned both outputs with a brief summary of anything that looked unusual.

**Observation:**
Claude interpreted "looks unusual" based on general knowledge of Nextcloud log patterns — it flagged a database connection warning that turned out to be relevant. This is a genuine example of AI adding analytical value, not just retrieving data.

---

### Documentation Tasks

This is where JARVIS proved unexpectedly capable.

**Prompt:**
```
SSH into automation, inspect the full Docker Compose stack, and write a markdown summary 
of every service — what it does, what port it runs on, and what it depends on
```

**What JARVIS did:**
SSH'd into `automation`, read the `docker-compose.yml`, ran `docker compose ps`, and produced a structured markdown document — including a dependency diagram in text form. The output required minimal editing before being committed to the documentation repo.

---

**Prompt:**
```
I've just added a new container to the stack. Update the infrastructure documentation 
to reflect the changes and commit it to GitHub
```

**What JARVIS did:**
Read the existing documentation file, identified the relevant section, made the update, then used the GitHub MCP to commit and push the change with an appropriate commit message.

**Observation:**
This is a genuinely useful workflow for keeping documentation in sync with a fast-moving homelab. The risk is discussed in [evaluation.md](./evaluation.md).

---

### Operational Tasks

**Prompt:**
```
The automation container hasn't been updated in a while. 
Pull the latest images and recreate any containers that have updates available
```

**What JARVIS did:**
SSH'd into `automation`, ran `docker compose pull` to check for updated images, reported which services had updates available, and asked for confirmation before running `docker compose up -d` to recreate the affected containers.

**Important:** Claude asked for confirmation before making changes. This is expected behaviour when `CLAUDE.md` includes the instruction *"always confirm before making destructive changes"*. It did not just proceed — it presented the plan and waited.

---

### Network and DNS

**Prompt:**
```
How many DNS queries has AdGuard processed today, and what are the top 5 blocked domains?
```

**What JARVIS did:**
Used the homelab MCP to query AdGuard's API and returned query counts, block rate, and top blocked domains in a formatted table.

---

### GitHub and Documentation Workflow

**Prompt:**
```
Show me the last 5 commits across my engineering portfolio repo 
and summarise what changed
```

**What JARVIS did:**
Used the GitHub MCP to retrieve recent commits, then summarised the changes in plain English — useful for picking up where you left off after a break.

---

## Effective Prompting Patterns

After regular use, a few patterns consistently produce better results:

**Be specific about scope:**
> "Check containers on `automation` only" is better than "check containers"

**State what you want done with the output:**
> "SSH into debian and check disk usage — write the results to a markdown file in my docs repo" gives Claude a complete task rather than a partial one

**Reference CLAUDE.md context explicitly when needed:**
> "Using the hosts defined in my config, check which ones are currently reachable" reminds Claude to use its context rather than making assumptions

**Ask for a plan before execution on risky tasks:**
> "What would you do to rotate the AdGuard admin password? Don't do it yet — just tell me the steps" is a useful safety pattern before letting Claude make changes

---

## What It Does Not Do Well

See [evaluation.md](./evaluation.md) for the full assessment, but a brief summary of the limitations encountered in practice:

- **No persistent memory** — every session starts fresh. CLAUDE.md compensates for this, but anything that happened in a previous session is unknown to Claude unless documented
- **Context window limits** — very long sessions with many tool calls can cause Claude to lose track of earlier context
- **Confidence without accuracy** — Claude will occasionally state something confidently that is subtly wrong. Output should be verified, especially for anything operational
- **Not a replacement for monitoring** — JARVIS is useful for ad-hoc queries and diagnostics, but it is not a substitute for Prometheus, Grafana, and alerting

---

## A Typical Session

To give a sense of how this fits into a real workflow:

```
1. cd ~/Documents/claude && claude
2. "Give me a quick health check — any containers down, any hosts unreachable?"
3. Review the output, follow up on anything flagged
4. "The grafana container restarted overnight — check the logs and tell me why"
5. Investigate, make any fixes needed
6. "Document what we found and what we changed, and commit it"
7. Done
```

The entire workflow — health check, diagnosis, fix, documentation, commit — handled in a single session through natural language. That is the core value proposition, and in practice it largely delivers on it.
