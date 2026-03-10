# Design Decisions (Architecture Decision Records)

[← Back to README](../../README.md) | [← Architecture Overview](ARCHITECTURE.md)

---

## What Is an ADR?

An Architecture Decision Record (ADR) documents a significant design choice — what was decided, why, and what alternatives were considered. This is standard practice in professional engineering teams. It means anyone joining the project (or a hiring manager reviewing it) can understand the reasoning, not just the outcome.

---

## ADR-001 — Single LXC Container vs Multiple VMs

**Decision:** Run all services inside a single LXC container using Docker Compose, rather than separate VMs per service.

**Reasoning:** The Intel NUC has 2 CPU cores and 8GB RAM. Separate VMs would consume significant overhead per service (kernel, memory, disk). A single LXC with Docker achieves process isolation without the resource cost. For a portfolio project this is the pragmatic choice — the containerisation story is Docker, not hypervisor-level isolation.

**Trade-off accepted:** If one service compromises the container, all services are potentially affected. In a production environment with higher stakes, separate VMs or a full Kubernetes cluster would be appropriate.

---

## ADR-002 — Ansible Over Terraform

**Decision:** Use Ansible for all provisioning and configuration management. No Terraform.

**Reasoning:** Terraform excels at cloud infrastructure (AWS, Azure, GCP) where resources are API-driven and ephemeral. This project provisions a single physical host — Ansible is the right tool for that scope. Using both would add complexity without adding value. The project deliberately demonstrates that you don't need cloud spend to demonstrate IaC competency.

**Trade-off accepted:** Ansible is less idempotent than Terraform for infrastructure state. Mitigated by using `--check` mode and tagging playbooks clearly.

---

## ADR-003 — Cloudflare Proxy Over VPN-Only Access

**Decision:** Expose Nextcloud and Gitea publicly via Cloudflare proxy. Keep the management plane (Portainer, Proxmox, Uptime Kuma) private via Tailscale only.

**Reasoning:** A portfolio project that requires a hiring manager to install Tailscale before they can view a demo is a poor experience. Public access via Cloudflare allows anyone to see the running platform. Cloudflare provides DDoS protection and WAF at the free tier — meaningful security at zero cost.

**Trade-off accepted:** Public services have a larger attack surface than Tailscale-only access. Mitigated by Cloudflare WAF, fail2ban, and strong authentication on Nextcloud.

---

## ADR-004 — Let's Encrypt DNS Challenge Over HTTP Challenge

**Decision:** Use Certbot with the Cloudflare DNS-01 challenge for SSL certificates rather than the HTTP-01 challenge.

**Reasoning:** The DNS challenge proves domain ownership by creating a temporary DNS record via the Cloudflare API. This works without opening any inbound ports. The HTTP challenge would require port 80 to be open during renewal — creating a recurring security window. DNS challenge is cleaner, more automated, and works behind Cloudflare's proxy.

**Trade-off accepted:** Requires a Cloudflare API token to be stored securely (handled via Ansible Vault).

---

## ADR-005 — PostgreSQL Over SQLite for Nextcloud

**Decision:** Use PostgreSQL as the Nextcloud database backend rather than the default SQLite.

**Reasoning:** SQLite is acceptable for a single-user test environment but is not suitable for production use with Nextcloud. PostgreSQL demonstrates production-grade database thinking and is the same choice that would be made in an enterprise deployment. It also serves Gitea, avoiding the need for multiple database engines.

**Trade-off accepted:** Slightly more complex to configure and backup. Worth it for the portfolio signal.

---

## ADR-006 — No Open Router Ports

**Decision:** Zero inbound ports forwarded on the router. All inbound traffic routed via Cloudflare proxy. Management via Tailscale.

**Reasoning:** Opening ports is the most common homelab security mistake. Demonstrating that a full, publicly accessible platform can be operated with no open ports is a deliberate and impressive design choice. This maps directly to zero-trust architecture patterns used in enterprise environments.

**Trade-off accepted:** Slightly more complex initial setup. More than compensated by the security posture and the portfolio narrative.

---

[Next: Security Overview →](SECURITY.md)
