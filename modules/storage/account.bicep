// ============================================================================
// A module to deploy a Storage Account
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// Remove for resources that DONT need unique names
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('Pick your storage SKU')
param sku string = 'Standard_LRS'
@description('Pick your account kind')
param kind string = 'StorageV2'

// ===== Variables ============================================================

var resourceName = replace('${name}${suffix}', '-', '')

// ===== Modules & Resources ==================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: resourceName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

// ===== Outputs ==============================================================

output resourceId string = storageAccount.id
output name string = resourceName
output accountKey string = storageAccount.listKeys().keys[0].value
