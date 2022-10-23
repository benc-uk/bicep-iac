#!/bin/bash

if [[ "$0" = "$BASH_SOURCE" ]]; then
  echo "💥 Error - Please source this script. Do not execute."
  exit 1
fi

DEPLOYMENT_NAME=${1:-"main"}
echo "📚 Will use Azure deployment name: $DEPLOYMENT_NAME"

CLUSTER_IP=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.controlPlaneIp.value" -o tsv)
if [[ $CLUSTER_IP == *"10."* ]]; then
  echo "⛔ Can not use this script with a private cluster, run fetch-ssh-details.sh and access via the jumpbox"
  return 1
fi

echo "🌐 Checking cluster API at $CLUSTER_IP is accepting traffic"
nc -z "$CLUSTER_IP" 6443 -w 5
if [ $? -ne 0 ]; then
  echo "💥 Error - Cluster API is not ready. Exiting..."
  return 1
fi

KV_NAME=$(az deployment sub show --name "$DEPLOYMENT_NAME" --query "properties.outputs.keyVaultName.value" -o tsv)
echo "🔍 Discovered KeyVault name from deployment: $KV_NAME"
FILE=$(realpath azure.kubeconfig)

[[ $KV_NAME ]] || { echo "Failed to get KeyVault name. Exiting."; exit 1; }

echo "📜 Fetching kubeconfig from KeyVault $KV_NAME"
az keyvault secret show --name kubeconfig --vault-name "$KV_NAME" > /dev/null

if [ $? -eq 0 ]; then
  az keyvault secret show --name kubeconfig --vault-name "$KV_NAME" -o json | jq -e -r '.value' > "$FILE"
  echo "🧰 Download successful. Setting KUBECONFIG to $FILE"
  echo "🤓 Now run kubectl as normal, e.g. kubectl get nodes"
  export KUBECONFIG=$FILE
fi