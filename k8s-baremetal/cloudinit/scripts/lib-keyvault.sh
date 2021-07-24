#!/bin/bash

      #
      # Bash library for Azure KeyVault using managed identity
      #

      which curl > /dev/null || { echo -e "💥 Error! Command curl not installed"; exit 1; }
      which jq > /dev/null || { echo -e "💥 Error! Command jq not installed"; exit 1; }

      kvEndpoint="vault.azure.net"

      setKeyVaultEndpoint() {
        cloud=$(curl -sSH Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq -r ".compute.azEnvironment")
        if [ "$cloud" == "AzurePublicCloud" ]; then
          kvEndpoint="vault.azure.net"
        elif [ "$cloud" == "AzureUSGovernmentCloud" ]; then
          kvEndpoint="vault.usgovcloudapi.net"
        fi
      }

      getAccessToken() {
        resource="https%3A%2F%2F${kvEndpoint}"
        echo $(curl -sS -m 10 --fail "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=${resource}" -H Metadata:true | jq -r '.access_token')
      }

      getKeyVaultSecret() {
        vaultName=$1
        secretName=$2
        (( $# < 2 )) && { echo "Wrong number of arguments to getSecret"; return 1; }

        access_token=$(getAccessToken)

        secretValue=$(curl -Ss -m 10 --fail "https://${vaultName}.${kvEndpoint}/secrets/${secretName}?api-version=2016-10-01" -H "Authorization: Bearer ${access_token}" | jq -r ".value")

        if [[ "$secretValue" == "null" || "$secretValue" == "" ]]; then
          echo "Error fetching secret '$secretName' from '${vaultName}.${kvEndpoint}'"
          return 1
        fi

        echo $secretValue
      }

      getKeyVaultSecretToFile() {
        vaultName=$1
        secretName=$2
        fileName=$3
        (( $# < 3 )) && { echo "Wrong number of arguments to getSecret"; return 1; }

        access_token=$(getAccessToken)

        curl -Ss -m 10 --fail "https://${vaultName}.${kvEndpoint}/secrets/${secretName}?api-version=2016-10-01" -H "Authorization: Bearer ${access_token}" | jq -r ".value" > $fileName
      }

      putKeyVaultSecretFromFile() {
        vaultName=$1
        secretName=$2
        fileName=$3
        (( $# < 3 )) && { echo "Wrong number of arguments to putSecret"; return 1; }
        
        value=$(cat "$fileName" | jq -aRs .)

        access_token=$(getAccessToken)

        curl -sS --fail -X PUT \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${access_token}" \
          "https://${vaultName}.${kvEndpoint}/secrets/${secretName}?api-version=7.1" \
          --data-binary @- << EOF > /dev/null
      {
        "value": $value
      }
      EOF
      }

      putKeyVaultSecret() {
        vaultName=$1
        secretName=$2
        value=$3
        (( $# < 3 )) && { echo "Wrong number of arguments to putSecret"; return 1; }
        
        access_token=$(getAccessToken)

        curl -sS --fail -X PUT \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer ${access_token}" \
          "https://${vaultName}.${kvEndpoint}/secrets/${secretName}?api-version=7.1" \
          --data-binary @- << EOF > /dev/null
      {
        "value": "$value"
      }
      EOF
      }