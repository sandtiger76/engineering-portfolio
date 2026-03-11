#!/bin/bash
# =============================================================================
# QCB Technologies — Full Lab Deploy
# Builds the entire Azure lab environment from scratch
# Run time: approximately 10-15 minutes
# =============================================================================

set -e

# =============================================================================
# VARIABLES — edit these if needed
# =============================================================================

LOCATION="eastus"
RESOURCE_GROUP="qcb-rg-lab"

VNET="qcb-vnet-main"
SNET_WEB="qcb-snet-web"
SNET_APP="qcb-snet-app"
SNET_DATA="qcb-snet-data"
NSG_WEB="qcb-nsg-web"
NSG_APP="qcb-nsg-app"
NSG_DATA="qcb-nsg-data"

LB_NAME="qcb-lb-web"
LB_PIP="qcb-pip-lb"
AVSET="qcb-avset-web"

VM_WEB="qcb-vm-web-01"
VM_APP="qcb-vm-app-01"
VM_ADMIN="qcbadmin"
VM_PASSWORD="QCBLab@2024!"   # Change this — stored in Key Vault after Phase 06

STORAGE_ACCOUNT="qcbstorage01"
STORAGE_CONTAINER="qcb-data"
FILE_SHARE="qcb-fileshare"

KEY_VAULT="qcb-kv-lab"

LAW="qcb-law-main"
ACTION_GROUP="qcb-ag-ops"
ALERT_EMAIL="qcb-alerts@qcbhomelab.online"

TAGS="Project=QCBLab Environment=Lab"

# =============================================================================
echo ""
echo "============================================="
echo "  QCB Technologies — Lab Deploy"
echo "  Region: $LOCATION"
echo "============================================="

# =============================================================================
# PHASE 01 — Resource Group
# =============================================================================
echo ""
echo "[Phase 01] Creating resource group..."

az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags $TAGS

echo "  Done: $RESOURCE_GROUP"

# =============================================================================
# PHASE 02 — Networking
# =============================================================================
echo ""
echo "[Phase 02] Creating VNet and subnets..."

az network vnet create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VNET" \
  --address-prefix 10.0.0.0/16 \
  --tags $TAGS

az network vnet subnet create --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_WEB" --address-prefix 10.0.1.0/24
az network vnet subnet create --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_APP" --address-prefix 10.0.2.0/24
az network vnet subnet create --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_DATA" --address-prefix 10.0.3.0/24

echo "  Creating NSGs..."

az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_WEB" --tags $TAGS
az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_APP" --tags $TAGS
az network nsg create --resource-group "$RESOURCE_GROUP" --name "$NSG_DATA" --tags $TAGS

az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_WEB" --name Allow-HTTP  --priority 100 --protocol Tcp --destination-port-range 80  --access Allow --direction Inbound
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_WEB" --name Allow-HTTPS --priority 110 --protocol Tcp --destination-port-range 443 --access Allow --direction Inbound
az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_APP" --name Allow-From-Web --priority 100 --protocol Tcp --source-address-prefix 10.0.1.0/24 --destination-port-range 8080 --access Allow --direction Inbound

az network vnet subnet update --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_WEB"  --network-security-group "$NSG_WEB"
az network vnet subnet update --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_APP"  --network-security-group "$NSG_APP"
az network vnet subnet update --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET" --name "$SNET_DATA" --network-security-group "$NSG_DATA"

echo "  Done: VNet, subnets, NSGs"

# =============================================================================
# PHASE 03 — Compute
# =============================================================================
echo ""
echo "[Phase 03] Creating load balancer and VMs..."

az network public-ip create --resource-group "$RESOURCE_GROUP" --name "$LB_PIP" --sku Basic --allocation-method Static --tags $TAGS

az network lb create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$LB_NAME" \
  --sku Basic \
  --public-ip-address "$LB_PIP" \
  --frontend-ip-name qcb-lb-frontend \
  --backend-pool-name qcb-lb-backend \
  --tags $TAGS

az vm availability-set create --resource-group "$RESOURCE_GROUP" --name "$AVSET" --platform-fault-domain-count 2 --platform-update-domain-count 2 --tags $TAGS

echo "  Creating Linux VM (web tier) — this takes a few minutes..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_WEB" \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --vnet-name "$VNET" \
  --subnet "$SNET_WEB" \
  --availability-set "$AVSET" \
  --public-ip-address "" \
  --nsg "" \
  --admin-username "$VM_ADMIN" \
  --generate-ssh-keys \
  --tags $TAGS

echo "  Creating Windows VM (app tier) — this takes a few minutes..."
az vm create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_APP" \
  --image Win2022Datacenter \
  --size Standard_B1s \
  --vnet-name "$VNET" \
  --subnet "$SNET_APP" \
  --public-ip-address "" \
  --nsg "" \
  --admin-username "$VM_ADMIN" \
  --admin-password "$VM_PASSWORD" \
  --tags $TAGS

echo "  Installing nginx on web VM..."
az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_WEB" \
  --command-id RunShellScript \
  --scripts "sudo apt-get update -y && sudo apt-get install -y nginx && sudo systemctl start nginx && sudo systemctl enable nginx && echo 'QCB Technologies Web Server' | sudo tee /var/www/html/index.html"

echo "  Done: VMs and load balancer"

# =============================================================================
# PHASE 04 — Storage
# =============================================================================
echo ""
echo "[Phase 04] Creating storage account..."

az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot \
  --allow-blob-public-access false \
  --tags $TAGS

az storage container create --account-name "$STORAGE_ACCOUNT" --name "$STORAGE_CONTAINER" --auth-mode login
az storage share create --account-name "$STORAGE_ACCOUNT" --name "$FILE_SHARE" --quota 1 --auth-mode login

echo "  Done: Storage account, blob container, file share"

# =============================================================================
# PHASE 05 — Identity
# =============================================================================
echo ""
echo "[Phase 05] Enabling managed identity and assigning RBAC roles..."

az vm identity assign --resource-group "$RESOURCE_GROUP" --name "$VM_WEB"

VM_IDENTITY=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_WEB" --query identity.principalId --output tsv)
STORAGE_ID=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query id --output tsv)

az role assignment create --assignee "$VM_IDENTITY" --role "Storage Blob Data Reader" --scope "$STORAGE_ID"

echo "  Done: Managed identity and RBAC"

# =============================================================================
# PHASE 06 — Key Vault
# =============================================================================
echo ""
echo "[Phase 06] Creating Key Vault..."

az keyvault create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$KEY_VAULT" \
  --location "$LOCATION" \
  --enable-rbac-authorization true \
  --tags $TAGS

KV_ID=$(az keyvault show --name "$KEY_VAULT" --resource-group "$RESOURCE_GROUP" --query id --output tsv)
USER_ID=$(az ad signed-in-user show --query id --output tsv)

az role assignment create --assignee "$USER_ID" --role "Key Vault Secrets Officer" --scope "$KV_ID"

echo "  Waiting for role propagation..."
sleep 30

az keyvault secret set --vault-name "$KEY_VAULT" --name "vm-admin-password" --value "$VM_PASSWORD"
az role assignment create --assignee "$VM_IDENTITY" --role "Key Vault Secrets User" --scope "$KV_ID"

echo "  Done: Key Vault and secrets"

# =============================================================================
# PHASE 07 — Monitoring
# =============================================================================
echo ""
echo "[Phase 07] Setting up monitoring..."

az monitor log-analytics workspace create \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LAW" \
  --location "$LOCATION" \
  --retention-time 30 \
  --tags $TAGS

LAW_ID=$(az monitor log-analytics workspace show --resource-group "$RESOURCE_GROUP" --workspace-name "$LAW" --query customerId --output tsv)
LAW_KEY=$(az monitor log-analytics workspace get-shared-keys --resource-group "$RESOURCE_GROUP" --workspace-name "$LAW" --query primarySharedKey --output tsv)

az vm extension set \
  --resource-group "$RESOURCE_GROUP" \
  --vm-name "$VM_WEB" \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --settings "{\"workspaceId\": \"$LAW_ID\"}" \
  --protected-settings "{\"workspaceKey\": \"$LAW_KEY\"}"

az monitor action-group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACTION_GROUP" \
  --short-name QCBOps \
  --action email ops-alert "$ALERT_EMAIL"

VM_ID=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_WEB" --query id --output tsv)
AG_ID=$(az monitor action-group show --resource-group "$RESOURCE_GROUP" --name "$ACTION_GROUP" --query id --output tsv)

az monitor metrics alert create \
  --resource-group "$RESOURCE_GROUP" \
  --name qcb-alert-cpu-web \
  --scopes "$VM_ID" \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "$AG_ID" \
  --description "Alert when web VM CPU exceeds 80% for 5 minutes" \
  --tags $TAGS

echo "  Done: Log Analytics, monitoring agent, alerts"

# =============================================================================
# COMPLETE
# =============================================================================
echo ""
echo "============================================="
echo "  QCB Lab deployed successfully."
echo ""
echo "  Resource Group : $RESOURCE_GROUP"
echo "  Region         : $LOCATION"
echo ""
echo "  To verify:"
echo "  az resource list --resource-group $RESOURCE_GROUP --output table"
echo ""
echo "  To tear down:"
echo "  ./teardown/destroy-all.sh"
echo "============================================="
echo ""
