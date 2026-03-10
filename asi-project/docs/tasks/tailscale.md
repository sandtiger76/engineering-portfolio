# Tailscale Setup

[← Back to README](../../README.md) | [← OpenWrt Network Configuration](openwrt-network.md)

---

## What Is It?

Tailscale is a zero-configuration VPN built on WireGuard. It creates a private encrypted network (called a "Tailnet") between your devices, regardless of where they are physically located or what network they're on.

Unlike a traditional VPN, Tailscale is peer-to-peer — devices connect directly to each other rather than routing all traffic through a central server. It requires no port forwarding, no firewall rules, and no public IP address.

**Why it's in this project:** Management interfaces (Proxmox, Portainer, Uptime Kuma) must never be exposed to the public internet. Tailscale provides secure access to these interfaces from anywhere without opening a single port on the router.

---

## Why We Need It

The management plane is completely separated from the public plane:

| Access type | How it works |
|---|---|
| Nextcloud, Gitea | Public via Cloudflare proxy — no direct IP exposure |
| Proxmox, Portainer, Uptime Kuma, SSH | Tailscale only — never reachable from the public internet |

Even if someone discovers the server's public IP, the management interfaces are unreachable — they only respond on the Tailscale network.

---

## Technical Implementation

### Tailscale IP Addresses

| Device | Tailscale IP |
|---|---|
| asi-platform | 100.114.7.81 |
| quintin-m70q (laptop) | 100.123.183.26 |

### Installation (Debian 12 Bookworm)

```bash
# Add Tailscale GPG key
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg \
  | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null

# Add apt repository
echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] \
  https://pkgs.tailscale.com/stable/debian bookworm main" \
  | tee /etc/apt/sources.list.d/tailscale.list

# Install
apt update && apt install -y tailscale

# Enable daemon
systemctl enable --now tailscaled

# Authenticate (unattended)
tailscale up \
  --authkey=tskey-auth-YOURKEY \
  --hostname=asi-platform \
  --accept-routes=false
```

### Proxmox LXC — TUN Device Setup

Tailscale requires `/dev/net/tun` inside the LXC container. This must be configured on the **Proxmox host** before starting Tailscale.

> **Note:** `pct set <vmid> --features tun=1` does not work on Proxmox 6.17+ — the `tun` feature was removed from the schema. Use the direct config file method instead:

```bash
# On the Proxmox host (not inside the LXC)
echo "lxc.cgroup2.devices.allow: c 10:200 rwm" >> /etc/pve/lxc/100.conf
echo "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file" >> /etc/pve/lxc/100.conf

# Restart the LXC for changes to take effect
pct restart 100
```

Verify the device exists inside the container:
```bash
ls -la /dev/net/tun
# crw-rw-rw- 1 root root 10, 200 ...
```

### Auth Key Settings

| Setting | Value | Reason |
|---|---|---|
| Reusable | OFF | Single-use is more secure for a known host |
| Ephemeral | OFF | Device must persist across reboots |
| Pre-authorized | ON | Skips admin approval — required for unattended install |

Generate at: https://login.tailscale.com/admin/settings/keys

### Tailscale Flags

| Flag | Value | Reason |
|---|---|---|
| `--authkey` | from Vault | Unattended authentication |
| `--hostname` | `asi-platform` | Matches LXC hostname in admin console |
| `--accept-routes` | `false` | Management access only — no traffic routing |

### Verification

```bash
tailscale ip -4       # Shows 100.x.x.x address
tailscale status      # Shows all peers on the Tailnet
```

Check admin console: https://login.tailscale.com/admin/machines — `asi-platform` should show as Connected.

### Ansible Role

Provisioned by: `ansible/roles/tailscale/`

The role uses idempotency via `tailscale status --json` — checks `.BackendState == "Running"` before running `tailscale up`. This prevents consuming a single-use auth key on re-runs.

The `tailscale up` task uses `no_log: true` — the auth key never appears in Ansible output or logs.

The Proxmox LXC config entries (`lxc.cgroup2.devices.allow` and `lxc.mount.entry`) must be applied to the Proxmox host **before** running the Ansible role — these are not automated since they require Proxmox host access and an LXC restart.

Key variables (stored in Ansible Vault):
```yaml
tailscale_auth_key: "{{ vault_tailscale_auth_key }}"
```

---

## Gotchas & Notes

**`pct set --features tun=1` fails on Proxmox 6.17+**
The `tun` feature was removed from the LXC schema in newer Proxmox versions. Use the direct `/etc/pve/lxc/100.conf` method instead. The error message is: `features.tun: property is not defined in schema`.

**LXC must be restarted after adding TUN device**
Adding the cgroup and mount entries to `/etc/pve/lxc/100.conf` does not take effect until `pct restart 100` is run. Tailscale will fail with `503 Service Unavailable: no backend` until this is done.

**`503 Service Unavailable: no backend` error**
This means `tailscaled` is running but cannot access `/dev/net/tun`. The fix is to add the TUN device to the LXC config and restart the container — not to restart tailscaled.

**Auth key is consumed on first use**
Tailscale single-use auth keys cannot be reused. If the playbook needs to re-authenticate (e.g. after a reinstall), generate a new key. The Ansible idempotency check prevents accidentally consuming the key on re-runs when already authenticated.

**`--accept-routes=false` is explicit**
Without this flag, Tailscale may accept subnet routes advertised by other nodes on the Tailnet. Setting it explicitly ensures this host only uses Tailscale for direct peer access.

---

[Next: SSL Certificate Setup →](ssl-certificates.md)
