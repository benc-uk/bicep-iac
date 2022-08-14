param name string = resourceGroup().name
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param location string = resourceGroup().location

@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

// ===== Variables ============================================================

// Append suffix, as these resources need to be uniquely named
var resourceName = '${name}${suffix}'

// ===== Modules & Resources ==================================================

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: resourceName
  properties: {
    sku: {
      name: sku
    }
  }
}

// ===== Outputs ==================================================

output id string = logWorkspace.id
output name string = logWorkspace.name
output customerId string = logWorkspace.properties.customerId
output sharedKey string = logWorkspace.listKeys().primarySharedKey
