param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Used to give the public IP a unique FQDN')
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 5)

// ===== Modules & Resources ==================================================

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
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

resource natGateway 'Microsoft.Network/natGateways@2021-02-01' = {
  location: location
  name: name
  sku: {
    name: 'Standard'
  }

  properties: {
    publicIpAddresses: [
      {
        id: pip.id
      }
    ]
  }
}

output resourceId string = natGateway.id
