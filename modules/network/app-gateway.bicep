param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Place into this subnet')
param subnetId string = ''

@description('Used to give the public IP a unique FQDN')
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 5)

@description('Create a new public IP or not')
param newPublicIp bool = true

@description('Assign this public IP, set newPublicIp to false')
param existingPublicIpId string = ''

@description('SKU configuration for size and features')
param skuName string = 'Standard_v2'
@description('SKU configuration for size and features')
param skuTier string = 'Standard_v2'
@description('Number of instances to create')
param skuCapacity int = 1

@description('Flavour of HTTP to use, plain or HTTPS')
@allowed([
  'Http'
  'Https'
])
param protocol string = 'Http'
@description('Port to use for HTTP')
param port int = 80

// ===== Variables ============================================================

var pipConfig = {
  id: existingPublicIpId != '' ? existingPublicIpId : pip.id
}

// ===== Modules & Resources ==================================================

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = if (newPublicIp) {
  location: location
  name: name
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: '${name}-${dnsSuffix}'
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2020-06-01' = {
  location: location
  name: name

  properties: {
    sku: {
      name: skuName
      tier: skuTier
      capacity: skuCapacity
    }

    gatewayIPConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]

    frontendIPConfigurations: [
      {
        name: 'default'
        properties: {
          publicIPAddress: pipConfig
        }
      }
    ]

    frontendPorts: [
      {
        name: 'default'
        properties: {
          port: port
        }
      }
    ]

    backendAddressPools: [
      {
        name: 'default'
      }
    ]

    backendHttpSettingsCollection: [
      {
        name: 'default'
        properties: {
          port: port
          protocol: protocol
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
        }
      }
    ]

    httpListeners: [
      {
        name: 'default'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'default')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'default')
          }
          protocol: protocol
        }
      }
    ]

    requestRoutingRules: [
      {
        name: 'default'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'default')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'default')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'default')
          }
        }
      }
    ]
  }
}

output appGatewayId string = appGateway.id
