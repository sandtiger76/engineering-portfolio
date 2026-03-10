# SSL Certificate Setup

[← Back to README](../../README.md) | [← Tailscale Setup](tailscale.md)

---

## What Is It?

SSL (Secure Sockets Layer) certificates — more accurately called TLS certificates — are the technology behind the padlock in your browser's address bar. They encrypt the connection between a user's browser and a web server, preventing anyone from intercepting or tampering with the data in transit.

Let's Encrypt is a free, automated, and open certificate authority. It issues trusted SSL certificates at no cost, with automated renewal. It is the same certificate authority trusted by major browsers and used by millions of websites worldwide.

**Why it's in this project:** Serving a website over plain HTTP in 2025 is unacceptable in any professional context. Automated certificate management — where certificates renew themselves without human intervention — is the expected standard.

---

## Why We Need It

All public services (`nextcloud.qcbhomelab.online`, `gitea.qcbhomelab.online`) must be served over HTTPS. Without a valid certificate, browsers display a security warning and users cannot trust the connection. With automated renewal, there is no risk of certificate expiry causing an outage.

---

## The DNS-01 Challenge Method

There are two ways to prove to Let's Encrypt that you own a domain:

- **HTTP-01 challenge** — Let's Encrypt visits a specific URL on your server to verify ownership. Requires port 80 to be accessible from the internet.
- **DNS-01 challenge** — Let's Encrypt asks you to create a specific DNS record. Ownership is proved by successfully creating that record via the Cloudflare API.

This project uses the **DNS-01 challenge** — it works without any open ports, is fully automated via the Cloudflare API, and is compatible with Cloudflare's proxy mode.

---

## Technical Implementation

### Certbot with Cloudflare Plugin

Certbot is the Let's Encrypt client. The Cloudflare DNS plugin handles the DNS challenge automatically.

### Ansible Role

Provisioned by: `ansible/roles/ssl/`

```yaml
- name: Install Certbot and Cloudflare plugin
  ansible.builtin.apt:
    name:
      - certbot
      - python3-certbot-dns-cloudflare
    state: present

- name: Create Cloudflare credentials file
  ansible.builtin.copy:
    content: |
      dns_cloudflare_api_token = {{ cloudflare_api_token }}
    dest: /etc/letsencrypt/cloudflare.ini
    mode: '0600'

- name: Obtain certificate
  ansible.builtin.command:
    cmd: >
      certbot certonly
      --dns-cloudflare
      --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini
      -d nextcloud.qcbhomelab.online
      -d gitea.qcbhomelab.online
      --non-interactive
      --agree-tos
      --email {{ admin_email }}
    creates: /etc/letsencrypt/live/nextcloud.qcbhomelab.online/fullchain.pem
```

### Automatic Renewal

Certbot installs a systemd timer that attempts renewal twice daily. Certificates are renewed when they have less than 30 days remaining. No manual action is ever required.

```bash
# Check renewal timer status
systemctl status certbot.timer

# Test renewal (dry run)
certbot renew --dry-run
```

---

## Gotchas & Notes

- The Cloudflare API token must have `Zone → DNS → Edit` permission — scoped to your specific zone only
- Certificates are stored in `/etc/letsencrypt/live/` — the Nginx configuration references these paths
- Let's Encrypt has rate limits — 5 certificates per domain per week. Use `--staging` flag during testing to avoid hitting limits
- The `cloudflare.ini` credentials file must be readable only by root (`chmod 600`) — Certbot will refuse to run if the file is world-readable

---

[Next: Ansible Vault →](ansible-vault.md)
