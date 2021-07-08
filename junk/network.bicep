param suffix string
param location string 

param vnetAddressSpace string = '10.0.0.0/8'
param aksSubnetCidr string = '10.240.0.0/16'

var aksSubnetName = 'aks-subnet-${suffix}'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  location: location
  name: 'vnet-${suffix}'
  
  properties: {
    addressSpace: {
      addressPrefixes: [  
        vnetAddressSpace 
      ]
    }

    subnets: [
      {
        name: aksSubnetName
        properties: {
          addressPrefix: aksSubnetCidr
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output aksSubnetName string = vnet.properties.subnets[0].name
