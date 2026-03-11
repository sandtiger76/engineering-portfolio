#!/bin/bash
# =============================================================================
# QCB Technologies — Full Lab Deploy
# Free tier only. Builds entire Azure lab from scratch.
# Expected run time: 10-15 minutes
#
# Design note: No public IPs on any VM. All VM access is via
# az vm run-command through the Azure control plane. This is the
# correct enterprise pattern — VMs are not directly internet-exposed.
# =============================================================================

set -e

# =============================================================================
# VARIABLES — change LOCATION if needed, leave everything else as-is
# =============================================================================

LOCATION="eastus"
RG="qcb-rg-lab"

# Networking
VNET="qcb-vnet-lab"
SNET_WEB="snet-web"
SNET_APP="snet-app"
NSG_WEB="nsg-web"
NSG_APP="nsg-app"

# Compute — no PIP variable, no public IP anywhere
NIC_WEB="nic-web"
NIC_APP="nic-app"
VM_WEB="vm-web"
VM_APP="vm-app"
VM_SIZE="Standard_B1s"
VM_IMAGE_LINUX="Ubuntu2204"
VM_IMAGE_WIN="Win2022Datacenter"
VM_ADMIN="qcbadmin"
VM_PASSWORD="QCBLab2024!Secure"

# Storage
STORAGE="stqcblab"
CONTAINER_1="uploads"
CONTAINER_2="backups"

# Key Vault
KV="qcb-kv-lab"

# Monitoring
LAW="qcb-law-main"
ACTION_GROUP="qcb-ag-ops"
ALERT_EMAIL="qcb-alerts@qcbhomelab.online"

TAGS="Project=QCBLab Environment=Lab"

# =============================================================================
echo ""
echo "============================================="
echo "  QCB Technologies — Lab Deploy"
echo "  Region : $LOCATION"
echo "  Group  : $RG"
echo "============================================="

# =============================================================================
# PHASE 01 — Resource Group
# =============================================================================
echo ""
echo "[Phase 01] Resource Group..."

az group create \
  --name "$RG" \
  --location "$LOCATION" \
  --tags $TAGS

echo "  ✓ $RG created"

# =============================================================================
# PHASE 02 — Networking
# =============================================================================
echo ""
echo "[Phase 02] Networking..."

az network vnet create \
  --resource-group "$RG" \
  --name "$VNET" \
  --address-prefixes 10.0.0.0/16 \
  --tags $TAGS

az network vnet subnet create \
  --resource-group "$RG" \
  --vnet-name "$VNET" \
  --name "$SNET_WEB" \
  --address-prefixes 10.0.1.0/24

az network vnet subnet create \
  --resource-group "$RG" \
  --vnet-name "$VNET" \
  --name "$SNET_APP" \
  --address-prefixes 10.0.2.0/24

az network nsg create --resource-group "$RG" --name "$NSG_WEB" --tags $TAGS
az network nsg create --resource-group "$RG" --name "$NSG_APP" --tags $TAGS

az network nsg rule create \
  --resource-group "$RG" --nsg-name "$NSG_WEB" \
  --name Allow-HTTP --priority 100 \
  --protocol Tcp --direction Inbound --access Allow \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG" --nsg-name "$NSG_WEB" \
  --name Allow-HTTPS --priority 110 \
  --protocol Tcp --direction Inbound --access Allow \
  --destination-port-range 443

az network nsg rule create \
  --resource-group "$RG" --nsg-name "$NSG_APP" \
  --name Allow-From-Web --priority 100 \
  --protocol Tcp --direction Inbound --access Allow \
  --source-address-prefix 10.0.1.0/24 \
  --destination-port-range 8080

az network vnet subnet update \
  --resource-group "$RG" --vnet-name "$VNET" \
  --name "$SNET_WEB" --network-security-group "$NSG_WEB"

az network vnet subnet update \
  --resource-group "$RG" --vnet-name "$VNET" \
  --name "$SNET_APP" --network-security-group "$NSG_APP"

echo "  ✓ VNet, subnets, NSGs created and associated"

# =============================================================================
# PHASE 03 — Compute
# =============================================================================
echo ""
echo "[Phase 03] Compute..."

# No public IP on either NIC — VMs accessed via az vm run-command only.
# This is the enterprise pattern: no direct internet exposure on VMs.
az network nic create \
  --resource-group "$RG" \
  --name "$NIC_WEB" \
  --vnet-name "$VNET" \
  --subnet "$SNET_WEB" \
  --network-security-group "$NSG_WEB"

az network nic create \
  --resource-group "$RG" \
  --name "$NIC_APP" \
  --vnet-name "$VNET" \
  --subnet "$SNET_APP" \
  --network-security-group "$NSG_APP"

echo "  Creating vm-web (Linux B1s)..."
az vm create \
  --resource-group "$RG" \
  --name "$VM_WEB" \
  --nics "$NIC_WEB" \
  --image "$VM_IMAGE_LINUX" \
  --size "$VM_SIZE" \
  --storage-sku Standard_LRS \
  --admin-username "$VM_ADMIN" \
  --generate-ssh-keys \
  --tags $TAGS

echo "  Creating vm-app (Windows B1s)..."
az vm create \
  --resource-group "$RG" \
  --name "$VM_APP" \
  --nics "$NIC_APP" \
  --image "$VM_IMAGE_WIN" \
  --size "$VM_SIZE" \
  --storage-sku Standard_LRS \
  --admin-username "$VM_ADMIN" \
  --admin-password "$VM_PASSWORD" \
  --tags $TAGS

echo "  Installing nginx on vm-web..."
az vm run-command invoke \
  --resource-group "$RG" \
  --name "$VM_WEB" \
  --command-id RunShellScript \
  --scripts "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl enable nginx && echo '<h1>QCB Technologies</h1>' | sudo tee /var/www/html/index.html"

echo "  ✓ VMs created, nginx installed"

# =============================================================================
# PHASE 04 — Storage
# =============================================================================
echo ""
echo "[Phase 04] Storage..."

az storage account create \
  --resource-group "$RG" \
  --name "$STORAGE" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --min-tls-version TLS1_2 \
  --tags $TAGS

az storage container create \
  --account-name "$STORAGE" \
  --name "$CONTAINER_1" \
  --auth-mode login

az storage container create \
  --account-name "$STORAGE" \
  --name "$CONTAINER_2" \
  --auth-mode login

echo "  ✓ Storage account and containers created"

# =============================================================================
# PHASE 05 — Identity
# =============================================================================
echo ""
echo "[Phase 05] Identity..."

az vm identity assign \
  --resource-group "$RG" \
  --name "$VM_WEB"

VM_IDENTITY=$(az vm show \
  --resource-group "$RG" \
  --name "$VM_WEB" \
  --query identity.principalId \
  --output tsv)

STORAGE_ID=$(az storage account show \
  --name "$STORAGE" \
  --resource-group "$RG" \
  --query id \
  --output tsv)

az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Storage Blob Data Reader" \
  --scope "$STORAGE_ID"

echo "  ✓ Managed identity enabled, RBAC assigned"

# =============================================================================
# PHASE 06 — Key Vault
# =============================================================================
echo ""
echo "[Phase 06] Key Vault..."

az keyvault create \
  --resource-group "$RG" \
  --name "$KV" \
  --location "$LOCATION" \
  --enable-rbac-authorization true \
  --tags $TAGS

KV_ID=$(az keyvault show \
  --name "$KV" \
  --resource-group "$RG" \
  --query id \
  --output tsv)

USER_ID=$(az ad signed-in-user show --query id --output tsv)

az role assignment create \
  --assignee "$USER_ID" \
  --role "Key Vault Secrets Officer" \
  --scope "$KV_ID"

echo "  Waiting 30s for role propagation..."
sleep 30

az keyvault secret set \
  --vault-name "$KV" \
  --name "vm-admin-password" \
  --value "$VM_PASSWORD"

az role assignment create \
  --assignee "$VM_IDENTITY" \
  --role "Key Vault Secrets User" \
  --scope "$KV_ID"

echo "  ✓ Key Vault created, secret stored, VM access granted"

# =============================================================================
# PHASE 07 — Monitoring
# =============================================================================
echo ""
echo "[Phase 07] Monitoring..."

az monitor log-analytics workspace create \
  --resource-group "$RG" \
  --workspace-name "$LAW" \
  --location "$LOCATION" \
  --retention-time 30 \
  --tags $TAGS

VM_ID=$(az vm show \
  --resource-group "$RG" \
  --name "$VM_WEB" \
  --query id \
  --output tsv)

az monitor action-group create \
  --resource-group "$RG" \
  --name "$ACTION_GROUP" \
  --short-name QCBOps \
  --action email ops-alert "$ALERT_EMAIL"

AG_ID=$(az monitor action-group show \
  --resource-group "$RG" \
  --name "$ACTION_GROUP" \
  --query id \
  --output tsv)

az monitor metrics alert create \
  --resource-group "$RG" \
  --name qcb-alert-cpu-web \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$AG_ID" \
  --description "Alert when web VM CPU exceeds 80% for 5 minutes" \
  --tags $TAGS

echo "  ✓ Log Analytics, action group, CPU alert created"

# =============================================================================
# COMPLETE
# =============================================================================
echo ""
echo "============================================="
echo "  QCB Lab deployed successfully."
echo ""
echo "  Resource Group : $RG"
echo "  Region         : $LOCATION"
echo ""
echo "  Note: No public IPs assigned. VM access via:"
echo "  az vm run-command invoke --resource-group $RG --name $VM_WEB ..."
echo ""
echo "  Verify : az resource list --resource-group $RG --output table"
echo "  Teardown: ./teardown/destroy-all.sh"
echo "============================================="
