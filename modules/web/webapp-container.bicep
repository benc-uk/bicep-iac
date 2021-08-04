// ============================================================================
// A module to deploy containerised web app from a container image
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param servicePlanId string
param registry string = 'docker.io'
param repo string
param tag string = 'latest'
param appSettings array = []

// Set these if the registry requires auth 
param registryUser string = ''
param registryPassword string = ''

// ===== Variables ============================================================

var resourceName = '${name}${suffix}'

var settingsDockerServer =  [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: registry
  }   
]

var settingsDockerAuth = registryUser == '' ? [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: registry
  }
] : [
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: registryUser
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: registryPassword
  }
]

var appSettingsMerged = concat(appSettings, settingsDockerServer, settingsDockerAuth)

// ===== Modules & Resources ==================================================

resource webApp 'Microsoft.Web/sites@2021-01-15' = {
  name: resourceName
  location: location
  properties: {
    serverFarmId: servicePlanId
    siteConfig: {
      appSettings: appSettingsMerged
      linuxFxVersion: 'DOCKER|${registry}/${repo}:${tag}'
    }
  }
}

// ===== Outputs ==============================================================

output resourceId string = webApp.id
output hostname string = webApp.properties.hostNames[0]
