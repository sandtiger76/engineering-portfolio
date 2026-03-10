# OpenWrt Network Configuration

[← Back to README](../../README.md) | [← Docker Installation](docker.md)

---

## What Is It?

OpenWrt is an open-source Linux-based operating system for routers. It replaces the manufacturer's stock firmware with a fully customisable, community-maintained alternative that provides far greater control over network behaviour.

The Cudy WR3000 router in this project runs OpenWrt 24.10, providing the network foundation the entire platform depends on.

**Why it's in this project:** The router configuration is part of the infrastructure. Documenting it — even when it cannot be fully automated — demonstrates that network thinking is integrated into the design, not an afterthought.

---

## Why We Need It

The router performs three important functions for this platform:

1. **DHCP reservation** — ensures the NUC always receives the same IP address (192.168.1.10)
2. **DNS configuration** — points local DNS to the correct host for `qcbhomelab.online` during development
3. **Firewall baseline** — provides the outer network boundary (no port forwarding — this is a deliberate design choice)

---

## Architecture Note

This is one of the few components that is configured manually rather than via Ansible. The reasons are documented in [ADR-002](../DECISIONS.md) — the OpenWrt Ansible collection is not mature enough for reliable automation, and the router configuration is a one-time bootstrap step that changes rarely.

The configuration is documented here in full so that it can be reproduced exactly if the router is reset or replaced.

---

## Configuration Steps

### 1. Static DHCP Lease (IP Reservation)

Ensures the NUC always receives `192.168.1.10`.

**Via LuCI:** Network → DHCP and DNS → Static Leases → Add

| Field | Value |
|---|---|
| MAC Address | *(NUC's MAC — check Proxmox network tab)* |
| IP Address | 192.168.1.10 |
| Hostname | asi-platform |

### 2. Firewall — Confirm No Port Forwarding

Verify that no port forwarding rules exist for the NUC's IP.

**Via LuCI:** Network → Firewall → Port Forwards

This should be empty. Inbound traffic reaches the platform exclusively via Cloudflare's proxy. This is intentional — see [ADR-006](../DECISIONS.md).

### 3. Local DNS Override (Optional — Development Only)

When testing before Cloudflare DNS propagation, add a local DNS override so `nextcloud.qcbhomelab.online` resolves to the NUC internally.

**Via LuCI:** Network → DHCP and DNS → Hostnames → Add

| Hostname | IP |
|---|---|
| nextcloud.qcbhomelab.online | 192.168.1.10 |
| gitea.qcbhomelab.online | 192.168.1.10 |

Remove these entries once Cloudflare DNS is confirmed working.

---

## VLAN Considerations

The router supports VLAN configuration via DSA (OpenWrt 24.10). In this deployment, a dedicated VLAN for the NUC was considered but not implemented — the NUC has a single NIC and there is no managed switch to carry tagged traffic between physical ports.

The security boundary is provided instead by:
- Tailscale for management plane isolation
- No open ports on the router
- Cloudflare proxy for public traffic

This decision is documented in [ADR-001](../DECISIONS.md). In a production environment with a managed switch, VLAN isolation would be implemented.

---

## Gotchas & Notes

- OpenWrt's LuCI interface may time out during configuration saves — always confirm the change applied by refreshing the page
- The router's default IP is `192.168.1.1` — if this conflicts with your existing network, adjust all IP references in the Ansible inventory accordingly
- After changing DHCP reservations, the NUC may need to release and renew its lease: `dhclient -r && dhclient eth0`

---

[Next: Tailscale Setup →](tailscale.md)
