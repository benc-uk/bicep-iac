// ============================================================================
// THIS DOESN'T WORK .... YET
// Need to work out how to connect two apps using TCP rather than HTTP ingress
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and base name for all resources')
param appName string = 'wordpress'
@description('Azure region for all resources')
param location string = deployment().location

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

module  wordpress '../modules/compute/container-app.bicep' = {
  scope: resGroup
  name: 'wordpress'
  params: {
    name: 'wordpress'
    environmentId: containerAppEnv.outputs.id
    image: 'wordpress:latest'
    replicasMin: 3
    ingressPort: 80
    envs: [
      {
        name: 'WORDPRESS_DB_HOST'
        value: 'mysql'//.blueisland-569fa97f.northcentralusstage.azurecontainerapps.io'
      }
      {
        name: 'WORDPRESS_DB_USER'
        value: 'wordpress'
      }
      {
        name: 'WORDPRESS_DB_PASSWORD'
        value: '__CHANGE_ME__'
      }
      {
        name: 'WORDPRESS_DB_NAME'
        value: 'wordpress'
      }
    ]
  }
}

module  mySQL '../modules/compute/container-app.bicep' = {
  scope: resGroup
  name: 'mySQL'
  params: {
    name: 'mysql'
    environmentId: containerAppEnv.outputs.id
    image: 'mysql:5.7'
    replicasMin: 1
    replicasMax: 1
    envs: [
      {
        name: 'MYSQL_ROOT_PASSWORD'
        value: '__CHANGE_ME__'
      }
      {
        name: 'MYSQL_DATABASE'
        value: 'wordpress'
      }
      {
        name: 'MYSQL_USER'
        value: 'wordpress'
      }
      {
        name: 'MYSQL_PASSWORD'
        value: '__CHANGE_ME__'
      }
    ]
  }
}

// ===== Outputs ==============================================================
