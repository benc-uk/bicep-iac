// ============================================================================
// Simple Virtual Network with default subnet and few features
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Address space for the virtual network, in CIDR format')
param addressSpace string = '10.0.0.0/8'

@description('Address range for the default subnet, in CIDR format')
param defaultSubnetCidr string = '10.100.0.0/24'
@description('Name of the default subnet')
param defaultSubnetName string = 'default'

@description('Set if you wish to associate an NSG with the default subnet')
param nsgId string = ''
@description('Set if you wish to associate an NAT gateway with the default subnet')
param natGatewayId string = ''

// ===== Variables ============================================================

var nsgConfig = {
  id: nsgId
}

var natGatewayConfig = {
  id: natGatewayId
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
        name: defaultSubnetName
        properties: {
          addressPrefix: defaultSubnetCidr
          networkSecurityGroup: nsgId != '' ? nsgConfig : null
          natGateway: natGatewayId != '' ? natGatewayConfig : null
        }
      }
    ]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnetName string = vnet.properties.subnets[0].name
output subnetId string = vnet.properties.subnets[0].id
