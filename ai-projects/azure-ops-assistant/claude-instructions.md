# Claude Instructions — Sanitised Reference

*This is a sanitised version of the `CLAUDE.md` file that Claude Code operated from during the second run. Personal details, local paths, and account-specific values have been removed or replaced with placeholders. The structure and content are otherwise unchanged.*

*This file is the entire operating brief the AI received. There were no other instructions.*

---

## What This File Is

`CLAUDE.md` is a plain-text context and instruction file read by Claude Code at the start of each session. It acts as the AI's memory and runbook simultaneously — describing the environment, specifying exactly what to do, and setting the rules of engagement.

The file was produced in a Claude chat session after discussing the Azure architecture. It was then handed to Claude Code as the sole source of truth for the deployment.

---

## The File

```markdown
# CLAUDE.md — Azure Lab Environment

## Authentication
Before anything else, verify authentication:
az account show --query "{Sub:name, State:state}" --output table

If this fails, run: az login
Confirm the correct subscription is active and the default location is set to eastus.
If not set: az configure --defaults location=eastus

---

## Your Task
Run the deploy script end-to-end, verify each phase, write findings to NOTES.md, then tear down.

---

## Step 1 — Deploy

chmod +x <path-to-deploy-script>
<path-to-deploy-script>

Rules:
- Do NOT modify the script.
- Do NOT rename resources.
- Do NOT add resources not in the script.
- If a command fails, fix it within the script logic — do not work around it by running ad-hoc commands.

---

## Step 2 — Verify Each Phase
After the script completes, run these verification commands and record output in NOTES.md:

# Phase 01 — Resource Group
az group show --name qcb-rg-lab \
  --query "{Name:name, Location:location, State:properties.provisioningState}" \
  --output table

# Phase 02 — Networking
az network vnet show --resource-group qcb-rg-lab --name qcb-vnet-lab \
  --query "{Name:name, Space:addressSpace.addressPrefixes}" --output table
az network vnet subnet list --resource-group qcb-rg-lab --vnet-name qcb-vnet-lab --output table
az network nsg list --resource-group qcb-rg-lab --output table

# Phase 03 — Compute
az vm list --resource-group qcb-rg-lab --show-details --output table
az network nic list --resource-group qcb-rg-lab \
  --query "[].{NIC:name, PrivateIP:ipConfigurations[0].privateIPAddress, Subnet:ipConfigurations[0].subnet.id}" \
  --output table
az vm run-command invoke --resource-group qcb-rg-lab --name vm-web \
  --command-id RunShellScript --scripts "curl -s http://localhost | head -3"

# Phase 04 — Storage
az storage account show --name stqcblab --resource-group qcb-rg-lab \
  --query "{Name:name, SKU:sku.name, TLS:minimumTlsVersion}" --output table
az storage container list --account-name stqcblab --auth-mode login --output table

# Phase 05 — Identity
az vm show --resource-group qcb-rg-lab --name vm-web --query "identity" --output json
az role assignment list \
  --assignee $(az vm show --resource-group qcb-rg-lab --name vm-web \
    --query identity.principalId --output tsv) \
  --output table

# Phase 06 — Key Vault
az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab \
  --query "{Name:name, RBAC:properties.enableRbacAuthorization}" --output table
az keyvault secret list --vault-name qcb-kv-lab --output table

# Phase 07 — Monitoring
az monitor log-analytics workspace show \
  --resource-group qcb-rg-lab --workspace-name qcb-law-main \
  --query "{Name:name, Retention:retentionInDays}" --output table
az monitor metrics alert list --resource-group qcb-rg-lab --output table

---

## Step 3 — Write NOTES.md
Create NOTES.md at <output-path>/NOTES.md with this structure:

# Azure Lab — Implementation Notes
Generated: <date>

## Phase 01 — Resource Group
### What worked
### Gotchas

## Phase 02 — Networking
### What worked
### Gotchas

## Phase 03 — Compute
### What worked
### Gotchas

## Phase 04 — Storage
### What worked
### Gotchas

## Phase 05 — Identity
### What worked
### Gotchas

## Phase 06 — Key Vault
### What worked
### Gotchas

## Phase 07 — Monitoring
### What worked
### Gotchas

## Deploy Script Issues
Any commands that failed or needed fixing.

## Free Tier Confirmation
Confirm which resources fall within free tier allowances.

---

## Step 4 — Teardown
Once NOTES.md is written, run teardown immediately to stop all Azure costs:
<path-to-teardown-script>

Confirm resource group is gone:
az group list --output table

---

## Rules
- Use exact resource names from the script — never invent alternatives.
- Output one line per successful step, full output only on failure.
- Do not skip teardown at the end.
```

---

## Notes on the File

A few things worth observing about how this file is structured:

**It is written for an AI, not a human.** Human runbooks often include explanatory context — why a step matters, what it connects to. This file is optimised for unambiguous execution: verb first, exact command, no interpretation required.

**The rules section is explicit about deviations.** "Do not rename resources. Do not add resources not in the script." These were added after the first run, where the absence of explicit prohibitions left room for the AI to make substitutions. Negative instructions — telling the AI what not to do — proved as important as positive ones.

**Teardown is mandatory, not optional.** The instruction is unambiguous and appears as a numbered step, not a footnote. This matters: in the first run, teardown happened but was a separate action. Making it part of the defined workflow ensures it is not skipped.

**Verification is prescribed, not left to judgement.** Every phase has specific CLI commands to run. The AI is not asked to "confirm the networking is correct" — it is given the exact commands that confirm it. This produces consistent, reproducible verification rather than whatever the AI decides to check.
