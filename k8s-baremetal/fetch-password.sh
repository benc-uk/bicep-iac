#!/bin/bash

DEPLOYMENT_NAME=${1:-"main"}

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.keyVaultName.value" -o tsv)

[[ $KV_NAME ]] || { echo "Failed to get KeyVault name. Exiting."; exit 1; }

az keyvault secret show --name kubeconfig --vault-name $KV_NAME > /dev/null

if [ $? -eq 0 ]; then
  az keyvault secret show --name nodePassword --vault-name $KV_NAME | jq -e -r '.value' 
fi