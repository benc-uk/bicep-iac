// ==============================================================================
// Deploy Wordpress & MySQL into a VNet and link them up, expose only Wordpress
// ==============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-wordpress'

@description('Azure region for all resources')
param location string = deployment().location

// ===== Variables ============================================================

var mysqlDbPassword = uniqueString(appName, location)
var wordpressImage = 'wordpress:latest'
var mySQLImage = 'mysql:5-debian'

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
        name: 'controlplane'
        cidr: '10.75.0.0/21'
      }
      {
        name: 'apps'
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
    image: wordpressImage
    replicasMin: 1
    replicasMax: 1
    revisionMode: 'single'

    ingressPort: 80
    ingressExternal: true

    cpu: '1'
    memory: '1Gi'

    secrets: [
      {
        name: 'db-password'
        value: mysqlDbPassword
      }
    ]

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
        secretref: 'db-password'
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
    image: mySQLImage

    memoryRequest: '1.5'
    cpuRequest: '0.75'

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
        secureValue: mysqlDbPassword
      }
      {
        name: 'MYSQL_DATABASE'
        value: 'wordpress'
      }
    ]

    port: 3306
    ipAddressType: 'Private'
    subnetId: network.outputs.subnets[2].id
  }
}

output appURL string = 'https://${wordpress.outputs.fqdn}/'
