#!/bin/bash

echo -e "\n\e[34m╔══════════════════════════════════╗"
echo -e "║\e[32m    Bicep Build & Deploy 💪 🚀\e[34m    ║"
echo -e "╚══════════════════════════════════╝"
echo -e "\n\e[34m»»» ✅ \e[96mChecking pre-reqs\e[0m..."

az > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» 💩 Azure CLI is not installed! 😥 Please go to http://aka.ms/cli to set it up"
  exit
fi

bicep --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo -e "\e[31m»»» 💩 Bicep is not installed! 😥 Please run install-bicep.sh to set it up"
  exit
fi
set -e

export SUB_NAME=$(az account show --query name -o tsv)
if [[ -z $SUB_NAME ]]; then
  echo -e "\n\e[31m»»» 💩 You are not logged in to Azure!"
  exit
fi
export TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "\e[34m»»» 🔨 \e[96mDetails for Azure CLI currently logged on user \e[0m"
echo -e "\e[34m»»»   • \e[96mSubscription: \e[33m$SUB_NAME\e[0m"
echo -e "\e[34m»»»   • \e[96mTenant:       \e[33m$TENANT_ID\e[0m\n"

if (( $# < 3 )); then
  echo -e "\e[32m»»» 💬 Insuffcient script arguments"
  echo -e "\e[32m»»» Usage: \e[37mdeploy.sh \e[36m{bicep-file} {'build|'sub'|'group'} {region} {res-grp}"
  exit
fi

echo -e "\e[34m»»» 💪 Bicep building..."  
bicep build $1

if [[ $2 == "build" ]]; then
  exit 0
fi

if [[ $2 == "group" ]]; then
  if [[ -z $4 ]]; then
    echo -e "\n\e[31m»»» 💩 You must supply a resource group name!"
    exit 1
  fi
  echo -e "\e[34m»»» 📁 Creating resource group '$4'..."
  az group create --name $4 --location $3 --query "properties.provisioningState"
  echo -e "\e[34m»»» 🚀 Deploying output file: \e[37m${1/.bicep/.json}\e[34m at resource group scope"
  PARAMS=""
  if [[ $5 != "" ]]; then
    PARAMS="--parameters $5"
  fi
  az deployment group create --template-file "${1/.bicep/.json}" --resource-group $4 $PARAMS
  exit
fi

echo -e "\e[34m»»» 🚀 Deploying output file: \e[37m${1/.bicep/.json}\e[34m at subscription scope"
PARAMS=""
if [[ $4 != "" ]]; then
  PARAMS="--parameters $4"
fi
echo az deployment $2 create --template-file "${1/.bicep/.json}" --location $3 $PARAMS
exit