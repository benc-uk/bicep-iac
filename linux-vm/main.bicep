// ============================================================================
// Deploy a simple Linux VM including network
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and base name for VM & resources')
param name string 
@description('Azure region for all resources')
param location string = deployment().location

@description('Username to login with SSH')
param adminUser string = 'azureuser'

@description('Instance size of VM to deploy')
param size string = 'Standard_B1ms'

@description('Type of authentication to use on the VM, publicKey is recommended')
@allowed([
  'publicKey'
  'password'
])
param authenticationType string = 'publicKey'

@description('SSH public key or password to login to the VM')
@secure()
param adminPasswordOrKey string

@description('Create and assign a user managed identity to the VM')
param assignManagedIdentity bool = false

@description('Limit the NSG rule for SSH to certain addresses')
param allowSshFromAddress string = '*'

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location  
}

module subnetNsg '../modules/network/nsg.bicep' = {
  scope: resGroup
  name: 'subnetNsg'
  params: {
    sourceAddress: allowSshFromAddress
    openPorts: [ 
      '22'
    ]
  }
}

module network '../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    nsgId: subnetNsg.outputs.nsgId
  }
}

module linuxVm '../modules/compute/linux-vm.bicep' = {
  scope: resGroup
  name: 'linuxVm'

  params: {
    name: name
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: adminPasswordOrKey
    publicIp: true
    authenticationType: authenticationType
    size: size
    adminUser: adminUser
    userIdentityResourceId: assignManagedIdentity ? managedIdentity.outputs.resourceId : ''
  }
}

module managedIdentity '../modules/identity/user-managed.bicep' = if(assignManagedIdentity) {
  scope: resGroup
  name: 'managedIdentity'
}

// ===== Outputs ==========================az==================================

output publicIp string = linuxVm.outputs.publicIP
output dnsName string = linuxVm.outputs.dnsName
output sshCommand string = 'ssh ${adminUser}@${linuxVm.outputs.dnsName}'
