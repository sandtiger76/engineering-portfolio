# Tailscale Setup

[← Back to README](../../README.md) | [← OpenWrt Network Configuration](openwrt-network.md)

---

## What Is It?

Tailscale is a zero-trust overlay network built on WireGuard — a modern, audited VPN protocol. It creates a private, encrypted network between your authorised devices, regardless of where they are physically located.

Unlike a traditional VPN that routes all traffic through a central server, Tailscale creates direct peer-to-peer connections between devices — making it fast, reliable, and simple to operate.

**Why it's in this project:** Tailscale is the access mechanism for everything that should never be publicly accessible — Proxmox, Portainer, Uptime Kuma, and SSH. It provides strong authentication (device must be enrolled and authorised) with zero configuration complexity.

---

## Why We Need It

The management plane — the tools used to operate and maintain the infrastructure — must never be exposed to the internet. Tailscale achieves this without requiring complex firewall rules, VPN servers, or certificate management. Any device enrolled in the Tailnet can reach the management services. Any device not enrolled cannot, regardless of where it is.

---

## Technical Implementation

### Installation

Tailscale is installed on the LXC container via the official installation script.

### Ansible Role

Provisioned by: `ansible/roles/tailscale/`

```yaml
- name: Install Tailscale
  ansible.builtin.shell: |
    curl -fsSL https://tailscale.com/install.sh | sh
  args:
    creates: /usr/bin/tailscale

- name: Authenticate Tailscale
  ansible.builtin.command:
    cmd: "tailscale up --authkey={{ tailscale_auth_key }} --hostname=asi-platform"
  changed_when: false
```

### Auth Key

A Tailscale auth key is required for unattended (non-interactive) device enrollment. This is generated in the Tailscale admin console and stored in Ansible Vault.

**Generate auth key:**
1. Log into [tailscale.com/admin](https://tailscale.com/admin)
2. Settings → Keys → Generate auth key
3. Set expiry to 90 days, mark as reusable
4. Store in Ansible Vault as `tailscale_auth_key`

### What Is Accessible via Tailscale

| Service | Tailscale URL |
|---|---|
| Proxmox UI | https://[tailscale-ip]:8006 |
| Portainer | http://[tailscale-ip]:9000 |
| Uptime Kuma | http://[tailscale-ip]:3001 |
| SSH | ssh root@[tailscale-ip] |

---

## Gotchas & Notes

- Auth keys expire — if rebuilding the platform after key expiry, generate a new one and update Ansible Vault
- `--hostname=asi-platform` sets a friendly name in the Tailscale admin console — makes it easy to identify the device
- Tailscale works behind NAT without any port forwarding — this is one of its key advantages

---

[Next: SSL Certificate Setup →](ssl-certificates.md)
