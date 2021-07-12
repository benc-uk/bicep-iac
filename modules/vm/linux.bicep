// ==================================================================================
// Module for deploying a Linux VM
// ==================================================================================

param suffix string
param prefix string = 'vm-'
param location string 

@description('Subnet to place the VM into')
param subnetId string

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

@description('Cloud init config string to load into VM custom data')
param cloudInit string = '''
#cloud-config
'''

@description('Create a public IP or not')
param publicIp bool = true

@description('Resource ID of user managed identity or set to blank emtpy string')
param userIdentityResourceId string = ''

@description('Used to give the VM a unique FQDN')
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 4)

// ===== Variables ============================================================

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

// ===== Modules & Resources ==================================================

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: '${prefix}${suffix}'

  properties: {
    ipConfigurations: [
      {
         name: 'ipconfig1'
         properties: {
           subnet: {
            id: subnetId
           }
           publicIPAddress: publicIp ? pipConfig : null
         }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = if(publicIp) {
  location: location
  name: '${prefix}${suffix}'
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${prefix}${suffix}-${dnsSuffix}'
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: '${prefix}${suffix}'

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
      computerName: '${prefix}${suffix}'
      adminUsername: adminUser
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : sshConfig)
      customData: base64(cloudInit)
    }
  }
}

output publicIP string = (publicIp ? pip.properties.ipAddress : 'none') 
output dnsName string = (publicIp ? pip.properties.dnsSettings.fqdn : 'none')
