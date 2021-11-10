// ============================================================================
// Deploy a container app with app container environment and log analytics
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-demoapp'

@description('Azure region for all resources')
param location string = deployment().location

@description('Container image')
param image string = 'ghcr.io/benc-uk/nodejs-demoapp:latest'

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location  
}

module logAnalytics '../modules/monitoring/log-analytics.bicep' = {
  scope: resGroup
  name: 'monitoring'
}

module  containerAppEnv '../modules/compute/container-app-env.bicep' = {
  scope: resGroup
  name: 'containerAppEnv'
  params: {
    logAnalyticsName: logAnalytics.outputs.name
    logAnalyticsResGroup: resGroup.name
  }
}

module demoApp '../modules/compute/container-app.bicep' = {
  scope: resGroup
  name: 'demoApp'
  params: {
    name: 'nodejs-demoapp'
    environmentId: containerAppEnv.outputs.id
    
    image: image

    ingressPort: 3000
    ingressExternal: true

    scaleHttpRequests: 200

    secrets: [
      {
        // OPTIONAL - OpenWeather API key, enables the weather feature of the demo app
        // Get a free API key here https://home.openweathermap.org/users/sign_up
        name: 'weather-key-secret'
        value: '__CHANGE_ME__'
      }
    ]

    envs: [
      {
        name: 'WEATHER_API_KEY'
        secretref: 'weather-key-secret'
      }
    ]
  }
}

// ===== Outputs ==============================================================

output appURL string = 'https://${demoApp.outputs.fqdn}'
