# Troubleshooting

> ← [Back to README](../README.md)

Real projects have real problems. Every issue here was encountered during the actual build and is documented so it doesn't need solving twice — and so anyone following this project can see that the path was not a smooth one.

> 💡 **For portfolio readers:** This section is intentionally preserved in full. The ability to diagnose and document problems is as valuable as writing the original code. These are real errors with real fixes.

---

## Quick Diagnostics

Run these first whenever something seems wrong:

```bash
# Are all containers running?
cd /opt/automation && docker compose ps

# Is the portal responding?
curl http://YOUR_HOMELAB_IP:3099/health

# Are there jobs in the database?
docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT COUNT(*) FROM jobs;"

# Did the scrapers run successfully?
docker exec -it postgres psql -U automation -d jobhunt \
  -c "SELECT source, started_at, jobs_found, status FROM scrape_log ORDER BY started_at DESC LIMIT 10;"

# Any container errors?
docker compose logs [service] --tail 50
```

---

## Infrastructure Issues

### n8n: Permission denied on startup

**Error:**
```
Error: EACCES: permission denied, mkdir '/home/node/.n8n'
```

**Cause:** The n8n data folder was created by root. n8n runs as user `node` (UID 1000) and cannot write to a root-owned directory.

**Fix:**
```bash
chown -R 1000:1000 /opt/automation/n8n/data
docker compose restart n8n
```

---

### n8n: Secure cookie error on login

**Error:** Browser shows a cookie-related error or login fails silently.

**Cause:** n8n requires HTTPS for secure cookies by default. The local environment uses HTTP.

**Fix:** Ensure `.env` contains:
```
N8N_SECURE_COOKIE=false
```
Then restart:
```bash
docker compose down && docker compose up -d
```

---

### Prometheus: Failed to start

**Error:**
```
error loading config file: open /etc/prometheus/prometheus.yml: no such file or directory
```

**Cause:** `prometheus.yml` did not exist when the container started. Prometheus fails immediately without its config file — it won't create a default.

**Fix:** Create the file before starting the stack. See [setup-guide.md](setup-guide.md) Step 5 for the correct content. Then:
```bash
docker compose restart prometheus
```

---

### Grafana: Password not updating after `.env` change

**Cause:** Grafana stores its admin password in a persistent volume after first initialisation. Changing `GRAFANA_ADMIN_PASSWORD` in `.env` has no effect on a running instance — the volume takes precedence.

**Fix:**
```bash
docker exec -it grafana grafana-cli admin reset-admin-password NEWPASSWORD
```

---

### Docker Compose: YAML validation error after editing

**Error:**
```
mapping key "service-name" already defined at line X
```
or
```
networks.service-name additional properties not allowed
```

**Cause:** A service block was appended in the wrong location — either after `networks:` instead of inside `services:`, or a block was duplicated.

**Fix:** Check the structure at the bottom of the compose file. The correct order is:

```yaml
  last-service:
    ...

volumes:
  prometheus_data:
  grafana_data:

networks:
  automation:
    driver: bridge
```

Always validate after editing:
```bash
docker compose config --quiet && echo "YAML OK"
```

---

### Container restart hangs at "Restarting"

**Cause:** Normal behaviour for `jobhunt-api`. The container runs `npm install` on every start which takes a few seconds.

**Not a problem.** Wait 10–15 seconds then check:
```bash
docker compose logs jobhunt-api --tail 20
```

Expected output when healthy:
```
JobHunt portal + API running on port 3099
```

---

## Database Issues

### `role "postgres" does not exist`

**Error:**
```
FATAL: role "postgres" does not exist
```

**Cause:** The PostgreSQL container was initialised with a custom user (`automation`), not the default `postgres` superuser.

**Fix:** Always connect as the `automation` user:
```bash
docker exec -it postgres psql -U automation -d jobhunt
```

---

### Schema file contains wrong content after paste

**Symptom:** Running `psql -f schema.sql` produces:
```
ERROR: syntax error at or near "docker"
```

**Cause:** Shell commands were accidentally pasted into the SQL file instead of the SQL content.

**Fix:** Use a heredoc to write files safely:
```bash
cat > /opt/automation/jobhunt-api/schema.sql << 'ENDSQL'
-- paste SQL content here
ENDSQL
```

---

### `invalid input syntax for type date: "null"`

**Error:** Appears when running the expired jobs classifier query.

**Cause:** Different sources publish closing dates in different formats (`2026-03-16` and `16 March 2026`). A direct `::date` cast fails on both when the format doesn't match what PostgreSQL expects.

**Fix:** Use the CASE statement pattern that detects the format by regex:
```sql
CASE
  WHEN j.end_date ~ '^\d{4}-\d{2}-\d{2}$' THEN j.end_date::date
  WHEN j.end_date ~ '^\d{2} \w+ \d{4}$'   THEN TO_DATE(j.end_date, 'DD Month YYYY')
  ELSE NULL
END
```

See [classifier.md](classifier.md) for the full query context.

---

### `column "scraped_at" does not exist`

**Cause:** The schema uses `first_seen` and `last_seen`, not `scraped_at`. This error appears when writing a query using the wrong column name.

**Fix:** Verify column names before writing queries:
```sql
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'jobs'
ORDER BY ordinal_position;
```

---

## n8n Workflow Issues

### Upstream fields missing — showing as `undefined`

**Symptom:** SQL INSERT produces values like `'undefined'` for `source_id`, `title`, etc.

**Cause:** An HTTP Request node only passes its own output. It does not carry forward fields from upstream nodes automatically.

**Fix:** In the Code node that follows the HTTP Request, reference the upstream parse node explicitly:
```javascript
const listing = $('Exact Node Name').item.json;
```
The node name must match exactly as it appears on the n8n canvas.

---

### n8n stops after Postgres node returns no rows

**Cause:** n8n treats a node with no output data as a workflow termination point by default.

**Fix:** Use `INSERT ... ON CONFLICT` instead of SELECT-then-branch patterns. The Postgres node always returns `{"success": true}` from an INSERT regardless of whether the row was new or already existed.

---

### `$1` / `$2` parameter syntax fails in Postgres node

**Error:**
```
there is no parameter $1
```

**Cause:** The n8n Postgres `Execute a SQL query` operation does not support parameterised queries with `$1` syntax.

**Fix:** Switch the query field to expression mode and use inline expressions:
```sql
WHERE source_id = '{{ $json.source_id }}'
```

---

### Expression mode not working — `{{ }}` appears as literal text

**Cause:** Expression mode is not enabled on the field. The toggle must be on the entire field.

**Fix:** Look for the `{}` or `=` toggle icon at the right edge of the field. Click it to switch to expression mode. The field background changes colour when active.

---

### Workflow stops after Loop Over Items with no output

**Cause:** Loop Over Items requires a feedback connection. When all items are processed, the loop exits via its first output. If nothing is connected there, the workflow ends silently after the first item.

**Fix:** Connect the last node in the loop body back to the Loop Over Items input. The loop's first output (index 0) handles loop continuation. The loop's second output (index 1) connects to what happens after all items are processed.

---

## Portal Issues

### Config dialog appears on every page load

**Cause:** No API URL is saved in the browser's local storage.

**Fix:** Click **⚙ Config**, enter `http://YOUR_HOMELAB_IP:3099` as the API Base URL, and click Save. The value persists in that browser from that point.

Alternatively, hard-code the default in `portal.html`:
```javascript
// Find:
apiUrl: localStorage.getItem('jh_apiUrl') || '',
// Change to:
apiUrl: localStorage.getItem('jh_apiUrl') || 'http://YOUR_HOMELAB_IP:3099',
```
Then restart the container.

---

### Portal shows jobs but status buttons don't save

**Symptom:** Clicking a status button appears to work but the status reverts on refresh.

**Cause:** The API URL in Config is incorrect, or the `jobhunt-api` container is not running.

**Fix:**
```bash
# Check container is running
docker compose ps jobhunt-api

# Test the API directly
curl -X POST http://YOUR_HOMELAB_IP:3099/jobs/1/status \
  -H "Content-Type: application/json" \
  -d '{"status":"shortlisted"}'
# Expected: {"ok":true,"id":1,"status":"shortlisted"}
```

---

### Database password hardcoded in docker-compose *(resolved)*

**Issue:** The `jobhunt-api` service had the database password as a plain text value in `docker-compose.yml`.

**Why this matters:** If `docker-compose.yml` is ever committed to a public Git repository, the password is exposed to anyone who finds it.

**Resolution:** Moved to `.env` as `JOBHUNT_DB_PASSWORD`. The compose file now references `${JOBHUNT_DB_PASSWORD}`. Resolved as a deliberate hardening step.

The correct pattern for any service that needs a credential:

1. Add to `/opt/automation/.env`:
```
JOBHUNT_DB_PASSWORD=your_password
```
2. Reference in `docker-compose.yml`:
```yaml
PGPASSWORD: ${JOBHUNT_DB_PASSWORD}
```
3. Ensure `.env` is in `.gitignore`. Never use a plain text value in the compose file.

---

*← [Back to README](../README.md)*
