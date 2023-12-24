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
param kind string = 'web'

// Set these if the registry requires auth 
param registryUser string = ''
@secure()
param registryPassword string = ''

// Optional managed identity settings
@description('Resource ID of user managed identity or leave as empty string')
param userIdentityResourceId string = ''
@description('Enable system assigned managed identity')
param systemAssignedIdentity bool = false

// ===== Variables ============================================================

var resourceName = '${name}${suffix}'

var settingsDockerServer = [
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: 'https://${registry}'
  }
]

var settingsDockerAuth = registryUser == '' ? [] : [
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

var userIdentityConfig = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${userIdentityResourceId}': {}
  }
}

var systemIdentityConfig = {
  type: 'SystemAssigned'
}

// ===== Modules & Resources ==================================================

resource webApp 'Microsoft.Web/sites@2021-01-15' = {
  name: resourceName
  location: location
  kind: kind

  identity: (userIdentityResourceId == '') ? (systemAssignedIdentity ? systemIdentityConfig : null) : userIdentityConfig

  properties: {
    serverFarmId: servicePlanId
    reserved: true
    httpsOnly: true
    siteConfig: {
      appSettings: appSettingsMerged
      linuxFxVersion: 'DOCKER|${registry}/${repo}:${tag}'
    }
  }
}

// ===== Outputs ==============================================================

output resourceId string = webApp.id
output hostname string = webApp.properties.hostNames[0]
output systemAssignedIdentityPrincipalId string = (systemAssignedIdentity ? webApp.identity.principalId : 'none')
