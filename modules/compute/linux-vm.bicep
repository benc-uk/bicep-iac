// ==================================================================================
// Module for deploying a standalone Linux VM
// ==================================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Subnet to place the VM into')
param subnetId string

@description('VM size')
param size string = 'Standard_B2s'

@description('Disk type for OS disk')
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

@description('Create a new public IP or not')
param publicIp bool = true

@description('Resource ID of user managed identity or set to blank emtpy string')
param userIdentityResourceId string = ''

@description('Used to give the VM a unique FQDN')
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 5)

@description('Assign this public IP, set publicIp to false')
param existingPipId string = ''

@description('Assign to a load balancer backend pool')
param loadBalancerBackendPoolId string = ''

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
  id: existingPipId != '' ? existingPipId : pip.id
}

var identityConfig = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userIdentityResourceId}' :{}
  }
}

var loadBalancerPoolConfig = {
  id: loadBalancerBackendPoolId
}

// ===== Modules & Resources ==================================================

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: name

  properties: {
    ipConfigurations: [
      {
         name: 'ipconfig1'
         properties: {
            subnet: {
              id: subnetId
            }
            publicIPAddress: publicIp || existingPipId != '' ? pipConfig : null
            loadBalancerBackendAddressPools: loadBalancerBackendPoolId != '' ?  [ 
              loadBalancerPoolConfig 
            ] : []
         }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = if(publicIp) {
  location: location
  name: name
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${name}-${dnsSuffix}'
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: name

  identity: ((userIdentityResourceId == '') ? null : identityConfig)

  properties: {
    hardwareProfile: {
      vmSize: size
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
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }

    osProfile: {
      computerName: name
      adminUsername: adminUser
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? null : sshConfig)
      customData: base64(cloudInit)
    }
  }
}

output publicIP string = (publicIp ? pip.properties.ipAddress : 'none') 
output privateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output dnsName string = (publicIp ? pip.properties.dnsSettings.fqdn : 'none')
