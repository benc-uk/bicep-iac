# Baremetal Kubernetes on Azure With Kubeadm

This is a Bicep template to deploy a baremetal Kubernetes cluster to Azure deployed with kubeadm

## Quick Deploy

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters clusterName="my-k8s-cluster" \
  keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
```