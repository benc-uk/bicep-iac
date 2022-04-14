// ============================================================================
// Deploy Keycloak and MS-SQL Server as Container App and Container Instance
// ============================================================================

// NOTE! Needs more work to run a first time create of the keycloak database in MSSQL

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-keycloak-new'

@description('Azure region for all resources')
param location string = deployment().location

// ===== Variables ============================================================

var subnetAppsName = 'apps'
var subnetCPName = 'controlplane'
var dbPassword = '${uniqueString(appName, location)}!2022'
var keycloakPassword = '${uniqueString(appName, location)}!kckc'

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

module keycloak '../modules/containers/app.bicep' = {
  scope: resGroup
  name: 'keycloak'
  params: {
    name: 'keycloakx'
    environmentId: containerAppEnv.outputs.id
    image: 'ghcr.io/benc-uk/keycloak:nodbnew'
    replicasMin: 1
    replicasMax: 1
    ingressPort: 8080
    ingressExternal: true
    cpu: '2'
    memory: '4.0Gi'
    revisionMode: 'single'
    envs: [
      {
        name: 'KEYCLOAK_ADMIN'
        value: 'superadmin'
      }
      {
        name: 'KEYCLOAK_ADMIN_PASSWORD'
        value: keycloakPassword
      }
      {
        name: 'KC_HOSTNAME_STRICT'
        value: 'false'
      }
      {
        name: 'KC_HOSTNAME_STRICT_HTTPS'
        value: 'false'
      }
      {
        name: 'KC_HTTP_ENABLED'
        value: 'true'
      }
      {
        name: 'KC_PROXY'
        value: 'edge'
      }

      {
        name: 'KC_DB_DATABASE'
        value: 'keycloak'
      }
      {
        name: 'KC_DB_USERNAME'
        value: 'sa'
      }
      {
        name: 'KC_DB_PASSWORD'
        value: dbPassword
      }
      {
        name: 'KC_DB_URL_HOST'
        value: mssql.outputs.ipAddress
      }
    ]
  }
}

module mssql '../modules/containers/instance.bicep' = {
  scope: resGroup
  name: 'msqsl'
  params: {
    name: 'mssql'
    image: 'mcr.microsoft.com/mssql/server:2019-latest'
    port: 1433
    memoryRequest: '4.0'
    cpuRequest: 2
    ipAddressType: 'private'
    envVars: [
      {
        name: 'MSSQL_SA_PASSWORD'
        value: dbPassword
      }
      {
        name: 'ACCEPT_EULA'
        value: 'y'
      }
    ]

    subnetId: network.outputs.subnets[2].id
  }
}

//output appURL string = 'https://${keycloak.outputs.fqdn}/'
