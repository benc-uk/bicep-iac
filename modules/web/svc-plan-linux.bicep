// ============================================================================
// A module to deploy a Linux App Service Plan
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location
@allowed([
  'Y1' // Functions consumption plan
  'EP1' // Elastic Premium, should be used for containerized Functions
  'EP2'
  'EP3'
  'F1' // Free, only if you are desperate
  'B1' // Basic aka bad
  'B2'
  'B3'
  'S1' // Standard (very old, don't use)
  'S2'
  'S3'
  'P1v2' // Older premium SKU
  'P2v2'
  'P3v2'
  'P1v3' // Newer premium SKU
  'P2v3'
  'P3v3'
])
param sku string = 'P1v3'
param instanceCount int = 1

// ===== Modules & Resources ==================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: name
  location: location
  kind: 'linux'

  sku: {
    name: sku
    capacity: instanceCount
  }

  properties: {
    reserved: true
  }
}

// ===== Outputs ==============================================================

output resourceId string = appServicePlan.id
