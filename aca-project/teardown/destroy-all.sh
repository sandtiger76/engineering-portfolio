#!/bin/bash
# =============================================================================
# QCB Technologies — Azure Lab Teardown
# Removes all lab resources cleanly and cheaply
# =============================================================================

set -e

# --- Variables ---------------------------------------------------------------
RESOURCE_GROUP="qcb-rg-lab"
KEY_VAULT="qcb-kv-lab"
LOCATION="eastus"

# --- Confirmation ------------------------------------------------------------
echo ""
echo "============================================="
echo "  QCB Technologies — Lab Teardown"
echo "============================================="
echo ""
echo "This will permanently delete:"
echo "  Resource Group : $RESOURCE_GROUP"
echo "  (and everything inside it)"
echo ""
read -p "Are you sure? Type 'yes' to confirm: " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Teardown cancelled."
  exit 0
fi

# --- Step 1: Purge Key Vault -------------------------------------------------
# Key Vault has soft-delete enabled by default. If we don't purge it,
# the vault name is reserved for 90 days and cannot be reused.
echo ""
echo "[1/2] Purging Key Vault: $KEY_VAULT"

KV_EXISTS=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[?name=='$KEY_VAULT'].name" --output tsv 2>/dev/null || true)

if [ -n "$KV_EXISTS" ]; then
  az keyvault delete --name "$KEY_VAULT" --resource-group "$RESOURCE_GROUP"
  echo "      Waiting for soft-delete to register..."
  sleep 15
  az keyvault purge --name "$KEY_VAULT" --location "$LOCATION"
  echo "      Key Vault purged."
else
  echo "      Key Vault not found — skipping."
fi

# --- Step 2: Delete Resource Group -------------------------------------------
echo ""
echo "[2/2] Deleting resource group: $RESOURCE_GROUP"

RG_EXISTS=$(az group exists --name "$RESOURCE_GROUP")

if [ "$RG_EXISTS" = "true" ]; then
  az group delete --name "$RESOURCE_GROUP" --yes
  echo "      Resource group deleted."
else
  echo "      Resource group not found — nothing to delete."
fi

# --- Done --------------------------------------------------------------------
echo ""
echo "============================================="
echo "  Teardown complete. All QCB lab resources"
echo "  have been removed."
echo "============================================="
echo ""
echo "To rebuild: ./scripts/deploy-all.sh"
echo ""
