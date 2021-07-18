# Baremetal Kubernetes on Azure With Kubeadm

This is a Bicep template to deploy a baremetal Kubernetes cluster to Azure deployed with kubeadm

## Quick Deploy

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters location="uksouth" \
  resGroupName="my-k8s-cluster" \
  authString="$(cat ~/.ssh/id_rsa.pub)" \
  keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
```