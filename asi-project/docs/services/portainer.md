# Portainer

[← Back to README](../../README.md) | [← Nginx](nginx.md)

---

## What Is It?

Portainer is a web-based management interface for Docker. It provides a visual dashboard for viewing, starting, stopping, and inspecting containers — without needing to use the command line.

Think of it as a control panel for the containerised services running on this platform. It shows the status of every container, resource usage, logs, and network configuration at a glance.

**Why it's in this project:** Portainer demonstrates operational awareness — the ability to monitor and manage a containerised environment beyond just deploying it. It is also the fastest way to diagnose issues during and after deployment.

---

## Why We Need It

When running eight or more containers, keeping track of what is running, what has crashed, and what is consuming resources becomes important. Portainer makes this visual and accessible. It is also a recognised tool in DevOps and infrastructure roles — knowing it is a small but genuine CV point.

**Access:** Tailscale only — `http://[tailscale-ip]:9000`. Never exposed publicly.

---

## Technical Implementation

```yaml
portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - portainer_data:/data
  networks:
    - internal
```

The Docker socket mount (`/var/run/docker.sock`) gives Portainer visibility and control over all containers on the host. This is standard practice but should be noted — it gives Portainer elevated privileges. This is why Portainer is restricted to Tailscale access only.

### Ansible Role

Provisioned by: `ansible/roles/portainer/`

---

## Gotchas & Notes

- Portainer requires initial setup within 5 minutes of first start — after that the setup wizard times out and the container must be restarted. The Ansible role sets the admin password non-interactively via the Portainer API to avoid this.
- Never expose Portainer publicly — the Docker socket mount makes it a high-value target.

---

[← Back to README](../../README.md) | [Next: Uptime Kuma →](uptime-kuma.md)
