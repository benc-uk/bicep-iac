param name string = resourceGroup().name
param location string = resourceGroup().location
param sku string = 'Standard'
param allocation string = 'Static'
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 5)

// ===== Modules & Resources ==================================================

resource pip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  location: location
  name: name
  sku: {
    name: sku
  }

  properties: {
    publicIPAllocationMethod: allocation
    dnsSettings: {
      domainNameLabel: '${name}-${dnsSuffix}'
    }
  }
}

output ipAddress string = pip.properties.ipAddress
output fqdn string = pip.properties.dnsSettings.fqdn
output resourceId string = pip.id
