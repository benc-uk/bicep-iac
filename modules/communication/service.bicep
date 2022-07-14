// ============================================================================
// A module to deploy Azure Communcation Services
// ============================================================================

param name string = resourceGroup().name
param dataLocation string = 'United States'

// Remove for resources that DONT need unique names
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

// ===== Variables ============================================================

// Append suffix, as these resources need to be uniquely named
var resourceName = '${name}${suffix}'
var location = 'global'

// ===== Modules & Resources ==================================================

resource acs 'Microsoft.Communication/communicationServices@2021-10-01-preview' = {
  name: resourceName
  location: location
  properties: {
    dataLocation: dataLocation
  }
}

// ===== Outputs ==============================================================

output resourceId string = acs.id
output resourceName string = acs.name
output hostName string = acs.properties.hostName
