// ============================================================================
// A module to deploy a Blob container to an existing Storage Account
// ============================================================================

@description('Name of existing Storage Account')
param storageAccountName string

@description('Name of table to create')
param name string

@description('Public access level for container')
@allowed([
  'None'
  'Blob'
  'Container'
])
param publicAccess string = 'None'

// ===== Modules & Resources ==================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobService
  name: name

  properties: {
    publicAccess: publicAccess
  }
}
