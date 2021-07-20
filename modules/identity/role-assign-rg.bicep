param roleId string 
param principalId string 
param nameGuid string = newGuid()

resource role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: nameGuid
  scope: resourceGroup()
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleId}'
    principalId: principalId
  }
}
