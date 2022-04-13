// ============================================================================
// Deploy a container app into a Vnet
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-container-vnet'

@description('Azure region for all resources')
param location string = deployment().location

// ===== Variables ============================================================

var subnetAppsName = 'apps'
var subnetCPName = 'controlplane'
var mysqlDbPassword = uniqueString(appName, location)

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

module logAnalytics '../modules/monitoring/log-analytics.bicep' = {
  scope: resGroup
  name: 'monitoring'
  params: {
    name: 'logs'
  }
}

module network '../modules/network/network-multi.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    name: 'app-vnet'
    addressSpace: '10.75.0.0/16'
    subnets: [
      {
        name: subnetCPName
        cidr: '10.75.0.0/21'
      }
      {
        name: subnetAppsName
        cidr: '10.75.8.0/21'
      }
      {
        name: 'backend'
        cidr: '10.75.16.0/24'
        delegation: 'Microsoft.ContainerInstance/containerGroups'
      }
    ]
  }
}

module containerAppEnv '../modules/containers/app-env.bicep' = {
  scope: resGroup
  name: 'containerAppEnv'
  params: {
    name: 'app-environment'
    logAnalyticsName: logAnalytics.outputs.name
    logAnalyticsResGroup: resGroup.name
    controlPlaneSubnetId: network.outputs.subnets[0].id
    appsSubnetId: network.outputs.subnets[1].id
  }
}

module wordpress '../modules/containers/app.bicep' = {
  scope: resGroup
  name: 'wordpress'
  params: {
    name: 'wordpress'
    environmentId: containerAppEnv.outputs.id
    image: 'wordpress:latest'
    replicasMin: 2
    ingressPort: 80
    ingressExternal: true
    cpu: '2'
    memory: '4.0Gi'
    revisionMode: 'single'
    envs: [
      {
        name: 'WORDPRESS_DB_HOST'
        value: mysql.outputs.ipAddress
      }
      {
        name: 'WORDPRESS_DB_USER'
        value: 'wordpress'
      }
      {
        name: 'WORDPRESS_DB_PASSWORD'
        value: mysqlDbPassword
      }
      {
        name: 'WORDPRESS_DB_NAME'
        value: 'wordpress'
      }
    ]
  }
}

module mysql '../modules/containers/instance.bicep' = {
  scope: resGroup
  name: 'mysql'
  params: {
    name: 'mysql'
    image: 'mysql:5-debian'
    port: 3306
    memoryRequest: '2.0'
    cpuRequest: 2
    ipAddressType: 'private'
    envVars: [
      {
        name: 'MYSQL_RANDOM_ROOT_PASSWORD'
        value: 'yes'
      }
      {
        name: 'MYSQL_USER'
        value: 'wordpress'
      }
      {
        name: 'MYSQL_PASSWORD'
        value: mysqlDbPassword
      }
      {
        name: 'MYSQL_DATABASE'
        value: 'wordpress'
      }
    ]

    subnetId: network.outputs.subnets[2].id
  }
}

output appURL string = 'https://${wordpress.outputs.fqdn}/'
