// ==================================================================================
// Module for deploying a Linux VM
// ==================================================================================

param suffix string
param location string 

@description('Subnet to place the VM into')
param subnetId string

@description('Name prefix for VM, suffix will be appended')
param name string = 'vm'

@description('Username for the Virtual Machine admin.')
param size string = 'Standard_B2s'

@description('Username for the Virtual Machine admin.')
param osDiskType string = 'Standard_LRS'

@description('Image to be deployed')
param imageRef object = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts'
  version: 'latest'
}

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

@description('Custom data to load into cloud-init process.')
param customData string = '''
#cloud-config
#
#
'''

@description('Create a public IP or not')
param publicIp bool = true

param userIdentityResourceId string = ''

// ==================================================================================
// Variables
// ==================================================================================

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

var pipConfig = {
  id: pip.id
}

var identityConfig = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userIdentityResourceId}' :{}
  }
}
// ==================================================================================
// Resources 
// ==================================================================================

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: '${name}-${suffix}'

  properties: {
    ipConfigurations: [
      {
         name: 'ipconfig1'
         properties: {
           subnet: {
            id: subnetId
           }
           publicIPAddress: ((publicIp == true) ? pipConfig : null)
         }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = if(publicIp == true) {
  location: location
  name: '${name}-${suffix}'
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod:'Static'
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: '${name}-${suffix}'

  identity: ((userIdentityResourceId == '') ? null : identityConfig)

  properties: {
    hardwareProfile: {
      vmSize: size
    }

    storageProfile: {
      osDisk: {
        createOption:'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageRef
    }

    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }

    osProfile: {
      computerName: '${name}-${suffix}'
      adminUsername: adminUser
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : sshConfig)
      customData: base64(customData)
    }
  }
}
