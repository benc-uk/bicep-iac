# 🤖 Baremetal Kubernetes on Azure With Kubeadm

This is a Bicep template to deploy a bare metal "vanilla" Kubernetes cluster to Azure.

The cluster is configured & created using [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/) and containerd is used as the container runtime. Both public and private clusters are supported.

The cluster can run in HA mode if multiple control plane nodes are deployed.

The [Kubernetes cloud provider for Azure](https://kubernetes-sigs.github.io/cloud-provider-azure/) will be configured (using in-tree method, via kubelet arguments) as well as a default storage class backed with Azure disk. This means persistent volumes will work and can be mounted, as well as external load balancer (backed with Azure Load Balancer). Azure user managed identity is used to give the cloud provider access to the Azure resources and API, and is assigned contributor role on the resource group.

The pod network is provided by [Flannel](https://github.com/flannel-io/flannel), and additionally the [metrics server](https://github.com/kubernetes-sigs/metrics-server) will be deployed.

The cluster consists of the following Azure resources:

- Network: A VNet, subnets, security group
- VM scale set for the Kubernetes control plane
- VM scale set for the Kubernetes worker nodes
- Azure KeyVault
- User managed identity for use with the Kubernetes cloud provider for Azure 
- Optional: Jump box VM
- Load balancer 
  - For public clusters, Azure Load Balancer is put in front of control plane, with a public IP.
  - For private clusters, HAProxy load balancer running on a VM with a backend set to the range of IPs used by the control plane nodes.

For fully automated & unattended deployment it employees several techniques & tricks:

- Heavy use of cloud-init to inject scripts & config into the VMs.
- Bicep format function to inject parameters into config & scripts.
- Bash scripts to install & run kubeadm, check for cluster availability, and configure the cluster.
- KeyVault to hold secrets, store kubeconfig to access the cluster.
- A bash library which uses managed identity and provides helper functions to get/put secrets from KeyVault.

## Quick Deploy

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters clusterName="my-cluster" \
  keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
```

## Parameters

It's important to assign your own user OID in Azure AD to the `keyVaultAccessObjectId` parameter, otherwise you will not have permissions to fetch the secrets from the KeyVault needed to access the cluster. You can get this from running `az ad signed-in-user show --query 'objectId' -o tsv` or other means.

| Name | Description | Type | Default |
|------|-------------|------|---------|
| clusterName | Name used for resource group, and base name for most resources | string | *none* |
| location | Azure region for all resources | string | *Same as deployment* |
| publicCluster | Switch between public/private clusters, changes type of load balancer, and removes public IP | bool | true |
| controlPlaneCount | Number of nodes in the control plane, should be a odd number | int | 1 |
| workerCount | Number of worker/agent nodes | int | 3 |
| workerVmSize | Azure VM instance size for the worker nodes | string | Standard_B2s |
| controlPlaneVmSize | Azure VM instance size for the control plane nodes | string | Standard_B2s |
| keyVaultAccessObjectId | Assign this Azure AD object id access to the KeyVault. See comment above. | string | *none* |
| deployJumpBox | Enable to deploy a jump box VM for SSH access to nodes. Always deployed if *publicCluster* is false | bool | false |
| jumpBoxPublicKey | SSH key to connect to the jumpbox, if unset password auth will be used, with the password in the KeyVault | string | *blank* |

## Cluster Access

The template will assign a public IP to the control plane load balancer and open the Kubernetes API (port 6443) externally. This is still secure, as without the correct kubeconfig (which is held in KeyVault) you will not be able to connect or do anything with the cluster.

To get access to a public cluster run `source ./fetch-kubeconfig.sh`, this script will check the cluster is online, downloads the kubeconfig file from KeyVault to a local file `azure.kubeconfig` and sets the KUBECONFIG environmental var (note it overwrites it) to point to the azure.kubeconfig file. Once it has run you should be able to run `kubectl` and other commands such as `helm` as normal against the cluster.

## SSH Access & Private Clusters

By default there is no way to SSH on to the control plane or worker nodes order to access the OS of the nodes. If you require SSH access for troubleshooting purposes, you should deploy a jump box by setting `deployJumpBox=true` and optionally provide a value for `jumpBoxPublicKey`. This is the SSH key to connect to the jumpbox, if unset then less secure password auth will be used, with the generated password stored in the KeyVault

Run the `fetch-ssh-details.sh` script to get the address of the jumpbox and the password from KeyVault. First SSH to the jumpbox (username is `kube`) using the key pair or password, then from the jumpbox SSH to the nodes using same user `kube` and the password output from the script.

With a private cluster this is the only way to access the cluster in order to run kubectl etc. The `access-cluster.sh` script on the jump box will fetch the kubeconfig from KeyVault and set it to be the default used by kubectl (i.e. downloads it to `$HOME/.kube/config`).

## Kubernetes Bootstrap Process

The cluster is boot strapped by **kubeadm** as follows

- Each node on the control plane runs `/root/kubeadm-cp.sh` this is done by cloud-init, this script checks the hostname
  - If the hostname ends `000000` this is the first node, and it runs `kubeadm init` to initialize the cluster, once the cluster is initialized, the following steps are carried out:
    - Install Flannel CNI
    - Apply `/root/default-sc.yaml` to create a default storage class
    - Apply `/root/metrics-server.yaml` to create a default storage class
    - Upload the `/etc/kubernetes/admin.conf` file to KeyVault as a secret named `kubeconfig`
  - If the hostname is anything else then this node waits for the control plane to be ready (by polling that port 6443 is open) then runs `kubeadm join`
- In both cases the `/root/kubeadm.conf` file is used to provide initialization details and cluster configuration for control plane nodes.
- The `kubeadm.conf` enables the in-tree Azure cloud provider with kubelet extra args and points it to `/etc/kubernetes/cloud.conf` and this file is created dynamically by Bicep at deployment time.

Worker nodes join the cluster by cloud-init running a different script, `kubeadm-worker.sh` this polls and checks the control-plane is ready (using the same port 6443 check) then runs `kubeadm join` with `kubeadm-worker.conf` config file (which also enables the in-tree Azure cloud provider using `/etc/kubernetes/cloud.conf`)

**Note 1.** A randomised bootstrap token & cert-key is created by the Bicep template and injected into the `kubeadm.conf` and `kubeadm-worker.conf`

**Note 2.** The cluster is initialized with `--upload-certs` and `unsafeSkipCAVerification` used in the join configuration for both control-plane and worker nodes.

## Private Clusters

Private clusters can be deployed by setting `publicCluster` to false, however an internal Azure Load Balancer (also refereed to as ILB) can't be used for several reasons:

- It is MAJOR a limitation of Azure that "hairpinning" is not supported on internal load balancers, this means the VMs in the load balancer back end CAN NOT access the frontend / VIP of the load balancer [see this note in the docs](https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-troubleshoot-backend-traffic#cause-4-accessing-the-internal-load-balancer-frontend-from-the-participating-load-balancer-backend-pool-vm)
- How kubeadm init / join operates https://github.com/kubernetes/kubeadm/issues/1685 means that it tries to talk to the load-balancer frontend address

In order to workaround this, a VM running HAProxy is used instead of an Azure Load Balancer.