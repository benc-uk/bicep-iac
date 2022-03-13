// ============================================================================
// Deploy a containerized Function App with supporting resources
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'func-demo'

@description('Azure region for all resources')
param location string = deployment().location

@description('Container image to deploy')
param registry string = 'ghcr.io'
param repo string = 'benc-uk/func-demo'
param tag string = 'latest'

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

// Functions apps need a storage account
module storage '../modules/storage/account.bicep' = {
  scope: resGroup
  name: 'storage'
}

// We create an ACR just as an example, it's not used.
// The image deploy will be pulled from the registry & repo parameter above
module acr '../modules/containers/registry.bicep' = {
  scope: resGroup
  name: 'acr'
}

// Functions apps also need App Insights
module appInsights '../modules/monitoring/app-insights.bicep' = {
  scope: resGroup
  name: 'appInsights'
}

// App Service Plan to host the Function App
module svcPlan '../modules/web/svc-plan-linux.bicep' = {
  scope: resGroup
  name: 'svcPlan'
  params: {
    // You must use elastic premium SKU or a dedicated for containerized Functions Apps
    sku: 'EP1'
  }
}

// Example of adding managed identity 
module managedIdentity '../modules/identity/user-managed.bicep' = {
  scope: resGroup
  name: 'managedIdentity'
}

// Assign some roles to the managed identity
// We assign Reader to the subscription just for the listResGroups demo function
resource role 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid('${subscription().subscriptionId}-${appName}-${location}')
  scope: subscription()
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7'
    principalId: managedIdentity.outputs.principalId
  }
  // Some fake dependencies to try to stop Azure AD race condition on role assignments
  dependsOn: [
    managedIdentity
    functionApp
    svcPlan
    storage
  ]
}

module functionApp '../modules/web/function-app-container.bicep' = {
  scope: resGroup
  name: 'functionApp'
  params: {
    // Common settings for Function apps
    servicePlanId: svcPlan.outputs.resourceId
    storageAccountName: storage.outputs.name
    storageAccountKey: storage.outputs.accountKey
    appInsightsKey: appInsights.outputs.instrumentationKey

    // Container to deploy and run
    registry: registry
    repo: repo
    tag: tag

    // This is the managed identity we created above
    userIdentityResourceId: managedIdentity.outputs.resourceId

    appSettings: [
      // Both settings are used by listResGroups function in the benc-uk/func-demo container
      // And can be removed when running other containers
      {
        name: 'AZURE_SUBSCRIPTION_ID'
        value: subscription().subscriptionId
      }
      {
        name: 'MI_CLIENT_ID'
        value: managedIdentity.outputs.clientId
      }
    ]
  }
}

// ===== Outputs ==============================================================

output functionAppURL string = 'https://${functionApp.outputs.hostname}'
