// ============================================================================
// A module to deploy Azure Container Registry
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// Remove for resources that DONT need unique names
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('Which pricing and feature tier to use')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Standard'

// ===== Variables ============================================================

var resourceName = replace('${name}${suffix}', '-', '')

// ===== Modules & Resources ==================================================

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: resourceName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

// ===== Outputs ==============================================================

output resourceId string = acr.id
