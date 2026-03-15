# Phase 5 — Gap Analysis

## Role
You are the **analyst**. All four phases are complete. Produce the document that makes the whole project meaningful — the gap analysis that answers the questions this experiment was designed to answer.

Read everything:
1. `../CLAUDE.md`
2. `../phase1-blue-audit/report.md`
3. `../phase2-red-attack/report.md`
4. `../phase3-blue-remediation/report.md`
5. `../phase4-red-retest/report.md`

---

## The Questions to Answer

**Q1 — The Discovery Gap**
What did Blue Team flag that Red Team independently confirmed?
What did Blue Team flag that Red Team couldn't find?
What did Red Team find that Blue Team missed entirely?

**Q2 — Reported Risk vs Actual Exploitability**
For each Phase 1 finding — did the severity rating match reality?
Was a "Critical" actually exploitable, or theoretical?
Was a "Medium" the thing that gave the attacker most traction?

**Q3 — Remediation Quality**
For each Phase 3 fix — did it actually close the Phase 2 finding?
Did it introduce anything new?

**Q4 — What Remains**
After all four phases, what's still open and why?

---

## Output

Write your analysis to `report.md` in this directory.

Structure:
```
# Phase 5 — Gap Analysis
Date:

## Overview

## Gap Table — Discovery

| Finding | Found by Auditor (P1)? | Found by Attacker (P2)? | Auditor Severity | Actually Exploitable? |
|---|---|---|---|---|

## Key Gaps

### Things the Auditor Found That the Attacker Missed

### Things the Attacker Found That the Auditor Missed

## Severity Calibration

## Remediation Assessment

### Fixes That Worked

### Fixes That Didn't Work

### Fixes That Introduced New Issues

## What Remains Open

| Finding | Why Still Open |
|---|---|

## Conclusions

### What This Experiment Demonstrates

### Limitations of This Experiment

### What Would Happen Next (The Loop)

## Portfolio Summary

| Episode | Title | Key Finding |
|---|---|---|
| 0 | Infrastructure build | |
| 1 | The audit | |
| 2 | The attack | |
| 3 | The gap | |
| 4 | The fix | |
| 5 | The retest | |
```

---

## Important
- This is the document a hiring manager or technical reviewer will read. Write accordingly.
- Be honest about what didn't work or what the experiment couldn't measure.
- Cite specific commands and outputs from the phase reports to support your analysis.
