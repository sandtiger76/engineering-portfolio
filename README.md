# Quintin Boshoff — Engineering Portfolio

**IT Infrastructure Consultant** ·  [LinkedIn](#) 

## About This Portfolio

This portfolio demonstrates hands-on technical capability across two core projects — one focused on Microsoft 365 cloud migration consulting, the other on modern infrastructure engineering using containerisation, infrastructure-as-code, and security best practices.

Each project is documented in layers: a plain-English summary for non-technical readers, and detailed technical documentation for engineers and hiring managers who want to go deeper.

---

## Projects

---

### 📁 Project 1 — SME Cloud Migration: Apex Drafting & Design

> *"How do you move a small business off ageing on-premises infrastructure and into the cloud — with zero data loss, minimal disruption, and a security posture that actually holds up?"*

A full end-to-end Microsoft 365 migration for a fictional 15-person architectural consultancy. Planned and delivered as a sole consultant — from initial discovery through to infrastructure decommission.

| | |
|---|---|
| **Scenario** | On-premises Windows Server, SMB file shares, legacy IMAP email → Microsoft 365 Business Premium |
| **My Role** | Sole consultant — planning, licensing, migration, documentation, decommission |
| **Technologies** | Active Directory · Entra ID · Exchange Online · SharePoint Online · OneDrive · Microsoft Teams · Intune · Conditional Access · SPMT · PowerShell |
| **Highlights** | Full AD to Entra ID identity migration · IMAP to Exchange Online with historical email · CIFS/SMB to SharePoint using SPMT · Intune device compliance + Zero Trust Conditional Access · Infrastructure decommission |

**[→ View Project 1](./project-1-apex-m365/README.md)**

---

### 🖥️ Project 2 — Homelab Infrastructure Platform: Nextcloud Stack

> *"Can you build a production-grade, fully monitored, security-hardened infrastructure platform from scratch — and then rebuild the entire thing from a single command?"*

A self-hosted infrastructure platform running on a Proxmox homelab, demonstrating containerisation, network security, monitoring, and infrastructure-as-code. The entire stack is provisioned via Ansible and version-controlled in Git.

| | |
|---|---|
| **Platform** | Proxmox · Debian LXC · Docker |
| **Application** | Nextcloud — self-hosted collaboration platform (SharePoint/OneDrive equivalent) |
| **Stack** | Nextcloud · PostgreSQL · Redis · Nginx · Let's Encrypt · Prometheus · Grafana · Portainer · Gitea |
| **Security** | VLAN isolation · Tailscale (zero open ports) · SSL/TLS · OS hardening · Fail2ban · UFW |
| **IaC** | Ansible — full stack provisioned from scratch in a single command |

**[→ View Project 2](./project-2-homelab-nextcloud/README.md)**

---

## Technical Skills

| Domain | Technologies |
|---|---|
| **Microsoft 365** | Entra ID · Exchange Online · SharePoint Online · OneDrive · Teams · Intune · Conditional Access |
| **Infrastructure** | Proxmox · VMware · Windows Server · Active Directory · DNS · DHCP |
| **Storage & Migration** | NetApp NAS/SAN · CIFS/SMB · NFS · StorageX · SPMT · AWS & Azure migration tooling |
| **Cloud** | Microsoft Azure · AWS · SharePoint Online · Azure NetApp Files · Cloud Volumes ONTAP |
| **Containerisation** | Docker · Docker Compose · Portainer · LXC |
| **Monitoring** | Prometheus · Grafana · cAdvisor |
| **Automation & IaC** | Ansible · PowerShell · n8n · Bash |
| **Networking** | VLANs · OpenWRT · Tailscale · Nginx · pfSense |
| **Version Control** | Git · Gitea · GitHub |
| **Databases** | PostgreSQL · MySQL |
| **Operating Systems** | Debian/Ubuntu Linux · Windows Server 2016–2022 |

---


*All projects in this portfolio represent real hands-on work. Lab environments are clearly documented where they differ from production. No credentials, client data, or confidential information is included in any repository.*
