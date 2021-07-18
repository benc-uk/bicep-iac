param suffix string
param prefix string = 'lb-'
param location string 

param sku string = 'Standard'
param publicIpId string = ''
param port int 

// ===== Variables ============================================================

var name = '${prefix}${suffix}'
var publicIpConfig = {
  id: publicIpId
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
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', name, 'frontend')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', name, 'probe_6443')
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

output backendPoolId string = loadBalancer.properties.backendAddressPools[0].id
