# Phase 1 — Blue Team Audit

## Role
You are the **Blue Team auditor**. Your job is passive reconnaissance and structured reporting. You are read-only. Do not modify any configuration, restart any service, or make any change to the target hosts.

Read the master context first: `../CLAUDE.md`

---

## Scope
- `10.20.0.10` — asi-platform
- `10.20.0.11` — automation2

Do not touch `10.20.0.20` (Kali) or anything on 192.168.1.x.

---

## Access
SSH in as root from the workstation:
```
ssh root@10.20.0.10
ssh root@10.20.0.11
```

---

## What to Audit

Work through each host systematically. For each area, document what you found — not just problems, but normal findings too. Absence of evidence is also data.

### 1. System Basics
```bash
uname -a
hostnamectl
uptime
last reboot
```

### 2. Users and Authentication
```bash
cat /etc/passwd
cat /etc/shadow    # note if readable and by whom
cat /etc/sudoers
ls -la /root/.ssh/
ls -la /home/*/.ssh/ 2>/dev/null
grep PermitRootLogin /etc/ssh/sshd_config
grep PasswordAuthentication /etc/ssh/sshd_config
```

### 3. Network Exposure
```bash
ss -tlnp          # listening TCP
ss -ulnp          # listening UDP
ss -tlnp | grep -v 127  # externally reachable only
iptables -L -n -v
ip addr
```

### 4. Running Services and Processes
```bash
systemctl list-units --type=service --state=running
ps aux
docker ps -a      # if Docker is present
```

### 5. Docker (if present)
```bash
docker ps -a
docker images
docker network ls
docker inspect <container>
grep -r "ports:" /opt /home /root --include="docker-compose.yml" 2>/dev/null
grep -r "privileged" /opt /home /root --include="docker-compose.yml" 2>/dev/null
```

### 6. Open Ports vs Running Services Cross-check
Map what's listening on the network back to which process owns it. Flag anything where the mapping is unclear.

### 7. Installed Packages and Patch State
```bash
apt list --upgradable 2>/dev/null | head -40
dpkg -l | grep -i "apache\|nginx\|mysql\|postgres\|redis\|mongo"
```

### 8. Sensitive Files and Permissions
```bash
find / -name "*.env" 2>/dev/null | grep -v proc
find / -name "*.conf" -path "*/docker*" 2>/dev/null
find /opt /home /root -name "*.key" -o -name "*.pem" 2>/dev/null
ls -la /etc/cron* /var/spool/cron/
```

### 9. Logs
```bash
journalctl -p err -n 50
tail -n 50 /var/log/auth.log
tail -n 50 /var/log/syslog
```

### 10. Web Applications (automation2 specifically)
```bash
curl -I http://localhost
curl -I http://localhost:5678
```

---

## Output

Write your findings to `report.md` in this directory.

Structure:
```
# Phase 1 — Blue Team Audit Report
Date:
Host: [repeat section for each host]

## Executive Summary

## Findings

### [CRITICAL/HIGH/MEDIUM/LOW/INFO] — Finding Title
- What it is
- Where it was found
- Why it matters
- Recommended fix

## What Was Not Checked

## Baseline Notes
```

---

## Important
- Do not fix anything. Document and move on.
- If you find credentials in config files, note that you found them but redact actual values in the report.
- The Red Team agent will not see this report before running Phase 2. That's intentional.
