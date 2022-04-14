// ============================================================================
// Virtual Network with multi subnets and support for delegation
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Address space for the virtual network, in CIDR format')
param addressSpace string = '10.0.0.0/8'

@description('Array of subnet objects, each object should have `name` and `cidr` properties')
// Optional properies are `delegation`, `nsgId` & `natGatewayId`
param subnets array = []

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  location: location
  name: name

  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }

    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        delegations: contains(subnet, 'delegation') ? [
          {
            name: '${subnet.name}-delegation'
            properties: {
              serviceName: subnet.delegation
            }
          }
        ] : []
        addressPrefix: subnet.cidr
        networkSecurityGroup: contains(subnet, 'nsgId') ? {
          id: subnet.nsgId
        } : null
        natGateway: contains(subnet, 'natGatewayId') ? {
          id: subnet.natGatewayId
        } : null
      }
    }]
  }
}

output vnetName string = vnet.name
output vnetId string = vnet.id
output subnets array = [for (name, i) in subnets: {
  name: vnet.properties.subnets[i].name
  id: vnet.properties.subnets[i].id
}]
