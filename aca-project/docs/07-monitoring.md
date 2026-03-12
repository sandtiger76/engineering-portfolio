# Phase 07 — Monitoring

**AZ-104 Domain:** Monitor and Maintain Azure Resources &nbsp;|&nbsp; **Services:** Log Analytics Workspace, Azure Monitor, Action Groups, Metric Alerts &nbsp;|&nbsp; **Est. Cost:** Free (first 5 GB/day ingestion)

---

## Navigation

[← Phase 06](06-keyvault.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 08 →](08-automation.md)

---

## What We're Building

A Log Analytics Workspace (`qcb-law-main`) as the central destination for logs and metrics, an action group (`qcb-ag-ops`) that sends email notifications, and a CPU metric alert (`qcb-alert-cpu-web`) that fires when `vm-web`'s CPU exceeds 80% for 5 minutes.

---

## The Technology

### Log Analytics Workspace

A Log Analytics Workspace (LAW) is the database where Azure Monitor stores log data. It uses KQL (Kusto Query Language) for querying. Resources are pointed at the workspace via diagnostic settings and ship their logs there — giving you a single place to query across all resources.

**SKU used: PerGB2018** — the current pay-as-you-go model where you pay per GB of data ingested beyond the free daily allowance (5 GB/day). For a short lab session, ingestion is effectively zero.

**Retention: 30 days** — the minimum configurable retention period, sufficient for a lab.

### Action Group

An action group defines what happens when an alert fires — email, SMS, webhook, Azure Function, and so on. In this project the action group sends an email to `qcb-alerts@qcbhomelab.online`.

### Metric Alert

A metric alert monitors a numeric condition on an Azure resource. The anatomy of an alert rule:

| Part | This project |
|---|---|
| **Scope** | `vm-web` — the resource being monitored |
| **Condition** | `avg Percentage CPU > 80` |
| **Window size** | 5 minutes — how far back to look |
| **Evaluation frequency** | 1 minute — how often to check |
| **Action group** | `qcb-ag-ops` — what to do when triggered |

---

## Step 1 — Create the Log Analytics Workspace

### Azure Portal

1. Search for **Log Analytics workspaces → + Create**
2. Resource group: `qcb-rg-lab` | Name: `qcb-law-main` | Region: East US
3. Add tags `Project=QCBLab` and `Environment=Lab`
4. Click **Review + create**, then **Create**
5. After creation: open **qcb-law-main → Usage and estimated costs → Data Retention** → set to 30 days

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

1. Open **Monitor → Alerts → Action groups → + Create**
2. Resource group: `qcb-rg-lab` | Action group name: `qcb-ag-ops` | Display name: `QCBOps`
3. Click **Next: Notifications**
4. Notification type: Email/SMS/Push/Voice | Name: `ops-alert` | Email: `qcb-alerts@qcbhomelab.online`
5. Click **Review + create**, then **Create**

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

1. Open **Monitor → Alerts → + Create → Alert rule**
2. **Scope:** Select resource → filter by Virtual machines → select `vm-web`
3. **Condition:** Add condition → Signal: Percentage CPU → Aggregation: Average, Operator: Greater than, Threshold: 80, Lookback: 5 min, Frequency: 1 min
4. **Actions:** Select action groups → `qcb-ag-ops`
5. **Details:** Name: `qcb-alert-cpu-web` | Add tags
6. Click **Review + create**, then **Create**

### Azure CLI

```bash
VM_ID=$(az vm show \
  --resource-group qcb-rg-lab --name vm-web \
  --query id --output tsv)

AG_ID=$(az monitor action-group show \
  --resource-group qcb-rg-lab --name qcb-ag-ops \
  --query id --output tsv)

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

**1. `microsoft.insights` resource provider auto-registers on first use.** When `az monitor metrics alert create` runs for the first time in a subscription, Azure CLI emits: `WARNING: Resource provider 'microsoft.insights' used by this operation is not registered. We are registering for you.` This is harmless — auto-registration succeeded and the alert was created.

**2. Log Analytics workspace SKU is `PerGB2018` — not "Standard".** Earlier CLI documentation referenced a "Standard" SKU that no longer exists. Always verify the actual SKU with `az monitor log-analytics workspace show`.

**3. Metric alert `--condition` syntax is strict.** The condition string `"avg Percentage CPU > 80"` must match the exact metric name as Azure knows it. Use `az monitor metrics list-definitions --resource <VM_ID>` to find correct metric names if adapting this to other resources.

**4. Action group short name is limited to 12 characters.** `--short-name QCBOps` is fine at 6 characters. If you exceed 12, the CLI returns a validation error.

**5. Alerts have a small delay before entering an active monitoring state.** After creation, metric alerts typically take 2–5 minutes before they begin evaluating. During this time the portal may show the alert status as "Not set". This is normal.

---

## Navigation

[← Phase 06](06-keyvault.md) &nbsp;|&nbsp; [README](../README.md) &nbsp;|&nbsp; [Phase 08 →](08-automation.md)
