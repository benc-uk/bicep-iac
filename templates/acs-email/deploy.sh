#!/bin/bash
set -e

# Deployment wrapper script

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEPLOY_NAME="acs-email"
AZURE_BASE_NAME=${AZURE_BASE_NAME:-"acs-email"}
AZURE_REGION=${AZURE_REGION:-"uksouth"}

which az > /dev/null || { echo "💥 Error! Azure CLI not found, please install https://aka.ms/azure-cli"; exit 1; }
az bicep version > /dev/null || { echo "💥 Error! Bicep not installed in Azure CLI, run 'az bicep install'"; exit 1; }

for varName in AZURE_BASE_NAME AZURE_REGION; do
  varVal=$(eval echo "\${$varName}")
  [ -z "$varVal" ] && { echo "💥 Error! Required variable '$varName' is unset!"; varUnset=true; }
done
[ "$varUnset" ] && exit 1

echo -e "\n🚀 Deployment started..."
echo -e "  📂 Resource group: $AZURE_BASE_NAME"
echo -e "  🌎 Region: $AZURE_REGION"

az deployment sub create                   \
  --template-file "$DIR"/main.bicep        \
  --location "$AZURE_REGION"               \
  --name "$DEPLOY_NAME"                    \
  --parameters baseName="$AZURE_BASE_NAME" \
               location="$AZURE_REGION"                   

echo -e "\n✨ Deployment complete!"

domainResourceId=$(az deployment sub show --name "$DEPLOY_NAME" --query 'properties.outputs.domainResourceId.value' -o tsv)
domainName=$(az deployment sub show --name "$DEPLOY_NAME" --query 'properties.outputs.domainName.value' -o tsv)
acsResourceId=$(az deployment sub show --name "$DEPLOY_NAME" --query 'properties.outputs.acsResourceId.value' -o tsv)

echo "🔨 Patching ACS resource to link email domain to ACS..."

az rest --method patch \
  --url "${acsResourceId}?api-version=2021-10-01-preview" \
  --body "{ \"properties\": { \"linkedDomains\": [ \"${domainResourceId}\" ] } }"

echo -e "📧 Domain name: ${domainName}"
echo -e "\n🍒 Process complete!"
