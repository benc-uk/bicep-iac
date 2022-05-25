// ============================================================================
// A module to deploy Azure Maps
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('SKU / pricing tier')
@allowed([
  'G2'
  'S1'
  'S0'
])
param sku string = 'G2'

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource azureMaps 'Microsoft.Maps/accounts@2021-12-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
}

// ===== Outputs ==============================================================

output resourceId string = azureMaps.id
output key string = azureMaps.listKeys().primaryKey
