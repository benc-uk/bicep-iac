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

// Function app settings
param functionsVersion int = 4
param storageAccountName string
@secure()
param storageAccountKey string
param appInsightsKey string

// Set these if the registry requires auth 
param registryUser string = ''
param registryPassword string = ''

// Optional managed identity settings
@description('Resource ID of user managed identity or leave as empty string')
param userIdentityResourceId string = ''
@description('Enable system assigned managed identity')
param systemAssignedIdentity bool = false

// ===== Variables ============================================================

var kind = 'functionapp,linux,container'
var resourceName = '${name}${suffix}'

var functionAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: 'funcapp-${name}'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsightsKey
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~${functionsVersion}'
  }
  {
    name: 'FUNCTION_APP_EDIT_MODE'
    value: 'readOnly'
  }
  {
    name: 'DOCKER_CUSTOM_IMAGE_NAME'
    value: '${registry}/${repo}:${tag}'
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
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

var appSettingsMerged = concat(appSettings, settingsDockerAuth, functionAppSettings)

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

resource functionApp 'Microsoft.Web/sites@2021-01-15' = {
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

output resourceId string = functionApp.id
output hostname string = functionApp.properties.hostNames[0]
output systemAssignedIdentityPrincipalId string = (systemAssignedIdentity ? functionApp.identity.principalId : 'none')
