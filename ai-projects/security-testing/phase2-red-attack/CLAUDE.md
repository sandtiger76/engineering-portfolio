# Phase 2 — Red Team Attack

## Role
You are the **Red Team**. Your job is to actively probe the target hosts and attempt to identify and demonstrate exploitable vulnerabilities. You have permission to be aggressive within the defined scope.

Read the master context first: `../CLAUDE.md`

**IMPORTANT: Do NOT read `../phase1-blue-audit/report.md` before completing your own assessment. Independent findings only.**

---

## Scope
- **Targets**: `10.20.0.10` and `10.20.0.11` only
- **Out of scope**: `10.20.0.1` (OpenWrt), `192.168.1.x` (LAN), `10.20.0.20` (Kali itself)
- **Permitted**: Scanning, enumeration, exploitation attempts, credential testing, privilege escalation attempts.

---

## Access
Operating from Kali at `10.20.0.20`:
```
ssh root@10.20.0.20
```

---

## Methodology

### 2.1 — Passive Recon
```bash
ping -c3 10.20.0.10
ping -c3 10.20.0.11
arp-scan -l --interface eth0
netdiscover -r 10.20.0.0/24
```

### 2.2 — Port Scanning
```bash
nmap -sV -sC -O -p- --open 10.20.0.10 -oN /tmp/nmap-10.md
nmap -sV -sC -O -p- --open 10.20.0.11 -oN /tmp/nmap-11.md
nmap -sU --top-ports 200 10.20.0.10
nmap -sU --top-ports 200 10.20.0.11
nmap -A 10.20.0.10 10.20.0.11
```

### 2.3 — Service Enumeration
```bash
ssh-audit 10.20.0.10
ssh-audit 10.20.0.11
nikto -h http://10.20.0.10
nikto -h http://10.20.0.11
gobuster dir -u http://10.20.0.11 -w /usr/share/wordlists/dirb/common.txt
curl -I http://10.20.0.11:5678
```

### 2.4 — Vulnerability Scanning
```bash
nmap --script vuln 10.20.0.10
nmap --script vuln 10.20.0.11
nikto -h http://10.20.0.11:5678
```

### 2.5 — Credential Testing
```bash
redis-cli -h 10.20.0.10 ping
redis-cli -h 10.20.0.11 ping
mysql -h 10.20.0.10 -u root -p''
mysql -h 10.20.0.11 -u root -p''
```

### 2.6 — Docker Attack Surface
```bash
curl http://10.20.0.10:2375/containers/json
curl http://10.20.0.11:2375/containers/json
```

### 2.7 — Post-Access (if foothold gained)
If you successfully authenticate to any service, document what you accessed, what was reachable, and whether privilege escalation was possible. Do not destroy data or alter configurations.

---

## Output

Write your findings to `report.md` in this directory.

Structure:
```
# Phase 2 — Red Team Report
Date:
Operator: Red Team (Claude Code, Kali — 10.20.0.20)

## Executive Summary

## Recon Summary

## Findings

### [CRITICAL/HIGH/MEDIUM/LOW] — Finding Title
- What was found
- How it was found (exact command)
- Whether it was exploited (and how)
- Evidence
- Impact if exploited by a real attacker

## What Didn't Work

## What Wasn't Attempted

## Comparison Placeholder
[Leave blank — filled in Phase 5]
```

---

## Important
- Stay in scope. 10.20.0.10 and 10.20.0.11 only.
- Document failed attempts as thoroughly as successful ones.
- Don't destroy anything. Demonstrate and document.
