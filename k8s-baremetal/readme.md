# 🤖 Baremetal Kubernetes on Azure With Kubeadm

This is a Bicep template to deploy a bare metal Kubernetes cluster to Azure.

The cluster is configured & created using [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/) and containerd is used as the container runtime.

The cluster can run in HA mode if multiple cluster nodes are deployed, to synchronize the cluster creation KeyVault is used to provide a simple first-come-first-served leader election mechanism.

The [Kubernetes cloud provider for Azure](https://kubernetes-sigs.github.io/cloud-provider-azure/) will be configured (using in-tree method, via kubelet arguments) as well as a default storage class backed with Azure disk. This means persistent volumes will work and can be mounted, as well as external load balancer (backed with Azure Load Balancer)

The pod network is provided by [Flannel](https://github.com/flannel-io/flannel), and additionally the [metrics server](https://github.com/kubernetes-sigs/metrics-server) will be deployed.

In terms of Azure resources, the cluster consists of:

- Network: A VNet, subnet, security group
- VM scale set for the Kubernetes control plane
- Load balancer in front of control plane, with a public IP
- VM scale set for the Kubernetes worker nodes
- Azure KeyVault
- User managed identity for use with the Kubernetes cloud provider for Azure 
- Optional: Jump box VM

For fully automated & unattended deployment it employees several techniques & tricks:

- Heavy use of cloud-init to inject scripts & config into the VMs.
- Bicep format function to inject parameters into config & scripts.
- Bash scripts to install & run kubeadm, check for cluster availability, and configure the cluster.
- KeyVault to hold secrets, store kubeconfig to access the cluster, and synchronize cluster initialization.
- A bash library which uses managed identity and provides helper functions to get/put secrets from KeyVault.

## Quick Deploy

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters clusterName="my-cluster" \
  keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
```

## Parameters

## Cluster Access

By default the cluster will assign a public IP to the control plane load balancer and open the Kubnernetes API (port 6443) externally. This is still secure as without the correct kubeconfig you will not be able to connect.

## SSH Access

username: kube
password: in KeyVault
