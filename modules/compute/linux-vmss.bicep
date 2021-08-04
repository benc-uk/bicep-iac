// ==================================================================================
// Module for deploying a Linux VM scale set
// ==================================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Subnet to place the VM into')
param subnetId string

@description('Resource ID of user managed identity or set to blank emtpy string')
param userIdentityResourceId string = ''

@description('VM size')
param size string = 'Standard_B2s'

@description('Number of VM instances in the scale set')
param instanceCount int = 1

@description('Username for the Virtual Machine admin.')
param adminUser string = 'azureuser'

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'publicKey'
  'password'
])
param authenticationType string = 'publicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('Cloud init config string to load into VM custom data')
param cloudInit string = '''
#cloud-config
'''

@description('Disk type for OS disk')
param osDiskType string = 'Standard_LRS'

@description('Image to be deployed')
param imageRef object = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts'
  version: 'latest'
}

@description('Assign to a load balancer backend pool')
param loadBalancerBackendPoolId string = ''

@description('Enable overprovisioning')
param overprovision bool = false

// ===== Variables ============================================================

var identityConfig = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userIdentityResourceId}' :{}
  }
}

var sshConfig = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUser}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

var loadBalancerPoolConfig = {
  id: loadBalancerBackendPoolId
}

// ===== Modules & Resources ==================================================

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-03-01' = {
  location: location
  name: name

  identity: ((userIdentityResourceId == '') ? null : identityConfig)

  sku: {
    name: size
    capacity: instanceCount
  }

  properties: {
    upgradePolicy: {
      mode: 'Manual'
    }

    overprovision: overprovision

    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: '${name}-'
        adminUsername: adminUser
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? null : sshConfig)
        customData: base64(cloudInit)
      }

      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: osDiskType
          }
        }
        imageReference: imageRef
      }

      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic1'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig1'
                  properties: {
                    primary: true
                    subnet: { 
                      id: subnetId 
                    }
                    loadBalancerBackendAddressPools: loadBalancerBackendPoolId != '' ?  [ 
                      loadBalancerPoolConfig 
                    ] : []
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}
