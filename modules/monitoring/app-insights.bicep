// ============================================================================
// A module to deploy classic App Insights
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// ===== Modules & Resources ==================================================

resource appInsights 'Microsoft.Insights/components@2015-05-01' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// ===== Outputs ==============================================================

output resourceId string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
