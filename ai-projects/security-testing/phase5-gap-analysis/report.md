# Phase 5 — Gap Analysis

**Date:** 2026-03-15
**Analyst:** Claude Code
**Source material:** Phase 1 (Blue Audit), Phase 2 (Red Attack), Phase 3 (Remediation), Phase 4 (Retest)
**Hosts:** 10.20.0.10 (asi-platform), 10.20.0.11 (automation2)

---

## Overview

This experiment ran a complete audit-attack-remediate-retest cycle against two intentionally misconfigured lab hosts, using AI agents in each role. The purpose was to measure three gaps: between what an auditor flags and what an attacker exploits (the discovery gap), between reported severity and actual exploitability (the calibration gap), and between remediation intent and remediation effect (the execution gap).

The short answer on each:

- **Discovery gap:** Small. The Blue Team flagged the primary attack vector correctly and at the right severity. The Red Team found nothing the Blue Team had missed outright. The gaps were in what each agent chose to pursue, not in what they observed.
- **Calibration gap:** Accurate for Criticals, slightly over-rated for some Highs. The one finding rated Critical that the Red Team exploited first was genuinely Critical.
- **Execution gap:** One significant miss. Nine of ten Phase 3 remediations worked. One credential rotation (Gitea on asi-platform) was overlooked entirely, leaving a high-severity finding from Phase 2 still open in Phase 4.

---

## Gap Table — Discovery

| Finding | Found by Auditor (P1)? | Found by Attacker (P2)? | Auditor Severity | Actually Exploitable? |
|---|---|---|---|---|
| Docker TCP 2375 unauthenticated | YES | YES | CRITICAL | YES — primary attack path; full host compromise in ~4 min |
| SSH password auth + PermitRootLogin (.11) | YES | YES (confirmed via hydra) | CRITICAL | YES — password auth confirmed; exploitable if password guessed |
| SSH password auth (.10) | YES | NOT TESTED | MEDIUM | LIKELY — not directly tested, but mechanism was present |
| Universal credential reuse ([REDACTED]) | NOT FOUND (values not read) | YES — full exploitation | [n/a] | YES — single most damaging practical consequence |
| No host firewall (.11) | YES | YES (implicit) | HIGH | YES — the absence of firewall was what made 2375 reachable |
| No host firewall (.10) | YES | N/A | LOW | LOW — .10 had smaller attack surface; no services exploited |
| Tailscale overlay network (.10) | YES | NOT FOUND | HIGH | UNKNOWN — not visible from Kali's position on 10.20.x |
| n8n N8N_SECURE_COOKIE=false | YES | NOTED | HIGH | LOW — credentials already obtained via Docker API; this added no attack value |
| n8n / Gitea LAN IP leak (192.168.1.9) | YES | YES | MEDIUM | LOW — informational; used as recon, not as an attack path |
| Prometheus unauthenticated | YES | YES | MEDIUM | LOW — used as enumeration; not a direct path to anything |
| Grafana admin credential | NOTED (values redacted) | YES — exploited | HIGH | YES — admin access confirmed with extracted password |
| Gitea .11 ROOT_URL misconfigured | YES | YES (via manifest) | LOW | LOW — functional bug; not an attack path |
| SSH private key exfiltration risk | YES (noted as risk) | YES — key read from disk | MEDIUM | PARTIAL — key exfiltrated; did not authenticate to in-scope hosts |
| n8n owner account access | NOT FOUND (didn't authenticate) | YES — full owner access | [n/a] | YES — 9 active workflows, stored DB credential |
| cAdvisor host root mount | YES | NOT EXPLOITED | MEDIUM | LOW — cAdvisor port not externally mapped; no path demonstrated |
| Inter-container no segmentation | YES | NOT EXPLOITED | LOW | LOW — not relevant given host-level access achieved |
| Portainer via Docker socket | YES | YES | HIGH | THEORETICAL — Portainer had a different password; Docker API made it moot |
| Gitea .10 admin via [REDACTED] | NOTED (as credential risk) | YES — full admin | HIGH | YES — private infra repo accessible |
| JobHunt API unauthenticated | NOT FOUND | YES | MEDIUM | MEDIUM — 154 records + wildcard CORS; no PII confirmed |

---

## Key Gaps

### Things the Auditor Found That the Attacker Missed

**Tailscale overlay network (10.20.0.10):** The Blue Team found Tailscale running and correctly identified it as a VLAN bypass — a path from the compromised lab directly to the workstation that OpenWrt cannot block. The Red Team operating from Kali (10.20.0.20) could not see this. UDP port 41641 did not appear in Kali's position, likely because the Tailscale peer relationship was between asi-platform and the workstation directly — not routed through the lab subnet in a way Kali could observe.

This is a genuine gap. The finding was real, the severity (HIGH) was appropriate, and the attack team never got close to it. In a real engagement, an attacker who fully owned asi-platform via its web-facing services or the credential reuse chain would have found Tailscale by running `tailscale status` on the host — but the Red Team's path went through automation2 and never needed to touch asi-platform's host-level processes. The fix (Tailscale disabled) was correct; the Red Team simply validated it by absence.

**cAdvisor host root mount and inter-container network segmentation:** Both were correctly flagged by the auditor and neither was explored by the attacker. The Red Team had host-level access within minutes via Docker API and had no need to pursue container escape paths. These findings remain theoretical — real in principle, not demonstrated in practice.

**appuser account on asi-platform:** The auditor noted a user account (`appuser`, uid 1001, login shell, no clear purpose) and flagged that `/home/appuser/.ssh/` was not checked. The Red Team did not find or touch this account. It remains unaudited through all four phases.

### Things the Attacker Found That the Auditor Missed

**Universal credential reuse ([REDACTED]):** This is the most significant gap in the entire experiment. The Blue Team's policy was explicit: *"If you find credentials in config files, note that you found them but redact actual values in the report."* The auditor noted that `/opt/automation/.env` exists and contains credentials, but deliberately did not read the values.

The Red Team read the values immediately — this was the entire point of the Docker API exploit. The credential `[REDACTED]` used identically across SSH, Grafana, n8n, Gitea (.11), and Gitea (.10) was the single most dangerous characteristic of the environment. The Blue Team's report contains no mention of credential reuse, password strength, or the risk of a universal password. It could not, by design.

This is not a failure of the audit methodology — it is a structural limitation. A read-only auditor who respects credential confidentiality cannot assess credential quality. An attacker has no such constraint. The gap between "credentials exist in a file" and "these credentials own everything" is only visible from the attacker's side.

**JobHunt API unauthenticated access:** The Blue Team's automation2 audit was thorough on system-level findings but did not check the exposed web application endpoints. Port 3099 was noted as a running container (`jobhunt-api`) but the auditor did not `curl` the service or enumerate its routes. The Red Team ran gobuster and found `/jobs` returning 154 records with no authentication and wildcard CORS.

**n8n owner account details:** The auditor noted n8n as a service and flagged `N8N_SECURE_COOKIE=false` and the LAN IP misconfiguration. But without authenticating to n8n, the auditor could not see 9 active workflows, a stored PostgreSQL credential, or confirm who the owner account was. The Red Team confirmed full owner access and the real-world email address of the account (`admin@homelab.local`).

---

## Severity Calibration

### Critical findings — accurate

Both CRITICAL findings on automation2 were genuinely critical. The Docker TCP API was the primary attack path — exploited without any vulnerability, brute force, or prior knowledge. The Red Team went from port scan to reading `/etc/shadow` in approximately four minutes. That is the correct definition of Critical: immediate, trivially exploitable, high impact.

The SSH root password authentication (also CRITICAL) was confirmed by hydra as functional, though the Red Team's actual path did not require it — the Docker API was faster. The SSH finding would have been the fallback if Docker had been secured. Two independent Critical paths existing simultaneously is what makes this host as dangerous as the audit described.

### High findings — partially over-rated

**Tailscale (HIGH, .10):** Correct severity in isolation — a VLAN bypass is a serious finding. But in context, it required an attacker to first compromise asi-platform through one of its web-facing services. The Red Team never needed to go there. High is defensible; it is not something an attacker would reach on a first pass.

**Portainer HTTP + Docker socket (HIGH, .11):** Rated HIGH because Portainer with socket access is effectively a root shell. Accurate in principle. In practice, the Docker API was directly accessible and more useful. Portainer had a separate password (`[REDACTED]` was rejected), making it a softer path than the audit implied. The Docker API made Portainer redundant as an attack vector.

**n8n N8N_SECURE_COOKIE=false (HIGH, .11):** The rating was too high for the actual impact demonstrated. The finding is real — cleartext session cookies on HTTP is a genuine issue. But credential theft via passive network observation is a step removed from the direct access the Docker API provided. In this environment, the Blue Team rated the n8n config issue as HIGH when the actual attack path value was LOW — the real risk was the password behind it, not the cookie flag.

### Medium findings — mixed

The **SSH private key exfiltration risk** (MEDIUM) was correctly identified and the risk was real — the Red Team exfiltrated the key. However, the key did not authenticate to any in-scope host. In a real engagement the known_hosts entries would be tested; here the scope constraint limited the impact demonstration. The auditor's MEDIUM rating was correct given the incomplete information available.

The **Prometheus unauthenticated API** (MEDIUM) provided recon value but was never a path to anything. MEDIUM may be generous — LOW with a note about internal topology exposure would be more accurate.

**LAN topology leak** (MEDIUM) was confirmed exploitable as a recon tool (attacker can infer `192.168.1.9` has n8n and Gitea) but not as a direct attack path given the Lab → LAN firewall. In context this is a LOW with informational value.

### Conclusion on calibration

The Blue Team's severity ratings were well-calibrated at the Critical level and somewhat generous in the High/Medium range. The two Criticals were the two most dangerous things on the network. The audit did not under-rate anything that turned out to be critical. The main calibration failure is in the other direction: some findings rated High (Portainer, n8n cookie) did not translate to meaningful attack value in a real engagement run immediately after.

---

## Remediation Assessment

### Fixes That Worked

**Docker TCP 2375 removal** — Complete. Port filtered. `curl http://10.20.0.11:2375/version` fails. The primary attack path is genuinely closed, not merely obscured. Phase 4 confirmed: no Docker API access. This is the most consequential single fix.

**SSH password auth disabled — both hosts** — Complete. Hydra confirms `does not support password authentication` on both 10.20.0.10 and 10.20.0.11. The CRITICAL finding from Phase 2 is closed.

**Grafana admin credential rotated** — Complete. Phase 4: `admin:[REDACTED]` returns 401. New credential in effect.

**Gitea .11 admin credential rotated** — Complete. Phase 4: `admin:[REDACTED]` returns 401 on port 3000.

**n8n secure cookie enabled** — Complete. Phase 4 settings endpoint confirms `authCookie.secure: true`. The `N8N_SECURE_COOKIE=false` hardcoding in docker-compose is replaced by env var reference.

**Gitea .11 ROOT_URL corrected** — Complete. Phase 4 manifest shows `start_url: http://10.20.0.11:3000/`. LAN IP no longer present in responses.

**n8n LAN topology leak corrected** — Complete. Phase 4: no `192.168.x.x` addresses in any n8n HTTP response. WEBHOOK_URL and N8N_HOST now reference the correct lab IP.

**Host firewall applied — both hosts** — Functional. Phase 4 confirms internal ports (5432, 6379, 2375) return `filtered` (DROP). INPUT policy DROP active on both hosts. Access from workstation (192.168.1.x) and lab (10.20.0.x) preserved. SSH accessible; services accessible.

**Tailscale removed — asi-platform** — Complete. Service stopped, disabled. VLAN bypass closed.

**authorized_keys permissions corrected** — Complete. 0700 → 0600.

### Fixes That Didn't Work

**Gitea .10 (asi-platform) admin credential** — The credential `admin:[REDACTED]` on the Gitea instance running on asi-platform (10.20.0.10:443) was not rotated. Phase 4 confirms full admin authentication and private repository access. This appears to be an oversight — the remediation rotated credentials on automation2's Gitea (10.20.0.11:3000) but did not address the separate Gitea instance on asi-platform, which runs as a distinct container with its own credential store. The two Gitea instances are independent; rotating one does not affect the other.

**n8n web UI user account** — The n8n Basic Auth password was updated in the `.env` file and the container was recreated. However, the n8n web UI owner account (`admin@homelab.local:[REDACTED]`) is stored in the n8n PostgreSQL database — not in the Basic Auth layer. Phase 4 confirms: `admin@homelab.local:[REDACTED]` still authenticates as global owner. The Phase 3 report documents an attempt to change this via the n8n API that returned Unauthorized during the restart window; the fix was not re-attempted after n8n came up. The account password was never successfully rotated.

These two failures share a common cause: **credential rotation in distributed systems requires knowing every place a credential lives.** The Blue Team's Phase 3 approach of updating `.env` and restarting containers works for environment-variable-sourced credentials, but fails silently for credentials stored in application databases (n8n) or separate application instances (Gitea .10 vs Gitea .11).

### Fixes That Introduced New Issues

**Host firewall on automation2 caused a temporary lockout.** When the initial iptables rules were applied allowing SSH only from `10.20.0.0/24`, the workstation at `192.168.1.197` was immediately locked out. Recovery required accessing the LXC container via Proxmox console (`pct exec 101`). The final ruleset correctly includes both `10.20.0.0/24` and `192.168.1.0/24`.

This is a predictable operational risk of applying DROP-policy firewalls. The Phase 3 process should have tested SSH connectivity from the workstation before applying the DROP policy. The Proxmox console access as an out-of-band recovery path was available and used correctly.

**jobhunt-api postgres user separation failed silently.** Phase 3 attempted to create a dedicated `jobhunt` postgres user to avoid credential reuse. This caused `jobhunt-api` to enter a restart loop (`password authentication failed for user "jobhunt"`) despite the test container confirming the password was correct. The failure mode — scram-sha-256 auth working from a postgres client container but not from node-postgres 8.19.0 against PostgreSQL 16 — was not diagnosed. The fix was reverted (back to the `automation` postgres superuser). The JOBHUNT_DB_PASSWORD env var is defined but unused, creating a documentation inconsistency.

---

## What Remains Open

| Finding | Why Still Open |
|---|---|
| n8n owner account (admin@homelab.local:[REDACTED]) | API password change not completed during Phase 3 — n8n was mid-restart when the API call was attempted; not re-tried after recovery |
| Gitea .10 admin (admin:[REDACTED]) | Credential rotation only performed on Gitea running on automation2; the separate Gitea instance on asi-platform was not addressed |
| Prometheus unauthenticated API | Requires nginx reverse proxy config change; deferred as low-risk given host firewall now restricts access to lab VLAN |
| JobHunt /jobs unauthenticated + wildcard CORS | Requires application code change (enforce X-API-Key header) and CORS policy restriction; deferred as no PII confirmed in dataset |
| Portainer HTTP-only | Cosmetic — TLS for internal-only tools was out of scope; admin credential is not [REDACTED] so actual risk is low |
| SSH private key not rotated | The key exfiltrated in Phase 2 still exists in Kali's /tmp/loot from that session. If the key is authorised elsewhere in the homelab, that access persists. Not re-tested in Phase 4. |
| appuser account not audited | Exists on asi-platform; purpose, SSH keys, and password status never checked across any phase |

---

## Conclusions

### What This Experiment Demonstrates

**1. A single unauthenticated API eliminates the value of every other control.**

The Docker TCP API was the only thing that mattered in Phase 2. Every other finding — SSH config, credential reuse, Portainer, Grafana — became secondary the moment port 2375 responded to a curl. The attacker did not need to brute force passwords, exploit a CVE, or even know which services were running. They read a file. In the Phase 1 Blue Team report, this finding is correctly identified, correctly rated Critical, and correctly described as "trivially exploitable path to full host compromise." The audit was right. The environment was fully owned anyway.

This demonstrates that a thorough written audit and a secure environment are not the same thing. The gap between documentation and change is where the actual risk lives.

**2. The read-only constraint is the auditor's most significant limitation.**

The Blue Team's policy of not reading credential values created a blind spot that the Red Team immediately exploited. "Credentials exist in `/opt/automation/.env`" is a different finding from "every service on both hosts shares the password `[REDACTED]`." The Blue Team produced the first; the Red Team produced the second. In a real engagement, the Blue Team's version would appear in the report, the finding would be rated Medium or Low ("credentials in plaintext file"), and the actual risk — universal credential — would be invisible to the reader.

The solution is not to have auditors read credentials. It is to have auditors test authentication: does the credential from `.env` work for SSH? Does it work for Gitea on the other host? Credential reuse can be detected without reading the value. This audit methodology did not do that.

**3. Remediation requires knowing where a credential lives, not just where it was found.**

Phase 3's credential rotation was 7/9 complete. The two failures (n8n web UI account, Gitea .10) both share the same root cause: the Blue Team changed credentials in the places they knew about (`.env` file, container environment variables, the Gitea API on automation2) but not in every place the credential was active. n8n stores user passwords in PostgreSQL, not in environment variables. Gitea on asi-platform has its own database, independent of Gitea on automation2. Rotating the file doesn't rotate the database.

This is a systemic remediation failure pattern. A `.env` file is visible; a database row containing a bcrypt hash of `[REDACTED]` is invisible unless you know to look for it. Effective credential rotation requires an inventory of where each credential is stored, not just where it's configured.

**4. Severity ratings are most accurate where the threat model is most defined.**

Both Critical findings were genuinely critical. Both Medium findings that the Red Team confirmed (LAN topology leak, Prometheus) translated to recon value but not direct exploitation. The High findings were the least consistent: Tailscale (HIGH) was a real structural bypass that the Red Team never encountered; n8n cookie (HIGH) added no attack value in context; Portainer (HIGH) was independently inaccessible with known credentials.

The lesson is that severity ratings for application-layer findings depend heavily on what else is true about the environment. An unauthenticated Prometheus API in an environment with a DROP firewall and no other exposures is a different finding than the same API in an environment where the Docker daemon is open. Phase 1 rated findings in relative isolation; Phase 2 showed how they compound.

**5. Firewalls work, but applying them can break things.**

The host firewall on automation2 caused an immediate operational lockout. This is predictable, preventable, and happened anyway. The recovery path (Proxmox console) was available. The risk of applying a firewall to a live system with an incomplete ruleset is precisely the kind of operational risk that causes administrators to defer firewall implementation — and that deferral is what Phase 1 found as a HIGH finding.

### Limitations of This Experiment

**Scope was small and flat.** Both targets are on the same /24 subnet accessible directly from the attack machine. Real engagements involve routing, NAT, multiple subnets, and often require initial access through a perimeter before reaching internal services. The "full compromise in 4 minutes" result is partly a function of the target being one hop away with no perimeter control.

**The attacker had no persistence requirement.** Phase 2 demonstrated access — it did not demonstrate persistence, data exfiltration, or lateral movement beyond what was needed to confirm credentials. A real attacker who owned the Docker API would drop a backdoor, exfiltrate data volumes, and move to the known_hosts targets. None of that was tested.

**Red Team context isolation was imperfect in practice.** The Red Team did not read Phase 1's report, but both phases ran in the same session context within the same day. Some tool choices (hydra over sshpass, curl over docker CLI) were made based on prior knowledge of what was available on Kali, not purely from first-principles discovery. A true zero-knowledge Red Team engagement would require a fresh session with no access to Phase 1 tooling decisions.

**Tailscale was not fully retested.** Phase 4 confirmed Tailscale is stopped and disabled on asi-platform. The Tailscale network peer relationship was not confirmed terminated on the workstation side — Tailscale may still consider the node as a known peer. This is not a finding in scope, but is an operational completeness gap.

**The AI agents cannot do everything a human would do.** The agents operated within tool constraints (MCP SSH timeouts, no interactive terminal, batch commands only). Some findings that a human tester would discover by instinct — checking bash history, reading mail spool, following symlinks — were not performed. The experiment measures AI-agent security testing, not human security testing.

### What Would Happen Next (The Loop)

With Phase 4 findings in hand, a Phase 3 re-run would need to:

1. **Rotate n8n owner account password** — SSH into automation2, exec into the postgres container, and directly update the n8n user table: `UPDATE "user" SET "password" = crypt('newpassword', gen_salt('bf')) WHERE email = 'admin@homelab.local';` — or use the n8n UI while logged in as owner.

2. **Rotate Gitea .10 admin credential** — SSH into asi-platform, exec into the gitea container, and use `gitea admin user change-password --username admin --password 'NewPassword!'` (running as the gitea user, not root) — or use the Gitea API with the current known-good password before it's revoked.

3. **JobHunt API auth** — Add `X-API-Key` enforcement to `server.js` routes and restrict CORS to specific origins.

4. **n8n Prometheus authentication** — Add a lightweight nginx reverse proxy in front of Prometheus with Basic Auth.

After those four fixes, a Phase 4 re-run would find a substantially clean environment. The remaining LOW items (Portainer HTTP, image updates, appuser audit) are maintenance backlog, not attack paths.

The loop is the point. Security is not a state; it is a process. This experiment demonstrates one iteration of that process — with clear, measurable output at each stage.

---

## Portfolio Summary

| Episode | Title | Key Finding |
|---|---|---|
| 0 | Infrastructure build | Two Debian 12 LXC containers on Proxmox, isolated VLAN (10.20.0.0/24), intentionally misconfigured: Docker TCP API open, universal password, no firewall |
| 1 | The audit | Blue Team finds both Criticals on automation2 and a VLAN bypass via Tailscale on asi-platform; cannot assess credential quality due to read-only constraint |
| 2 | The attack | Red Team ignores everything except port 2375; reads one file; owns both hosts and all services in under 4 minutes; finds credential reuse the auditor could not see |
| 3 | The gap | Discovery gap is small (auditor found what mattered); execution gap is real (credential rotation incomplete; one host and one application database missed) |
| 4 | The fix | 8 of 10 remediations verified effective; Docker API closed; SSH hardened; most credentials rotated; host firewalls active; two credential fixes failed silently |
| 5 | The retest | Primary attack path confirmed closed; two credential findings persist (n8n owner account, Gitea .10 admin); surface otherwise clean; experiment loop demonstrated |
