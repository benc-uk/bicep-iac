#!/bin/bash
      # This script is used by the jumpbox only
      source lib-keyvault.sh

      mkdir -p $HOME/.kube
      KV_NAME={0}
      echo "Fetching kubeconfig from $KV_NAME"
      getKeyVaultSecretToFile $KV_NAME kubeconfig $HOME/.kube/config
      echo "$HOME/.kube/config has been updated"