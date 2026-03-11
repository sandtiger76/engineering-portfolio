# Phase 07 — Monitoring

| | |
|---|---|
| **Phase** | 07 |
| **Topic** | Monitoring & Observability |
| **Services** | Log Analytics Workspace, Azure Monitor, Diagnostic Settings, Alerts |
| **Est. Cost** | Low — first 5GB/day ingestion free, basic alerts free |

---

## Navigation

[← Phase 06: Key Vault](06-keyvault.md) | [Back to README](../README.md) | [Next: Phase 08 — Automation →](08-automation.md)

---

## What We're Building

A Log Analytics Workspace (`qcb-law-main`) as the central destination for all logs and metrics. We'll connect both VMs to it, configure diagnostic settings on the storage account and Key Vault, and create an alert that fires when VM CPU exceeds 80%.

---

## The Technology

### Azure Monitor

Azure Monitor is the umbrella service for all observability in Azure. It collects metrics and logs from every resource and provides the platform for alerts, dashboards, and analysis. You don't create Azure Monitor — it's always there. You configure what it collects and where it sends data.

### Log Analytics Workspace

A Log Analytics Workspace (LAW) is the database where Azure Monitor stores log data. It uses a query language called KQL (Kusto Query Language) to search and analyse logs. Think of it as a centralised logging platform — you point resources at it, they send logs, and you can query across all of them in one place.

**Why centralise logs?** When something goes wrong, you want to search across VMs, storage, Key Vault, and networking in a single query rather than clicking through each resource individually.

### Diagnostic Settings

Each Azure resource can send logs and metrics to a destination. A **diagnostic setting** is the configuration that says: "send these categories of logs to this workspace." You configure one per resource.

### Alerts

An alert rule monitors a condition (e.g. CPU > 80%) and triggers an action (e.g. email notification, webhook) when the condition is met. Alerts in Azure Monitor consist of:

- **Scope** — which resource to monitor
- **Condition** — what metric/log to watch and the threshold
- **Action group** — what to do when triggered (email, SMS, webhook, etc.)

### VM Insights

VM Insights is a pre-built monitoring solution for virtual machines. It automatically collects performance metrics (CPU, memory, disk, network) and maps dependencies between VMs. It requires the Azure Monitor Agent to be installed on the VM.

---

## Step 1 — Create the Log Analytics Workspace

```bash
az monitor log-analytics workspace create \
  --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --location eastus \
  --retention-time 30 \
  --tags Project=QCBLab Environment=Lab
```

```powershell
New-AzOperationalInsightsWorkspace `
  -ResourceGroupName "qcb-rg-lab" `
  -Name "qcb-law-main" `
  -Location "eastus" `
  -Retention 30 `
  -Tag @{Project="QCBLab"; Environment="Lab"}
```

> `--retention-time 30` keeps logs for 30 days. The free tier covers this. Longer retention incurs charges.

---

## Step 2 — Get the Workspace ID and Key

You'll need these to connect the VM agent:

```bash
LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --query customerId --output tsv)

LAW_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group qcb-rg-lab \
  --workspace-name qcb-law-main \
  --query primarySharedKey --output tsv)

echo "Workspace ID: $LAW_ID"
```

```powershell
$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName "qcb-rg-lab" -Name "qcb-law-main"
$lawKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName "qcb-rg-lab" -Name "qcb-law-main").PrimarySharedKey
$lawId = $law.CustomerId
```

---

## Step 3 — Install the Azure Monitor Agent on the Linux VM

```bash
az vm extension set \
  --resource-group qcb-rg-lab \
  --vm-name qcb-vm-web-01 \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings "{\"workspaceId\": \"$LAW_ID\"}" \
  --protected-settings "{\"workspaceKey\": \"$LAW_KEY\"}"
```

```powershell
Set-AzVMExtension `
  -ResourceGroupName "qcb-rg-lab" `
  -VMName "qcb-vm-web-01" `
  -Name "OmsAgentForLinux" `
  -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
  -ExtensionType "OmsAgentForLinux" `
  -TypeHandlerVersion "1.0" `
  -Settings @{"workspaceId" = $lawId} `
  -ProtectedSettings @{"workspaceKey" = $lawKey}
```

---

## Step 4 — Configure Diagnostic Settings on Key Vault

```bash
KV_ID=$(az keyvault show --name qcb-kv-lab --resource-group qcb-rg-lab --query id --output tsv)
LAW_ID_FULL=$(az monitor log-analytics workspace show --resource-group qcb-rg-lab --workspace-name qcb-law-main --query id --output tsv)

az monitor diagnostic-settings create \
  --name qcb-kv-diagnostics \
  --resource "$KV_ID" \
  --workspace "$LAW_ID_FULL" \
  --logs '[{"category": "AuditEvent", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

```powershell
$kvId = (Get-AzKeyVault -VaultName "qcb-kv-lab" -ResourceGroupName "qcb-rg-lab").ResourceId
$lawFullId = (Get-AzOperationalInsightsWorkspace -ResourceGroupName "qcb-rg-lab" -Name "qcb-law-main").ResourceId

$log = New-AzDiagnosticSettingLogSettingsObject -Enabled $true -Category "AuditEvent"
$metric = New-AzDiagnosticSettingMetricSettingsObject -Enabled $true -Category "AllMetrics"

New-AzDiagnosticSetting `
  -Name "qcb-kv-diagnostics" `
  -ResourceId $kvId `
  -WorkspaceId $lawFullId `
  -Log $log `
  -Metric $metric
```

---

## Step 5 — Create an Action Group (Email Alert)

```bash
az monitor action-group create \
  --resource-group qcb-rg-lab \
  --name qcb-ag-ops \
  --short-name QCBOps \
  --action email ops-alert qcb-alerts@qcbhomelab.online
```

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

## Step 6 — Create a CPU Alert on the Web VM

```bash
VM_ID=$(az vm show --resource-group qcb-rg-lab --name qcb-vm-web-01 --query id --output tsv)
AG_ID=$(az monitor action-group show --resource-group qcb-rg-lab --name qcb-ag-ops --query id --output tsv)

az monitor metrics alert create \
  --resource-group qcb-rg-lab \
  --name qcb-alert-cpu-web \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$AG_ID" \
  --description "Alert when web VM CPU exceeds 80% for 5 minutes" \
  --tags Project=QCBLab
```

```powershell
$vmId = (Get-AzVM -ResourceGroupName "qcb-rg-lab" -Name "qcb-vm-web-01").Id
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

## Step 7 — Query Logs with KQL

Once logs are flowing, you can query them in the portal or via CLI:

```bash
az monitor log-analytics query \
  --workspace "$LAW_ID" \
  --analytics-query "Heartbeat | summarize LastHeartbeat=max(TimeGenerated) by Computer | order by LastHeartbeat desc" \
  --output table
```

> The `Heartbeat` table is written every minute by the monitoring agent — a quick way to confirm agents are connected.

---

## Verification

```bash
# List workspaces
az monitor log-analytics workspace list --resource-group qcb-rg-lab --output table

# List alert rules
az monitor metrics alert list --resource-group qcb-rg-lab --output table

# List action groups
az monitor action-group list --resource-group qcb-rg-lab --output table
```

---

## Gotchas & Lessons Learned

> *This section is updated as the phase is implemented.*

---

## Teardown — This Phase Only

```bash
az group delete --name qcb-rg-lab --yes --no-wait
```

For the full project teardown, see [teardown/destroy-all.sh](../teardown/destroy-all.sh).

---

## Navigation

[← Phase 06: Key Vault](06-keyvault.md) | [Back to README](../README.md) | [Next: Phase 08 — Automation →](08-automation.md)
