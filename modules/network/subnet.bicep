param vnetName string
param name string = 'extrasubnet'
param nsgId string = ''
param natGatewayId string = ''
param addressPrefix string

// ===== Variables ============================================================

var nsgConfig = {
  id: nsgId
}

var natGatewayConfig = {
  id: natGatewayId
}

// ===== Modules & Resources ==================================================

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: name
  properties: {
    addressPrefix: addressPrefix
    networkSecurityGroup: nsgId != '' ? nsgConfig : null
    natGateway: natGatewayId != '' ? natGatewayConfig : null    
  }
}

output subnetName string = subnet.name
output subnetId string = subnet.id
