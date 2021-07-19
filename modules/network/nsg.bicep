param name string = resourceGroup().name
param location string = resourceGroup().location
param openPorts array = []
param sourceAddress string = '*'

// ===== Modules & Resources ==================================================

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  location: location
  name: name
}

resource nsgRule 'Microsoft.Network/networkSecurityGroups/securityRules@2021-02-01' = [for (portNum, i) in openPorts:{
  parent: nsg
  name: 'Allow_${portNum}'

  properties: {
    priority: 1000+i
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: sourceAddress
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
    destinationPortRange: portNum
  }
}]

output nsgId string = nsg.id
output nsgName string = nsg.name
