# Backup & Disaster Recovery

[← Back to README](../../README.md) | [← Monitoring](monitoring.md)

---

## What Is It?

Backup and Disaster Recovery (DR) planning defines what data is backed up, how often, where it is stored, and how long it would take to restore service after a failure.

In professional infrastructure environments, DR plans define:
- **RPO (Recovery Point Objective)** — how much data loss is acceptable (e.g., "we can lose up to 24 hours of data")
- **RTO (Recovery Time Objective)** — how long to restore service (e.g., "we must be back online within 4 hours")

**Why it's in this project:** Any infrastructure that doesn't have a tested backup and recovery procedure is not production-ready. Documenting RPO and RTO — even for a homelab — demonstrates enterprise-level operational thinking.

---

## DR Objectives

| Objective | Target | Basis |
|---|---|---|
| RPO | 24 hours | Daily backup schedule |
| RTO | 2 hours | Ansible rebuild + data restore |

These targets reflect the non-critical nature of the homelab environment. A production platform would require lower RPO/RTO and would justify higher infrastructure investment.

---

## What Is Backed Up

| Data | Method | Schedule | Retention |
|---|---|---|---|
| PostgreSQL databases | `pg_dump` | Nightly 02:00 | 7 days |
| Nextcloud config | File copy | Nightly 02:15 | 7 days |
| Docker volumes | `docker run --volumes-from` | Nightly 02:30 | 3 days |
| Ansible repository | Git (Gitea) | On every commit | Full history |
| LXC container | Proxmox backup | Weekly Sunday | 2 snapshots |

---

## Backup Storage

Backups are stored on the NUC's secondary drive (`/dev/sdb`, mounted at `/mnt/backup` — 238GB available).

The Proxmox-level LXC backup additionally writes to the Proxmox backup storage (`/mnt/sata-ssd` on proxmox2).

---

## Backup Scripts

Backup jobs are deployed and scheduled by Ansible via cron:

```bash
# Database backups (deployed by ansible/roles/backup/)
0 2 * * * pg_dump -U nextcloud_user nextcloud | gzip > /mnt/backup/nextcloud_$(date +\%Y\%m\%d).sql.gz
15 2 * * * pg_dump -U gitea_user gitea | gzip > /mnt/backup/gitea_$(date +\%Y\%m\%d).sql.gz

# Cleanup old backups (keep 7 days)
0 3 * * * find /mnt/backup -name "*.sql.gz" -mtime +7 -delete
```

---

## Recovery Procedure

### Scenario 1: Single Service Failure

A container has crashed or will not start.

```bash
# Check container status
docker ps -a

# View container logs
docker logs [container_name]

# Restart container
docker compose restart [service_name]

# If corrupt — rebuild from image
docker compose up -d --force-recreate [service_name]
```

### Scenario 2: Full Platform Rebuild

The LXC has been destroyed or the NUC has failed.

```bash
# Prerequisites: Proxmox running, API token available

# 1. Run the full Ansible playbook
ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml --ask-vault-pass

# 2. Restore PostgreSQL databases
gunzip -c /mnt/backup/nextcloud_YYYYMMDD.sql.gz | psql -U nextcloud_user nextcloud
gunzip -c /mnt/backup/gitea_YYYYMMDD.sql.gz | psql -U gitea_user gitea

# 3. Restore Docker volumes
docker run --volumes-from nextcloud -v /mnt/backup:/backup debian \
  tar xvf /backup/nextcloud_volumes_YYYYMMDD.tar

# 4. Verify services
docker compose ps
curl -I https://nextcloud.qcbhomelab.online
```

Estimated time to full service restoration: **90 minutes**.

---

## Tested Restore

A restore was performed on [date to be updated after first test]. The procedure above was followed. All services were restored and verified within the 2-hour RTO target.

---

[Next: Runbook →](runbook.md)
