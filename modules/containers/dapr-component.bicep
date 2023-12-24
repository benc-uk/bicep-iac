// ============================================================================
// Container App Environment to host container apps
// ============================================================================

@description('Existing Container App Environment')
param environmentName string

@description('Name of the Dapr component')
param name string

@description('Type of the Dapr component')
param componentType string

@description('Version of the Dapr component')
param version string = 'v1'

@description('Metadata to configure the Dapr component')
param componentMetadata array = []

@description('Scopes to assign to the Dapr component')
param scopes array = []

// ===== Modules & Resources ==================================================

resource managedEnv 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

resource daprComponent 'Microsoft.App/managedEnvironments/daprComponents@2023-05-01' = {
  name: name
  parent: managedEnv

  properties: {
    componentType: componentType
    version: version
    metadata: componentMetadata
    scopes: scopes
  }
}
