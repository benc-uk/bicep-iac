#!/bin/bash
set -euo pipefail

DEPLOYMENT_NAME=${1:-"main"}
echo "📚 Will use Azure deployment name: $DEPLOYMENT_NAME"

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.keyVaultName.value" -o tsv)
echo -e "🔍 Discovered KeyVault name from deployment: $KV_NAME\n"

[[ $KV_NAME == "" ]] && { echo "💥 Error - Failed to get KeyVault name."; exit 1; }

if az keyvault secret show --name nodePassword --vault-name "$KV_NAME" > /dev/null ; then
  echo "🔐 Node SSH password: $(az keyvault secret show --name nodePassword --vault-name "$KV_NAME" -o json | jq -e -r '.value')"
fi

if [ "$(az deployment sub show --name main --query "properties.outputs.jumpBoxIpAddress.value" -o tsv)" != "none" ]; then
  echo "👜 Access jump box with: ssh kube@$(az deployment sub show --name main --query "properties.outputs.jumpBoxIpAddress.value" -o tsv)"
fi
