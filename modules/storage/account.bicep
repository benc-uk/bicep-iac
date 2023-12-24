// ============================================================================
// A module to deploy a Storage Account
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// Remove for resources that DONT need unique names
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('Pick your storage SKU')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

@description('Pick your account kind')
@allowed([
  'StorageV2'
  'Storage'
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
])
param kind string = 'StorageV2'

@description('Access tier')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

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
    accessTier: accessTier
    allowSharedKeyAccess: true
  }
}

// ===== Outputs ==============================================================

output resourceId string = storageAccount.id
output name string = resourceName
output accountKey string = storageAccount.listKeys().keys[0].value
