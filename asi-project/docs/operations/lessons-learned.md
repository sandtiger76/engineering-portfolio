# Lessons Learned

[← Back to README](../../README.md) | [← Runbook](runbook.md)

---

## What This Section Is

This section documents real observations, challenges, and decisions made during the build. It is the most honest part of the project — and often the most valuable to a hiring manager, because it demonstrates genuine hands-on experience rather than a polished tutorial follow-along.

---

## Architecture Decisions in Hindsight

### What I'd Do Differently at Scale

**HashiCorp Vault instead of Ansible Vault**
Ansible Vault encrypts secrets at rest in the repository. In a multi-engineer team environment, HashiCorp Vault would be the appropriate solution — providing dynamic secrets, audit logging, and fine-grained access control. For a single-engineer homelab, Ansible Vault is the pragmatic choice.

**Kubernetes instead of Docker Compose**
Docker Compose is appropriate for this scale. At five or more nodes, or with a requirement for zero-downtime deployments and automatic failover, moving to Kubernetes (k3s for lightweight environments) would be the right call. This project deliberately stays at Docker Compose scale to keep the learning curve manageable while still demonstrating container orchestration.

**Dedicated managed switch for VLAN isolation**
Without a managed switch, true network-layer isolation between the management plane and application tier is not achievable at the physical level. Tailscale provides logical isolation instead. In an enterprise environment, a managed switch with 802.1Q VLAN trunking would be standard.

**Separate PostgreSQL instance per application**
Sharing a PostgreSQL instance between Nextcloud and Gitea is pragmatic on constrained hardware. In production, separate instances (or at minimum separate containers) per application reduces the blast radius of a database incident.

---

## How This Maps to Enterprise Environments

| Homelab | Enterprise Equivalent | Transferable Skill |
|---|---|---|
| Ansible | Ansible Tower / AWX / Terraform | IaC mindset, declarative provisioning |
| Docker Compose | Kubernetes / ECS / Nomad | Container orchestration thinking |
| Ansible Vault | HashiCorp Vault / AWS Secrets Manager | Secrets management discipline |
| Tailscale | Zscaler / Cisco AnyConnect / ZTNA | Zero-trust network access |
| Let's Encrypt | Internal PKI / DigiCert | Automated certificate lifecycle |
| Cloudflare | Akamai / CloudFront / Azure Front Door | CDN and WAF patterns |
| Uptime Kuma | Datadog / PagerDuty / Nagios | Observability and alerting |
| Proxmox | VMware vSphere / Hyper-V / KVM | Hypervisor management |
| Gitea | GitHub Enterprise / GitLab | Source control and GitOps |
| pg_dump backups | Veeam / Commvault / cloud snapshots | Backup strategy and RPO/RTO |

---

## Incidents & Postmortems

*(This section will be updated with real incidents as they occur during operation.)*

### Example: Certificate Renewal Test

**Date:** *(to be updated)*
**Impact:** None — planned test
**Cause:** Tested certbot renewal timer to confirm automation works
**Resolution:** `certbot renew --dry-run` completed successfully. Auto-renewal confirmed operational.
**Learning:** DNS-01 challenge renewal works without any port being open. Confirmed the architectural decision was correct.

---

## What This Project Taught Me

- Infrastructure as Code requires discipline from day one — retrofitting Ansible to an already-running system is harder than designing for automation upfront
- Constrained hardware forces better architecture decisions — every service earns its place
- Documentation written during the build is dramatically better than documentation written after
- The operational wrapper (monitoring, DR, runbooks) around a service matters as much as the deployment itself

---

[← Back to README](../../README.md)
