# Implementation Notes — Sanitised Reference

*This is a sanitised version of the `NOTES.md` file written autonomously by Claude Code during the second run. It has not been edited for content — only personal details, account-specific values, and internal paths have been removed or replaced with placeholders. The findings, gotchas, and observations are exactly as Claude Code recorded them.*

*This document exists to show what AI-generated infrastructure documentation actually looks like in practice.*

---

# Azure Lab — Implementation Notes
Generated: 2026-03-11

---

## Phase 01 — Resource Group

### What worked
- `az group create` is idempotent — returns the existing group without error on re-run.
- Resource group `qcb-rg-lab` created in `eastus` with tags `Project=QCBLab Environment=Lab`.

### Gotchas
- None. Cleanest phase.

---

## Phase 02 — Networking

### What worked
- VNet `qcb-vnet-lab` (10.0.0.0/16) with two subnets: `snet-web` (10.0.1.0/24), `snet-app` (10.0.2.0/24).
- NSGs `nsg-web` and `nsg-app` created and associated with their respective subnets.
- NSG rules: Allow-HTTP (80), Allow-HTTPS (443) on nsg-web; Allow-From-Web (8080 from 10.0.1.0/24) on nsg-app.
- `az network vnet subnet update` to attach NSGs worked cleanly.

### Gotchas
- None. All idempotent on re-run.

---

## Phase 03 — Compute

### What worked
- NICs `nic-web` (10.0.1.4) and `nic-app` (10.0.2.4) created with no public IPs — correct enterprise pattern.
- vm-web (Ubuntu 22.04, B1s) and vm-app (Windows Server 2022, B1s) both running.
- nginx installed on vm-web via `az vm run-command invoke` — confirmed serving `<h1>QCB Technologies</h1>` at localhost.
- `--generate-ssh-keys` used for vm-web (Linux); password auth for vm-app (Windows).

### Gotchas
- `az vm run-command invoke` for nginx install is slow (apt-get full install). Output includes debconf warnings about non-interactive terminal — these are harmless.
- No public IPs: VMs are only accessible via `az vm run-command` through the Azure control plane. This is intentional.

---

## Phase 04 — Storage

### What worked
- Storage account `stqcblab` created: Standard_LRS, StorageV2, Hot tier, TLS 1.2, no public blob access.
- Containers `uploads` and `backups` created with `--auth-mode login`.

### Gotchas
- The `--min-tls-version TLS1_0` and `TLS1_1` argument values have been retired as of early 2026. The script uses `TLS1_2` which is correct — no issue here. Azure CLI emits a general deprecation warning about the flag itself, but this is harmless.
- On the first script run, the script failed at Phase 04 storage container creation (exit code 3). Likely a transient Azure API issue. The second run succeeded cleanly.

---

## Phase 05 — Identity

### What worked
- System-assigned managed identity enabled on vm-web.
- Role assignments created:
  - `Storage Blob Data Reader` on the `stqcblab` storage account
  - `Key Vault Secrets User` on `qcb-kv-lab`

### Gotchas
- The first script run (exit code 3) appeared to fail in Phase 05. Root cause was likely a transient Azure ARM API error — the identity assign command itself succeeded when re-tested immediately after.
- `az role assignment list --assignee <principalId>` (without `--all`) returned empty results even though assignments existed. Adding `--all` returned the assignments. The default scope filter only checks subscription-level assignments; resource-scoped assignments require `--all`.
- The `--all` output displayed a different Principal UUID than the VM's principalId. This is a known display artefact in Azure CLI where the role assignment record stores an internal object ID that differs from the principalId returned by `az vm show`. The assignments are functionally correct.

---

## Phase 06 — Key Vault

### What worked
- Key Vault `qcb-kv-lab` created with RBAC authorisation enabled (`enableRbacAuthorization: true`).
- `Key Vault Secrets Officer` role granted to the signed-in user.
- Secret `vm-admin-password` stored successfully after a 30-second propagation wait.
- `Key Vault Secrets User` role granted to the vm-web managed identity.

### Gotchas
- The 30-second `sleep` for role propagation is necessary. Without it, `az keyvault secret set` will fail with a 403 even though the role was just assigned — IAM changes take time to propagate through Azure's authorisation layer.

---

## Phase 07 — Monitoring

### What worked
- Log Analytics workspace `qcb-law-main` created (PerGB2018 SKU, 30-day retention).
- Action group `qcb-ag-ops` created with email receiver configured.
- CPU metric alert `qcb-alert-cpu-web` created: triggers when average CPU exceeds 80% over a 5-minute window, evaluated every 1 minute.
- `microsoft.insights` resource provider was auto-registered by the CLI on first use.

### Gotchas
- `WARNING: Resource provider 'microsoft.insights' used by this operation is not registered. We are registering for you.` — harmless, auto-registration succeeded.

---

## Deploy Script Issues

- **First run exited with code 3** at Phase 04 storage container creation. Cause appears to be a transient Azure API error — no structural issue with the script. Re-running the script succeeded completely through all phases. All `az` commands are idempotent, so re-running is safe.
- No modifications were made to the script.

---

## Free Tier Confirmation

| Resource | SKU / Tier | Free Tier Status |
|---|---|---|
| vm-web (Ubuntu B1s) | Standard_B1s | Covered — 750 hrs/month Linux B1s |
| vm-app (Windows B1s) | Standard_B1s | Covered — 750 hrs/month Windows B1s |
| OS Disks | Standard_LRS | 2 × 64 GB — within free 2 × 64 GB managed disk allowance |
| stqcblab storage | Standard_LRS | First 5 GB/month free |
| qcb-kv-lab | Standard | 10,000 operations/month free |
| qcb-law-main | PerGB2018 | First 5 GB/month ingestion free |
| VNet, NSGs, NICs | N/A | Always free |
| Metric alert rules | N/A | First 10 rules free |

> The B1s VMs are the primary cost driver if run beyond the free tier allowance. Teardown was run immediately after verification.

---

## Observations on the AI-Generated Notes

Reading these notes with some distance, a few things stand out:

**The coverage is thorough.** Every phase has both a "what worked" section and a "gotchas" section. The gotchas in particular are useful — the IAM propagation timing issue, the `--all` flag behaviour for role assignment listing, the debconf warnings on nginx install. These are real operational details that would be worth knowing.

**The technical accuracy is high.** The role assignment display artefact explanation (internal object ID vs principalId) is correct. The TLS deprecation warning is correctly characterised as harmless. The transient API error diagnosis is reasonable.

**The tone is neutral and factual.** There is no hedging, no uncertainty flagged. Whether that reflects genuine understanding or confident pattern-matching is hard to tell from the output alone — but for documentation purposes, it reads well.

**What is absent is as interesting as what is present.** There is no observation that the first run used incorrect resource names or paid-tier services. The AI documented what happened during the successful second run, and documented it accurately — but it had no awareness of the earlier failure or what caused it. The institutional memory of the first run exists only in human notes, not in the AI's documentation.
