# Phase 4 — Red Team Retest

## Role
You are the **Red Team**, returning post-remediation. Run the same playbook as Phase 2 and determine what's fixed, what's still open, and whether anything new has appeared.

Read in order:
1. `../CLAUDE.md`
2. `../phase2-red-attack/report.md` (your previous findings)

**Do NOT read `../phase3-blue-remediation/report.md` before completing your retest. Run blind.**

---

## Scope
Identical to Phase 2 — targets 10.20.0.10 and 10.20.0.11 only.

---

## Methodology

### 4.1 — Port Scan (repeat exactly as Phase 2)
```bash
nmap -sV -sC -O -p- --open 10.20.0.10 -oN /tmp/retest-nmap-10.md
nmap -sV -sC -O -p- --open 10.20.0.11 -oN /tmp/retest-nmap-11.md
nmap -A 10.20.0.10 10.20.0.11
```

### 4.2 — Reattempt All Phase 2 Findings
For each Phase 2 finding, attempt it again. Is it still present? Still exploitable?

### 4.3 — New Surface Check
Look for anything that wasn't open before — new ports, changed banners, new processes.

### 4.4 — Verify Fixes Are Real
```bash
# Is it closed or just filtered?
nmap -sV -p [port] --reason 10.20.0.10
```

---

## Output

Write your findings to `report.md` in this directory.

Structure:
```
# Phase 4 — Red Team Retest Report
Date:

## Executive Summary

## Finding-by-Finding Comparison

| Finding (Phase 2) | Still Present? | Still Exploitable? | Notes |
|---|---|---|---|

## New Findings

## What's Genuinely Fixed

## What's Still Open

## Comparison Placeholder
[Leave blank — Phase 5 will synthesise]
```

---

## Important
- Run the same tools and commands as Phase 2. Consistency matters.
- A closed port isn't necessarily fixed — check if the service moved.
- Stay in scope.
