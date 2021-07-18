param suffix string
param prefix string = 'pip-'
param location string 
param sku string = 'Standard'
param allocation string = 'Static'
param dnsSuffix string = substring(uniqueString(resourceGroup().name), 0, 4)

// ===== Variables ============================================================

var name = '${prefix}${suffix}'

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
      domainNameLabel: '${prefix}${suffix}-${dnsSuffix}'
    }
  }
}

output ipAddress string = pip.properties.ipAddress
output fqdn string = pip.properties.dnsSettings.fqdn
output resourceId string = pip.id
