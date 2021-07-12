param suffix string
param prefix string = 'vnet-'
param location string 

param addressSpace string = '10.0.0.0/8'
param subnetCidr string = '10.100.0.0/24'

param subnetName string = 'default'
var vnetName = '${prefix}${suffix}'

param openPorts array = [
  '22'
]

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  location: location
  name: vnetName
  
  properties: {
    addressSpace: {
      addressPrefixes: [  
        addressSpace 
      ]
    }

    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetCidr
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  location: location
  name: vnetName
}

resource nsgRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = [for (portNum, i) in openPorts:{
  parent: nsg
  name: 'Allow_${portNum}'

  properties: {
    priority: 1000+i
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: portNum
  }
}]

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetName string = vnet.properties.subnets[0].name
output subnetId string = vnet.properties.subnets[0].id
