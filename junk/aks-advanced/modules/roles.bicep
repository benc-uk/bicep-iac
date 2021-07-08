param principalId string
param suffix string

resource aciRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(suffix)
  properties: {
    principalId: principalId
    // Contributor role
    roleDefinitionId: '${subscription().id}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
}