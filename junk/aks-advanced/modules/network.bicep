param suffix string
param location string 

param vnetAddressSpace string = '10.0.0.0/8'
param aksSubnetCidr string = '10.240.0.0/16'
param vnodeSubnetCidr string = '10.190.0.0/16'
param enableVnodes bool = false

var aksSubnetName = 'aks-subnet-${suffix}'
var vodesSubnetName = 'vnode-subnet-${suffix}'

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

resource vnode 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = if(enableVnodes) {
  name: '${vnet.name}/${vodesSubnetName}'
  properties: {
    addressPrefix: vnodeSubnetCidr
  }
}

output vnetName string = vnet.name
output aksSubnetName string = vnet.properties.subnets[0].name
output vodesSubnetNameFull string = vnode.name
output vodesSubnetName string = vodesSubnetName
