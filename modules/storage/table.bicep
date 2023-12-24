// ============================================================================
// A module to deploy a Storage Account Table to an existing Storage Account
// ============================================================================

@description('Name of existing Storage Account')
param storageAccountName string

@description('Name of table to create')
param name string

// ===== Modules & Resources ==================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' existing = {
  name: storageAccountName
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = {
  parent: tableService
  name: name
}
