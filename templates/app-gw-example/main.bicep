targetScope = 'subscription'

param baseName string = 'testest'
param location string = deployment().location

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: baseName
  location: location
}

module network '../../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
}

module appGateway '../../modules/network/app-gateway.bicep' = {
  name: 'app-gw'
  scope: resGroup

  params: {
    //newPublicIp: true
    subnetId: network.outputs.subnetId
    existingPublicIpId: '/subscriptions/52512f28-c6ed-403e-9569-82a9fb9fec91/resourceGroups/testest/providers/Microsoft.Network/publicIPAddresses/smellybob'
  }
}
