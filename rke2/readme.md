# RKE2 Bicep Template

Deploys a RKE2 cluster to Azure on Ubuntu 20.04, this currently uses

- Multiple agent nodes
- Automatic configuration of the [Azure Cloud Provider](https://kubernetes-sigs.github.io/cloud-provider-azure/) using in-tree provider
- Sets up default storage class for Azure
- Configuring Linux kernel parameters

## Quick Deploy

Run from the rke2 directory, i.e. `cd rke2`

Using your SSH key as a means to login to the server & agent nodes

```bash
az deployment sub create --template-file main.bicep \
--location uksouth \
--parameters resGroupName="rke2" \
  location="uksouth" \
  authString="$(cat ~/.ssh/id_rsa.pub)"
```

Or use a password

```bash
az deployment sub create --template-file main.bicep \
--location uksouth \
--parameters resGroupName="rke2" \
  location="uksouth" \
  authType="password" \
  authString="Password@123!"
```

## Connecting to RKE2 Cluster

Connect to the server and copy the kube config to your local machine

```bash
rke2Server=$(az deployment sub show --name main --query "properties.outputs.serverFQDN.value" -o tsv)
scp azureuser@${rke2Server}:/etc/rancher/rke2/rke2.yaml $HOME/rke2-kubeconfig
```

Update the config so the server address is the remote DNS name, not localhost

```bash
sed -i "s/127.0.0.1/$rke2Server/" $HOME/rke2-kubeconfig
```

Set your KUBECONFIG to use this file and run kubectl commands against the RKE2 cluster

```bash
export KUBECONFIG=$HOME/rke2-kubeconfig
kubectl get no
```

> Note. You may get permission denied when copying the rke2.yaml file, if so wait and try again

## Parameters

| Name         | Purpose                                        | Default            | Type   |
| ------------ | ---------------------------------------------- | ------------------ | ------ |
| resGroupName | Resource group to deploy to, will be created   | NONE               | string |
| location     | Azure region to use                            | NONE               | string |
| suffix       | Resource name suffix appended to all resources | `rke2`             | string |
| authString   | Password or SSH public key                     | NONE               | string |
| authType     | Either `publicKey` or `password`               | `publicKey`        | string |
| agentCount   | Number of agent nodes                          | 2                  | int    |
| serverVMSize | VM size for server node(s)                     | `Standard_D16s_v4` | string |
| agentVMSize  | VM size for agent node(s)                      | `Standard_D16s_v4` | string |

## Outputs

- serverIP
- serverFQDN

# Known Issues / Roadmap

- Uses standard VMs
- No HA for the server
