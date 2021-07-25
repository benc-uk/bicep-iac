param name string = resourceGroup().name
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param location string = resourceGroup().location
param sku string = 'Free'

// ===== Variables ============================================================

// Append suffix
var resourceName = '${name}${suffix}'

// ===== Modules & Resources ==================================================

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: resourceName
  properties:{
    sku:{
      name: sku
    }
  }
}

// ===== Outputs ==================================================

output logWorkspaceId string = logWorkspace.id
