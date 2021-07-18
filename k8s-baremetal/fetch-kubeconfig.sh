#!/bin/bash

if [[ "$0" = "$BASH_SOURCE" ]]; then
  echo "Please source this script. Do not execute."
  exit 1
fi

DEPLOYMENT_NAME=${1:-"main"}

CLUSTER_IP=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.controlPlaneIp.value" -o tsv)
nc -z $CLUSTER_IP 6443 -w 5
if [ $? -ne 0 ]; then
  echo "Cluster is not ready. Exiting..."
  return 1
fi

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.keyVaultName.value" -o tsv)
FILE=$(realpath azure.kubeconfig)

[[ $KV_NAME ]] || { echo "Failed to get KeyVault name. Exiting."; exit 1; }

echo "Fetching kubeconfig from KeyVault $KV_NAME"
az keyvault secret show --name kubeconfig --vault-name $KV_NAME > /dev/null

if [ $? -eq 0 ]; then
  az keyvault secret show --name kubeconfig --vault-name $KV_NAME | jq -e -r '.value' > $FILE
  echo "Download successful. Setting KUBECONFIG to $FILE"
  export KUBECONFIG=$FILE
fi