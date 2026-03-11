# Phase 08 — Automation

| | |
|---|---|
| **Phase** | 08 |
| **Topic** | Full Environment Automation |
| **Services** | Azure CLI, PowerShell, Bash scripting |
| **Est. Cost** | Same as running all phases — delete immediately after testing |

---

## Navigation

[← Phase 07: Monitoring](07-monitoring.md) | [Back to README](../README.md)

---

## What We're Building

A single script (`scripts/deploy-all.sh`) that rebuilds the entire QCB lab environment from scratch — every resource from every phase, in the correct order, with proper dependency handling. And a matching teardown script (`teardown/destroy-all.sh`) that removes everything cleanly.

This is the payoff of the entire project. If the script runs end-to-end without errors, it validates that every command documented in every phase is correct and that you understand the dependencies between resources.

---

## The Technology

### Why Automate?

Every phase was built step-by-step deliberately — to understand what each resource does and why it exists. Automation comes after understanding, not before.

The rebuild script isn't just a convenience. It proves:

- Every command is correct and repeatable
- Dependencies are understood (you can't create a VM before the VNet exists)
- The environment is cattle, not pets — it can be destroyed and recreated at any time
- Cost is controlled — spin up, test, tear down

### Script Design Principles

The deploy script follows these rules:

- **Idempotent where possible** — running it twice shouldn't fail or duplicate resources
- **Variables at the top** — region, names, and sizes are set once and referenced throughout
- **Exit on error** — `set -e` means the script stops if any command fails rather than continuing with a broken state
- **Clear section headers** — so you can follow progress and identify where a failure occurred
- **Teardown is separate** — the destroy script is never called by the deploy script

### PowerShell Alternative

A PowerShell version (`scripts/deploy-all.ps1`) is also provided for environments where bash isn't available. Both scripts produce identical infrastructure.

---

## deploy-all.sh

See the full script at [scripts/deploy-all.sh](../scripts/deploy-all.sh).

The script runs through phases in order:

1. Set variables
2. Create resource group
3. Create VNet, subnets, NSGs, NSG rules
4. Create load balancer and public IP
5. Create availability set
6. Create Linux VM (web tier)
7. Create Windows VM (app tier)
8. Install nginx on web VM via run-command
9. Create storage account, blob container, file share, lifecycle policy
10. Enable managed identity on web VM
11. Assign RBAC roles
12. Create Key Vault, store secrets, grant VM access
13. Create Log Analytics Workspace
14. Install monitoring agent on VMs
15. Create action group and CPU alert

---

## destroy-all.sh

See the full script at [teardown/destroy-all.sh](../teardown/destroy-all.sh).

The teardown script:

1. Purges the Key Vault (soft-delete means the name is reserved for 90 days otherwise)
2. Deletes the resource group (removes everything else)
3. Confirms deletion

---

## Running the Scripts

### Deploy

```bash
# Make executable
chmod +x scripts/deploy-all.sh

# Run
./scripts/deploy-all.sh
```

### Teardown

```bash
chmod +x teardown/destroy-all.sh
./teardown/destroy-all.sh
```

### PowerShell Deploy

```powershell
pwsh scripts/deploy-all.ps1
```

---

## Verifying the Full Build

After the deploy script completes, run these checks:

```bash
# All resources in the group
az resource list --resource-group qcb-rg-lab --output table

# VM status
az vm list --resource-group qcb-rg-lab --show-details --output table

# Web server responding (via run-command)
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --command-id RunShellScript \
  --scripts "curl -s http://localhost | head -5"

# Secret accessible from VM
az vm run-command invoke \
  --resource-group qcb-rg-lab \
  --name qcb-vm-web-01 \
  --command-id RunShellScript \
  --scripts "curl -s -o /dev/null -w '%{http_code}' 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H 'Metadata:true'"
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown

```bash
./teardown/destroy-all.sh
```

This removes all QCB lab resources. The script is in [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 07: Monitoring](07-monitoring.md) | [Back to README](../README.md)
