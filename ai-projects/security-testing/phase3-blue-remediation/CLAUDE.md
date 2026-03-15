# Phase 3 — Blue Team Remediation

## Role
You are the **Blue Team**, now acting on your own findings. Implement fixes for the issues identified in Phase 1, informed by what the Red Team demonstrated was actually exploitable in Phase 2.

Read in order:
1. `../CLAUDE.md`
2. `../phase1-blue-audit/report.md`
3. `../phase2-red-attack/report.md`

---

## Scope
- `10.20.0.10` — asi-platform
- `10.20.0.11` — automation2

---

## Prioritisation
1. Critical findings confirmed exploitable by Red Team
2. Critical findings Red Team didn't reach
3. High findings
4. Medium findings — only if low risk to services
5. Skip Low / Informational unless trivially easy

---

## Before You Start — Snapshot Current State
```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
iptables-save > /root/iptables-before-phase3.rules
systemctl list-units --type=service --state=running > /root/services-before-phase3.txt
docker ps -a > /root/docker-before-phase3.txt
```

---

## Common Fix Patterns

### SSH Hardening
```bash
sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sshd -t && systemctl restart sshd
```

### Bind Services to Localhost
```bash
# Redis example
sed -i 's/bind 0.0.0.0/bind 127.0.0.1/' /etc/redis/redis.conf
systemctl restart redis
```

### Docker API Exposure
```bash
# Remove any -H tcp:// flags from /etc/docker/daemon.json or systemd override
```

### Firewall Rules
```bash
iptables -A INPUT -p tcp --dport 3306 -s 10.20.0.0/24 -j DROP
```

---

## Output

Write your findings to `report.md` in this directory.

Structure:
```
# Phase 3 — Remediation Report
Date:

## What Was Fixed

### Fix 1 — [Title]
- Finding it addresses (Phase 1 severity)
- Red Team confirmed exploitable? (Y/N)
- Exact changes made (before/after)
- How verified
- Risk of fix

## What Was Not Fixed (and Why)

## Unintended Consequences

## Verification

## Pre-Phase 4 State
```

---

## Important
- Test every change before moving on.
- Document the before state of anything you change.
- If a fix breaks something, roll back and document it — that's valid data.
- The Red Team retests in Phase 4 without seeing this report first.
