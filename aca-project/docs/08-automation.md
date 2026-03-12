# Phase 08 — Automation

**AZ-104 Domain:** All domains &nbsp;|&nbsp; **Services:** Azure CLI, Bash scripting &nbsp;|&nbsp; **Est. Cost:** Same as running all phases — tear down immediately after testing

---

## Navigation

[← Phase 07](07-monitoring.md) &nbsp;|&nbsp; [README](../README.md)

---

## What We're Building

Two scripts that automate the entire lab lifecycle:

- `scripts/deploy-all.sh` — rebuilds the full environment across all 7 phases in a single run (~15–20 minutes)
- `teardown/destroy-all.sh` — purges the Key Vault and deletes the resource group, removing everything cleanly

This phase demonstrates the principle that infrastructure should be **cattle, not pets** — the environment can be destroyed and recreated at any time from code. It also validates that every command documented in every phase is correct, in the right order, and handles dependencies properly.

---

## The Technology

### Why Automate?

Each phase was built step-by-step to understand what each resource does and why it exists. Automation comes after understanding, not before. The deploy script proves:

- Every command is correct and repeatable
- Dependencies are understood — you cannot create a VM before the VNet exists, cannot assign a Key Vault role before the vault exists
- The environment can be destroyed and recreated to stop costs between sessions
- The entire AZ-104 lab can be validated in a single run

### Design Principles

| Principle | Implementation |
|---|---|
| Exit on any error | `set -e` at the top — script stops immediately if any command fails |
| Variables at the top | All names, sizes, and settings are defined once and referenced throughout |
| Idempotent where possible | `az group create`, `az vm identity assign` and others are safe to re-run |
| Clear section headers | Phase markers in output so you can follow progress and locate failures |
| No public IPs | Intentional — public IP removed from the design entirely |
| Teardown is separate | The destroy script is never called by the deploy script |

### Script Structure

```
deploy-all.sh
├── Variables
├── Phase 01 — az group create
├── Phase 02 — az network vnet create, subnet create ×2, nsg create ×2,
│              nsg rule create ×3, subnet update ×2
├── Phase 03 — az network nic create ×2, az vm create ×2,
│              az vm run-command invoke (nginx install)
├── Phase 04 — az storage account create, az storage container create ×2
├── Phase 05 — az vm identity assign, az role assignment create (storage)
├── Phase 06 — az keyvault create, az role assignment create (KV officer),
│              sleep 30, az keyvault secret set,
│              az role assignment create (KV secrets user)
└── Phase 07 — az monitor log-analytics workspace create,
               az monitor action-group create,
               az monitor metrics alert create

destroy-all.sh
├── Confirmation prompt
├── Step 1 — az keyvault delete + az keyvault purge (with sleep 15)
└── Step 2 — az group delete --yes (blocking, waits for completion)
```

---

## The Deploy Script

Full script at: `scripts/deploy-all.sh`

Key variables:

```bash
LOCATION="eastus"
RG="qcb-rg-lab"
VNET="qcb-vnet-lab"
SNET_WEB="snet-web"
SNET_APP="snet-app"
NSG_WEB="nsg-web"
NSG_APP="nsg-app"
NIC_WEB="nic-web"
NIC_APP="nic-app"
VM_WEB="vm-web"
VM_APP="vm-app"
VM_SIZE="Standard_B1s"
VM_IMAGE_LINUX="Ubuntu2204"
VM_IMAGE_WIN="Win2022Datacenter"
VM_ADMIN="qcbadmin"
VM_PASSWORD="QCBLab2024!Secure"
STORAGE="stqcblab"
CONTAINER_1="uploads"
CONTAINER_2="backups"
KV="qcb-kv-lab"
LAW="qcb-law-main"
ACTION_GROUP="qcb-ag-ops"
ALERT_EMAIL="qcb-alerts@qcbhomelab.online"
TAGS="Project=QCBLab Environment=Lab"
```

---

## Running the Scripts

### Deploy

```bash
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

### Teardown

```bash
chmod +x teardown/destroy-all.sh
./teardown/destroy-all.sh
```

### Expected Timings

| Phase | Approx. time |
|---|---|
| Phase 01 — Resource Group | < 1 minute |
| Phase 02 — Networking | ~2 minutes |
| Phase 03 — Compute | ~10–12 minutes (Windows VM is the bottleneck) |
| Phase 04 — Storage | ~1 minute |
| Phase 05 — Identity | ~1 minute |
| Phase 06 — Key Vault | ~2 minutes (includes `sleep 30`) |
| Phase 07 — Monitoring | ~2 minutes |
| **Total deploy** | **~15–20 minutes** |
| Teardown | ~3–5 minutes |

---

## Verifying the Full Build

After the deploy script completes:

```bash
# Phase 01
az group show --name qcb-rg-lab \
  --query "{Name:name, Location:location, State:properties.provisioningState}" \
  --output table

# Phase 02
az network vnet show --resource-group qcb-rg-lab --name qcb-vnet-lab \
  --query "{Name:name, Space:addressSpace.addressPrefixes}" --output table
az network vnet subnet list --resource-group qcb-rg-lab --vnet-name qcb-vnet-lab --output table

# Phase 03
az vm list --resource-group qcb-rg-lab --show-details --output table
az vm run-command invoke --resource-group qcb-rg-lab --name vm-web \
  --command-id RunShellScript --scripts "curl -s http://localhost | head -3"

# Phase 04
az storage account show --name stqcblab --resource-group qcb-rg-lab \
  --query "{Name:name, SKU:sku.name, TLS:minimumTlsVersion}" --output table

# Phase 05
az vm show --resource-group qcb-rg-lab --name vm-web --query "identity" --output json

# Phase 06
az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab \
  --query "{Name:name, RBAC:properties.enableRbacAuthorization}" --output table
az keyvault secret list --vault-name qcb-kv-lab --output table

# Phase 07
az monitor log-analytics workspace show --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --query "{Name:name, SKU:sku, Retention:retentionInDays}" --output table
az monitor metrics alert list --resource-group qcb-rg-lab --output table
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. First run exited with code 3 at Phase 04 — transient Azure API error.** The script failed at `az storage container create` on the first run with no structural issue. Re-running immediately succeeded through all 7 phases. This is a known behaviour with Azure ARM — transient 5xx errors are possible on first use of a resource type in a new resource group. `set -e` causes the script to exit cleanly rather than continue in a broken state.

**2. All commands are idempotent — re-running is always safe.** `az group create`, `az network vnet create`, `az vm identity assign`, `az keyvault create` and all other commands in the script are safe to re-run. Resources that already exist are returned as-is without error.

**3. `VM_IDENTITY` is set in Phase 05 and reused in Phase 06.** The variable holding the VM's managed identity principal ID is captured in Phase 05 and used again in Phase 06 for the Key Vault role assignment. If running phases independently, re-capture it:

```bash
VM_IDENTITY=$(az vm show --resource-group qcb-rg-lab --name vm-web \
  --query identity.principalId --output tsv)
```

**4. The `sleep 30` in Phase 06 is load-bearing.** Without the pause between assigning `Key Vault Secrets Officer` and running `az keyvault secret set`, the secret creation fails with 403. The sleep is intentional and confirmed necessary.

**5. Teardown uses a confirmation prompt.** `destroy-all.sh` requires you to type `yes` before proceeding. This is intentional — running teardown accidentally would delete everything.

**6. Key Vault purge is required for clean rebuilds.** Without purging after deletion, `qcb-kv-lab` enters soft-delete state for 90 days and the name cannot be reused. The teardown script deletes the vault, waits 15 seconds, then purges it. Subsequent deploy runs can create the vault with the same name immediately.

**7. No PowerShell equivalent for the full deploy script.** The automation is CLI-only (`deploy-all.sh`). Each individual phase documents PowerShell equivalents, but the master automation script uses bash and Azure CLI throughout.

---

## Cost

Running the deploy script and tearing down in the same session costs effectively **$0** — all resources fall within free tier allowances and the session duration is well under the monthly free hour limits.

---

## Navigation

[← Phase 07](07-monitoring.md) &nbsp;|&nbsp; [README](../README.md)
