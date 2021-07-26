// ============================================================================
// A module to deploy a LINUX App Service Plan
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location
@allowed([
  'F1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
param sku string = 'S1'
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
