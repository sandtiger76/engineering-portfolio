# AI Security Testing Project — Master Context

## Project Summary
A documented portfolio experiment: two AI agents with opposing briefs operating against the same isolated lab environment. One defends, one attacks. The goal is not just to find vulnerabilities — it's to measure the *gap* between what an auditor flags and what an attacker actually exploits.

This is a controlled, intentional, and fully authorised engagement. All three hosts are owned and operated by Quintin for research purposes.

---

## Network Layout

| VLAN | Subnet | Notes |
|------|--------|-------|
| LAN | 192.168.1.0/24 | Workstation lives here |
| Lab | 10.20.0.0/24 | Isolated — can reach internet, cannot reach LAN (DNS exception only) |

**Lab Hosts**
| Hostname | IP | Role |
|----------|----|------|
| asi-platform | 10.20.0.10 | Databases, Docker containers |
| automation2 | 10.20.0.11 | Databases, Docker, web servers, n8n |
| kali | 10.20.0.20 | Dedicated security testing machine |

**Firewall Rules**
- LAN → Lab: ACCEPT (workstation can reach all lab machines)
- Lab → LAN: REJECT (lab machines cannot reach 192.168.1.x)
- Lab → DNS (192.168.1.3:53): ACCEPT (AdGuard serves DNS to lab)
- Routing: All traffic through OpenWrt at 10.20.0.1 / 192.168.1.1

**SSH Access (from workstation)**
```
ssh root@10.20.0.10   # asi-platform
ssh root@10.20.0.11   # automation2
ssh root@10.20.0.20   # kali
```

---

## Phase Structure

| Phase | Agent | Brief | Output |
|-------|-------|-------|--------|
| 1 | Blue Team | Read-only audit of 10.20.0.10 and 10.20.0.11 | `phase1-blue-audit/report.md` |
| 2 | Red Team | Active probe from Kali against .10 and .11 only | `phase2-red-attack/report.md` |
| 3 | Blue Team | Implement fixes based on Phase 1 report | `phase3-blue-remediation/report.md` |
| 4 | Red Team | Same scope, post-remediation retest | `phase4-red-retest/report.md` |
| 5 | Analysis | Gap analysis — Phase 1 vs 2, Phase 3 vs 4 | `phase5-gap-analysis/report.md` |

---

## Ground Rules

- **Scope**: 10.20.0.10 and 10.20.0.11 only. Do not target OpenWrt (10.20.0.1), the workstation (192.168.1.197), or anything on 192.168.1.x.
- **Red Team context isolation**: The Phase 2 agent must NOT read Phase 1's report before running. Independent findings only. Compare after.
- **Document everything**: What was tried, what worked, what failed, and why. Partial results are valid data.
- **This doesn't need to fully work or fully fail.** The experiment is the documentation of what happens.

---

## Output Conventions (all phases)

Every report.md should include:
- Date/time the phase was run
- What commands were executed (or attempted)
- Findings with severity ratings where applicable: **Critical / High / Medium / Low / Informational**
- Unexpected behaviour — anything that surprised the agent
- What was *not* checked and why

---

## Episode Structure (Portfolio)

| Episode | Title |
|---------|-------|
| 0 | Infrastructure build — the isolated lab |
| 1 | The audit — read-only AI recon |
| 2 | The attack — AI with permission to probe |
| 3 | The gap — what one missed that the other didn't |
| 4 | The fix — AI remediates its own findings |
| 5 | The retest — did it actually work? |

---

## Current Status
- [x] Phase 1 — Blue Audit
- [x] Phase 2 — Red Attack
- [x] Phase 3 — Remediation
- [x] Phase 4 — Retest
- [x] Phase 5 — Gap Analysis
