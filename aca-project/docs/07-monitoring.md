# Phase 07 — Monitoring

| | |
|---|---|
| **Phase** | 07 |
| **Topic** | Monitoring & Observability |
| **AZ-104 Domain** | Monitor and Maintain Azure Resources |
| **Services** | Log Analytics Workspace, Azure Monitor, Action Groups, Metric Alerts |
| **Est. Cost** | Free tier — first 5 GB/day ingestion |

---

## Navigation

[← Phase 06: Key Vault](06-keyvault.md) | [Back to README](../README.md) | [Next: Phase 08 — Automation →](08-automation.md)

---

## What We're Building

A Log Analytics Workspace (`qcb-law-main`) as the central destination for logs and metrics, an action group (`qcb-ag-ops`) that sends email notifications, and a CPU metric alert (`qcb-alert-cpu-web`) that fires when `vm-web`'s CPU exceeds 80% for 5 minutes.

This phase maps to the **Monitor and Maintain Azure Resources** domain of AZ-104, specifically: creating and configuring Log Analytics workspaces, configuring Azure Monitor alerts, creating action groups, and understanding metric alert conditions and evaluation windows.

---

## The Technology

### Log Analytics Workspace

A Log Analytics Workspace (LAW) is the database where Azure Monitor stores log data. It uses KQL (Kusto Query Language) for querying. Resources are pointed at the workspace via diagnostic settings and they ship their logs there. You can then query across all resources in a single place.

**SKU used: PerGB2018** — the current pay-as-you-go model where you pay per GB of data ingested beyond the free daily allowance (5 GB/day). For a short lab session the ingestion is effectively zero.

**Retention: 30 days** — the minimum configurable retention period. Sufficient for a lab.

### Action Group

An action group defines what happens when an alert fires — email, SMS, webhook, Azure Function, and so on. In this project the action group sends an email to `qcb-alerts@qcbhomelab.online`.

### Metric Alert

A metric alert monitors a numeric condition on an Azure resource. It has:

- **Scope** — which resource to monitor (`vm-web`)
- **Condition** — `avg Percentage CPU > 80`
- **Window size** — 5 minutes (how far back to look)
- **Evaluation frequency** — 1 minute (how often to check)
- **Action group** — what to do when triggered (`qcb-ag-ops`)

---

## Step 1 — Create the Log Analytics Workspace

### Azure Portal

1. Search for **Log Analytics workspaces** and select it
2. Click **+ Create**
3. Fill in:
   - **Subscription:** QCB PAYG PersonalCloud
   - **Resource group:** `qcb-rg-lab`
   - **Name:** `qcb-law-main`
   - **Region:** East US
4. Click **Next: Tags**:
   - Add `Project=QCBLab` and `Environment=Lab`
5. Click **Review + create**, then **Create**
6. After creation, open **qcb-law-main → Usage and estimated costs → Data Retention**
   - Set retention to **30 days**

### Azure CLI

```bash
az monitor log-analytics workspace create \
  --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --location eastus \
  --retention-time 30 \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
New-AzOperationalInsightsWorkspace `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-law-main" `
  -Location "eastus" `
  -Retention 30 `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

---

## Step 2 — Create the Action Group

### Azure Portal

1. Search for **Monitor** and select it
2. In the left menu, click **Alerts → Action groups**
3. Click **+ Create**
4. Fill in the **Basics** tab:
   - **Subscription:** QCB PAYG PersonalCloud
   - **Resource group:** `qcb-rg-lab`
   - **Action group name:** `qcb-ag-ops`
   - **Display name:** `QCBOps`
5. Click **Next: Notifications**
6. Add a notification:
   - **Notification type:** Email/SMS/Push/Voice
   - **Name:** `ops-alert`
   - **Email:** `qcb-alerts@qcbhomelab.online`
   - Click **OK**
7. Click **Review + create**, then **Create**

### Azure CLI

```bash
az monitor action-group create \
  --resource-group qcb-rg-lab \
  --name qcb-ag-ops \
  --short-name QCBOps \
  --action email ops-alert qcb-alerts@qcbhomelab.online
```

### PowerShell

```powershell
$emailReceiver = New-AzActionGroupEmailReceiverObject `
  -Name "ops-alert" `
  -EmailAddress "qcb-alerts@qcbhomelab.online"

New-AzActionGroup `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-ag-ops" `
  -Location "global" `
  -ShortName "QCBOps" `
  -EmailReceiver $emailReceiver
```

---

## Step 3 — Create the CPU Metric Alert

### Azure Portal

1. In **Monitor → Alerts**, click **+ Create → Alert rule**
2. **Scope** — click **Select resource**:
   - Filter by resource type: Virtual machines
   - Select `vm-web` → click **Done**
3. **Condition** — click **Add condition**:
   - Signal: **Percentage CPU**
   - Aggregation: Average | Operator: Greater than | Threshold: 80
   - **Lookback period:** 5 minutes
   - **Frequency of evaluation:** 1 minute
   - Click **Done**
4. **Actions** — click **Select action groups**:
   - Select `qcb-ag-ops` → click **Select**
5. **Details**:
   - **Alert rule name:** `qcb-alert-cpu-web`
   - **Description:** Alert when web VM CPU exceeds 80% for 5 minutes
   - Add tags `Project=QCBLab` and `Environment=Lab`
6. Click **Review + create**, then **Create**

### Azure CLI

```bash
VM_ID=$(az vm show \
  --resource-group qcb-rg-lab \
  --name vm-web \
  --query id \
  --output tsv)

AG_ID=$(az monitor action-group show \
  --resource-group qcb-rg-lab \
  --name qcb-ag-ops \
  --query id \
  --output tsv)

az monitor metrics alert create \
  --resource-group qcb-rg-lab \
  --name qcb-alert-cpu-web \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$AG_ID" \
  --description "Alert when web VM CPU exceeds 80% for 5 minutes" \
  --tags Project=QCBLab Environment=Lab
```

### PowerShell

```powershell
$vmId = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "vm-web").Id
$agId = (Get-AzActionGroup -ResourceGroupName "qcb-rg-lab" -Name "qcb-ag-ops").Id

$condition = New-AzMetricAlertRuleV2Criteria `
  -MetricName "Percentage CPU" `
  -TimeAggregation Average `
  -Operator GreaterThan `
  -Threshold 80

Add-AzMetricAlertRuleV2 `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-alert-cpu-web" `
  -TargetResourceId $vmId `
  -Condition $condition `
  -WindowSize ([TimeSpan]::FromMinutes(5)) `
  -Frequency ([TimeSpan]::FromMinutes(1)) `
  -ActionGroupId $agId `
  -Severity 2 `
  -Description "Alert when web VM CPU exceeds 80% for 5 minutes"
```

---

## Verification

### Azure Portal

1. Open **qcb-law-main → Overview** — confirm workspace created, SKU PerGB2018, retention 30 days
2. Open **Monitor → Alerts → Action groups** — confirm `qcb-ag-ops` with email receiver
3. Open **Monitor → Alerts → Alert rules** — confirm `qcb-alert-cpu-web` targeting `vm-web`

### Azure CLI

```bash
az monitor log-analytics workspace show \
  --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --query "{Name:name, SKU:sku, Retention:retentionInDays}" \
  --output table

az monitor metrics alert list \
  --resource-group qcb-rg-lab \
  --output table
```

### PowerShell

```powershell
Get-AzOperationalInsightsWorkspace `
  -ResourceGroupName "qcb-rg-lab" -Name "qcb-law-main" | `
  Select-Object Name, Sku, RetentionInDays

Get-AzMetricAlertRuleV2 -ResourceGroupName "qcb-rg-lab" | Format-Table Name, Enabled
```

---

## Gotchas & Lessons Learned

> *Verified: 2026-03-11*

**1. `microsoft.insights` resource provider auto-registers on first use.** When `az monitor metrics alert create` runs for the first time in a subscription, Azure CLI emits: `WARNING: Resource provider 'microsoft.insights' used by this operation is not registered. We are registering for you.` This is harmless — auto-registration succeeded and the alert was created. No manual action needed.

**2. Log Analytics workspace SKU is `PerGB2018` — not "Standard".** The workspace was created with SKU `PerGB2018`, which is the current pay-as-you-go model. Earlier CLI documentation referenced a "Standard" SKU that no longer exists. Always verify the actual SKU with `az monitor log-analytics workspace show`.

**3. Metric alert `--condition` syntax is strict.** The condition string `"avg Percentage CPU > 80"` must match the exact metric name as Azure knows it. Use `az monitor metrics list-definitions --resource <VM_ID>` to find the correct metric names if you are adapting this to other resources.

**4. Action group short name is limited to 12 characters.** `--short-name QCBOps` is fine at 6 characters. If you exceed 12, the CLI returns a validation error.

**5. Alerts have a small delay before entering an active monitoring state.** After creation, metric alerts typically take 2–5 minutes before they begin evaluating. During this time the portal may show the alert status as "Not set". This is normal.

---

## Cost at This Phase

| Resource | Free Tier |
|---|---|
| qcb-law-main (PerGB2018) | ✅ First 5 GB/day ingestion free |
| qcb-ag-ops action group | ✅ First 1,000 email notifications/month free |
| qcb-alert-cpu-web metric alert | ✅ First 10 metric alert rules free |

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

```powershell
Remove-AzResourceGroup -Name "qcb-rg-lab" -Force -AsJob
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 06: Key Vault](06-keyvault.md) | [Back to README](../README.md) | [Next: Phase 08 — Automation →](08-automation.md)
