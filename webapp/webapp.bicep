// ============================================================================
// Deploy a containerized web app + app service plan
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and base name for all resources')
param appName string 
@description('Azure region for all resources')
param location string = deployment().location
@description('Existing App Service Plan, leave blank to create a new one')
param existingSvcPlanId string = ''

// ===== Variables ============================================================


// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location  
}

module servicePlan '../modules/web/svc-plan-linux.bicep' = if(existingSvcPlanId == '') {
  scope: resGroup
  name: 'servicePlan'
  params: {
    sku: 'S1'
  }
}

module webApp '../modules/web/webapp-container.bicep' = {
  scope: resGroup
  name: 'webApp'
  params: {
    servicePlanId: existingSvcPlanId == '' ? servicePlan.outputs.resourceId : existingSvcPlanId
    registry: 'ghcr.io'
    repo: 'benc-uk/nodejs-demoapp'
  }
}

// ===== Outputs ==============================================================

output url string = 'https://${webApp.outputs.hostname}'
