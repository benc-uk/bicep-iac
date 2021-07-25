# 💻🐧 Simple Linux VM

This deploys a standalone Linux VM in a new VNet and subnet, and allows SSH access to it

## Parameters

| Name                  | Description                                                       | Type   | Default              |
| --------------------- | ----------------------------------------------------------------- | ------ | -------------------- |
| name                  | Name used for resource group, and base name for VM & resources    | string | _none_               |
| location              | Azure region for all resources                                    | string | _Same as deployment_ |
| size                  | Instance size of VM to deploy                                     | string | Standard_B1ms        |
| adminUser             | Username to login with SSH                                        | string | azureuser            |
| authenticationType    | Type of authentication to use on the VM, publicKey is recommended | string | publicKey            |
| adminPasswordOrKey    | SSH public key or password to login to the VM                     | string | _none_               |
| assignManagedIdentity | Create and assign a user managed identity to the VM               | bool   | false                |
| allowSshFromAddress   | Limit the NSG rule for SSH to certain addresses                   | string | \*                   |

## Quick Deploy

To quickly deploy a VM taking the defaults, and using your own local SSH key-pair, run:

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters name="temp-vm" \
    adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)"
```

To get access to the VM run the following and copy and paste the command output

```bash
az deployment sub show --name main --query "properties.outputs.sshCommand.value" -o tsv
```

## Limit SSH Access

To limit SSH access to your current public IP address, add the parameter `allowSshFromAddress="$(curl -Ss ifconfig.me)"`, e.g.

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth" \
  --parameters name="temp-vm" \
    adminPasswordOrKey="$(cat ~/.ssh/id_rsa.pub)" \
    allowSshFromAddress="$(curl -Ss ifconfig.me)"
```
