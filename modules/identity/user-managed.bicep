param name string = resourceGroup().name
param location string = resourceGroup().location 

resource vmIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name
  location: location
}

output resourceId string = vmIdentity.id
output principalId string = vmIdentity.properties.principalId
output clientId string = vmIdentity.properties.clientId
output tenantId string = vmIdentity.properties.tenantId
