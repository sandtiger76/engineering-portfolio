# Nginx

[← Back to README](../../README.md) | [← PostgreSQL](postgresql.md)

---

## What Is It?

Nginx (pronounced "engine-x") is a high-performance web server and reverse proxy. In this project it acts as the front door to all public-facing services — receiving incoming web requests and routing them to the correct application container.

It also handles SSL termination — meaning it manages the encrypted HTTPS connection with the user's browser, so that the application containers themselves do not need to deal with encryption.

Nginx powers approximately 34% of all websites on the internet. It is the industry standard for this role.

**Why it's in this project:** Without a reverse proxy, each service would need its own port number (`nextcloud.qcbhomelab.online:8080`, `gitea.qcbhomelab.online:3000` etc.), which is insecure and unprofessional. Nginx allows all services to be accessed on standard HTTPS port 443, with routing handled by domain name.

---

## Why We Need It

Nginx performs three critical functions in this architecture:

1. **Reverse proxying** — routes `nextcloud.qcbhomelab.online` to the Nextcloud container and `gitea.qcbhomelab.online` to the Gitea container, all on port 443
2. **SSL termination** — manages the Let's Encrypt certificates, handles the encrypted connection, forwards plain HTTP internally
3. **Security headers** — adds HTTP security headers (HSTS, X-Frame-Options, Content-Security-Policy) to every response

---

## Technical Implementation

### Container Configuration

```yaml
nginx:
  image: nginx:alpine
  container_name: nginx
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/conf.d:/etc/nginx/conf.d:ro
    - ./nginx/ssl:/etc/nginx/ssl:ro
    - certbot_data:/var/www/certbot:ro
  networks:
    - proxy
```

Nginx is the **only** container with ports exposed to the host — ports 80 and 443. All other containers are on internal networks.

### Virtual Host Configuration

Each service gets its own configuration file in `nginx/conf.d/`:

```nginx
# nextcloud.conf
server {
    listen 443 ssl;
    server_name nextcloud.qcbhomelab.online;

    ssl_certificate /etc/nginx/ssl/live/nextcloud.qcbhomelab.online/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/nextcloud.qcbhomelab.online/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;

    location / {
        proxy_pass http://nextcloud:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### HTTP to HTTPS Redirect

All HTTP (port 80) traffic is redirected to HTTPS automatically:

```nginx
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

### Ansible Role

Provisioned by: `ansible/roles/nginx/`

The role handles:
- Deploying the Nginx container
- Placing all virtual host configuration files
- Linking SSL certificate paths
- Reloading Nginx after any configuration change

---

## Gotchas & Notes

- Nginx configuration changes require a reload (`nginx -s reload`) — the Ansible role handles this automatically with a handler
- Nextcloud requires specific proxy headers to function correctly — missing `X-Forwarded-Proto` causes redirect loops
- The Cloudflare proxy changes the client IP — `proxy_set_header X-Forwarded-For` ensures the real client IP is passed through correctly

---

[Next: Portainer →](portainer.md)
