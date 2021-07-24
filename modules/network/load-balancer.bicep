param name string = resourceGroup().name
param location string = resourceGroup().location

param sku string = 'Standard'

// Must supply one of these, BUT DO NOT SUPPLY BOTH
param publicIpId string = ''
param subnetId string = ''

param port int 
param enableFloatingIP bool = false

// ===== Variables ============================================================

var publicIpConfig = {
  id: publicIpId
}
var subnetConfig = {
  id: subnetId
}

// ===== Modules & Resources ==================================================

resource loadBalancer 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }

  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          publicIPAddress: publicIpId != '' ? publicIpConfig : null
          subnet: subnetId != '' ? subnetConfig : null
        }
      }
    ]

    loadBalancingRules: [
      {
        name: 'rule_${port}'
        properties: {
          frontendPort: port
          backendPort: port
          protocol: 'Tcp'
          enableFloatingIP: enableFloatingIP
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, 'frontend')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', name, 'probe_${port}')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', name, 'backend')
          }
        }
      }
    ]

    probes: [
      {
        name: 'probe_${port}'
        properties: {
          port: port
          protocol: 'Tcp'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]

    backendAddressPools: [
      {
        name: 'backend'
      }
    ]
  }
}

// Frontend IP is either private if subnetId is provided, otherwise assume public
output frontendIp string = subnetId != '' ? loadBalancer.properties.frontendIPConfigurations[0].properties.privateIPAddress : reference(publicIpId, '2020-11-01').ipAddress
output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
