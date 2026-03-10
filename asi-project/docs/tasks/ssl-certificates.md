# SSL Certificate Setup

[← Back to README](../../README.md) | [← Tailscale Setup](tailscale.md)

---

## What Is It?

SSL/TLS certificates are the technology behind the padlock in your browser's address bar. They encrypt the connection between a user's browser and a web server, preventing anyone from intercepting or tampering with the data in transit.

Let's Encrypt is a free, automated, and open certificate authority. It issues trusted SSL certificates at no cost, with automated renewal. It is the same certificate authority trusted by major browsers and used by millions of websites worldwide.

**Why it's in this project:** Serving a website over plain HTTP in 2025 is unacceptable in any professional context. Automated certificate management — where certificates renew themselves without human intervention — is the expected standard.

---

## Why We Need It

All public services (`nextcloud.qcbhomelab.online`, `gitea.qcbhomelab.online`) must be served over HTTPS. Without a valid certificate, browsers display a security warning and users cannot trust the connection. With automated renewal, there is no risk of certificate expiry causing an outage.

---

## Certificate Details

| Property | Value |
|---|---|
| Type | Wildcard |
| Domains covered | `*.qcbhomelab.online` + `qcbhomelab.online` |
| Issuer | Let's Encrypt E8 |
| Challenge method | DNS-01 via Cloudflare API |
| Certificate path | `/etc/letsencrypt/live/qcbhomelab.online/` |
| Expiry | 2026-06-08 (auto-renews at 30 days remaining) |
| Auto-renewal | `certbot.timer` systemd unit — runs twice daily |

The wildcard certificate covers all current and future `*.qcbhomelab.online` subdomains. Adding a new service requires only a new Nginx vhost — not a new certificate request.

---

## The DNS-01 Challenge Method

There are two ways to prove to Let's Encrypt that you own a domain:

- **HTTP-01 challenge** — Let's Encrypt visits a specific URL on your server. Requires port 80 open from the internet.
- **DNS-01 challenge** — Let's Encrypt asks you to create a temporary DNS TXT record. Ownership proved via the Cloudflare API.

This project uses **DNS-01 exclusively** — it works with zero open ports, is fully automated via the Cloudflare API, and is the only method that supports wildcard certificates.

---

## Technical Implementation

### Prerequisites

```bash
# Install certbot and Cloudflare plugin
apt-get install -y certbot python3-certbot-dns-cloudflare

# Create Cloudflare credentials file
cat > /etc/letsencrypt/cloudflare.ini << EOF
dns_cloudflare_api_token = YOUR_CLOUDFLARE_API_TOKEN
EOF

# Secure the credentials file — certbot refuses to run if world-readable
chmod 600 /etc/letsencrypt/cloudflare.ini
```

### Certificate Issuance

Always test with staging first — Let's Encrypt production has a rate limit of 5 failed certificates per domain per week:

```bash
# Step 1: Staging test (no rate limit)
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d qcbhomelab.online \
  -d "*.qcbhomelab.online" \
  --staging \
  --non-interactive \
  --agree-tos \
  --email admin@qcbhomelab.online

# Verify staging cert was issued
certbot certificates

# Step 2: Delete staging cert
certbot delete --cert-name qcbhomelab.online

# Step 3: Production certificate
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d qcbhomelab.online \
  -d "*.qcbhomelab.online" \
  --non-interactive \
  --agree-tos \
  --email admin@qcbhomelab.online
```

### Verify Auto-Renewal

```bash
# Check renewal timer is active
systemctl status certbot.timer

# Test renewal (dry run — does not issue a new cert)
certbot renew --dry-run

# Check certificate expiry
certbot certificates
```

### Ansible Role

Provisioned by: `ansible/roles/ssl/`

Key variables:
```yaml
base_domain: qcbhomelab.online
letsencrypt_email: admin@qcbhomelab.online
certbot_staging: false        # Set true to test, false for production
cloudflare_api_token: "{{ vault_cloudflare_api_token }}"
```

---

## Cloudflare SSL Mode

Set in Cloudflare dashboard: **SSL/TLS → Overview → Full (strict)**

This verifies that the origin server (Nginx) presents a valid certificate — not just any certificate. Already satisfied since a valid Let's Encrypt wildcard cert is installed. Do not use "Flexible" mode — it allows Cloudflare to connect to the origin over plain HTTP, undermining end-to-end encryption.

---

## Gotchas & Notes

**Always use `--staging` first**
Let's Encrypt production rate limits: 5 duplicate certificates per week per domain. Hitting this during testing locks you out for days. Always test with `--staging`, verify it works, delete the staging cert, then issue production.

**Cloudflare credentials file must be `chmod 600`**
Certbot will refuse to run if `/etc/letsencrypt/cloudflare.ini` is readable by anyone other than root. The Ansible role sets this explicitly.

**Wildcard requires DNS-01 — HTTP-01 cannot issue wildcards**
This is a Let's Encrypt requirement, not a limitation of this setup.

**Certbot installed on host, not in container**
Certbot runs on the LXC host and writes certificates to `/etc/letsencrypt/`. Nginx mounts this directory read-only. This avoids the complexity of running Certbot inside a container.

**Cloudflare API token scope**
The token needs only `Zone → DNS → Edit` permission scoped to `qcbhomelab.online`. Do not use the global API key — a scoped token limits the blast radius if the token is ever compromised.

---

[Next: Ansible Vault →](ansible-vault.md)
