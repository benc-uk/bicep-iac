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

## Parameters

| Name         | Purpose                                        | Default            | Type   |
| ------------ | ---------------------------------------------- | ------------------ | ------ |
| resGroupName | Resource group to deploy to, will be created   | NONE               | string |
| location     | Azure region to use                            | NONE               | string |
| suffix       | Resource name suffix appended to all resources | `rke2`             | string |
| authString   | Password or SSH public key                     | NONE               | string |
| authType     | Either `publicKey` or `password`               | `publicKey`        | string |
| agentCount   | Number of agent nodes                          | 2                  | int    |
| serverVMSize | VM size for server node(s)                     | `Standard_D16s_v4` | string    |
| agentVMSize  | VM size for agent node(s)                      | `Standard_D16s_v4` | string    |
| public       | Number of agent nodes                          | `true`             | bool   |

# Known Issues / Roadmap

- Uses standard VMs
- No HA for the server