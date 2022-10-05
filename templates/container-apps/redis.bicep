// ============================================================================
// Deploy a container app with app container environment and log analytics
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-redis'

@description('Azure region for all resources')
param location string = deployment().location

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

module logAnalytics '../../modules/monitoring/log-analytics.bicep' = {
  scope: resGroup
  name: 'monitoring'
}

module containerAppEnv '../../modules/containers/app-env.bicep' = {
  scope: resGroup
  name: 'containerAppEnv'
  params: {
    logAnalyticsName: logAnalytics.outputs.name
    logAnalyticsResGroup: resGroup.name
  }
}

module demoApp '../../modules/containers/app.bicep' = {
  scope: resGroup
  name: 'demoApp'
  params: {
    name: appName
    environmentId: containerAppEnv.outputs.id

    image: 'redis'

    ingressPort: 6379
    ingressExternal: true
    ingressTransport: 'tcp'
  }
}

// ===== Outputs ==============================================================

output appURL string = 'https://${demoApp.outputs.fqdn}'
