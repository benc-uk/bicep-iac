// ===============================================================================
// A module to deploy a non-containerized Function App, i.e. for code deployment
// ===============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param servicePlanId string
param appSettings array = []

@description('Runtime language, e.g. dotnet, node, python')
@allowed([ 'dotnet', 'node', 'python', 'java', 'dotnet-isolated' ])
param runtime string

// Function app settings
param functionsVersion int = 4
param storageAccountName string
@secure()
param storageAccountKey string
param appInsightsKey string

// Optional managed identity settings
@description('Resource ID of user managed identity or leave as empty string')
param userIdentityResourceId string = ''
@description('Enable system assigned managed identity')
param systemAssignedIdentity bool = false

// ===== Variables ============================================================

var kind = 'functionapp,linux'
var resourceName = '${name}${suffix}'

var functionAppSettings = [
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
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
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet'
  }
]

var appSettingsMerged = concat(appSettings, functionAppSettings)

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

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
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
    }
  }
}

// ===== Outputs ==============================================================

output resourceId string = functionApp.id
output hostname string = functionApp.properties.hostNames[0]
output systemAssignedIdentityPrincipalId string = (systemAssignedIdentity ? functionApp.identity.principalId : 'none')
