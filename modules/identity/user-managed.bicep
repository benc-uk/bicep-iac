param name string = resourceGroup().name
param location string = resourceGroup().location

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' = {
  name: name
  location: location
}

output resourceId string = identity.id
output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
output tenantId string = identity.properties.tenantId
