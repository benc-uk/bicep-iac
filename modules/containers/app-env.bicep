param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Existing Log Analytics workspace name')
param logAnalyticsName string

@description('Resource group containing the Log Analytics workspace')
param logAnalyticsResGroup string

@description('Custom VNet; subnet to be used for the control plane. Leave when using a managed VNet')
param controlPlaneSubnetId string = ''
@description('Custom VNet; subnet to be used for the apps. Leave when using a managed VNet')
param appsSubnetId string = ''
@description('Custom VNet; what type of Load Balancer to use. Leave when using a managed VNet')
param loadBalancerInternal bool = false

// Unlikely you will ever want to change these, but they are exposed as parameters
param dockerBridgeCidr string = '10.1.0.1/16'
param platformReservedCidr string = '10.0.0.0/16'
param platformReservedDnsIP string = '10.0.0.2'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(logAnalyticsResGroup)
}

resource kubeEnv 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  location: location
  name: name

  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }

    vnetConfiguration: controlPlaneSubnetId != '' ? {
      internal: loadBalancerInternal
      infrastructureSubnetId: controlPlaneSubnetId
      runtimeSubnetId: appsSubnetId
      dockerBridgeCidr: dockerBridgeCidr
      platformReservedCidr: platformReservedCidr
      platformReservedDnsIP: platformReservedDnsIP
    } : null
  }
}

output id string = kubeEnv.id
