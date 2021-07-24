#!/bin/bash

DEPLOYMENT_NAME=${1:-"main"}
echo "📚 Will use Azure deployment name: $DEPLOYMENT_NAME"

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.keyVaultName.value" -o tsv)
echo "🔍 Discovered KeyVault name from deployment: $KV_NAME"

[[ $KV_NAME == "" ]] && { echo "💥 Error - Failed to get KeyVault name."; exit 1; }

az keyvault secret show --name nodePassword --vault-name $KV_NAME > /dev/null

if [ $? -eq 0 ]; then
  echo "🔐 Node password: $(az keyvault secret show --name nodePassword --vault-name $KV_NAME | jq -e -r '.value')"
fi
echo "👜 Access jump box with: ssh kube@$(az deployment sub show --name main --query "properties.outputs.jumpBoxIpAddress.value" -o tsv)"