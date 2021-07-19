param name string = resourceGroup().name
param location string = resourceGroup().location

param addressSpace string = '10.0.0.0/8'
param subnetCidr string = '10.100.0.0/24'

param subnetName string = 'default'
param nsgId string = ''

// ===== Variables ============================================================

var nsgConfig = {
  id: nsgId
}

// ===== Modules & Resources ==================================================

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  location: location
  name: name
  
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
          networkSecurityGroup: nsgId != '' ? nsgConfig : null
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetName string = vnet.properties.subnets[0].name
output subnetId string = vnet.properties.subnets[0].id
