param name string = resourceGroup().name
param location string = resourceGroup().location 

@description('Existing Log Analytics workspace name')
param logAnalyticsName string
@description('Resource group containing the Log Analytics workspace')
param logAnalyticsResGroup string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' existing = {
  name: logAnalyticsName
  scope: resourceGroup(logAnalyticsResGroup)
}

resource kubeEnv 'Microsoft.Web/kubeEnvironments@2021-02-01' = {
  location: location
  name: name
  kind: 'containerenvironment'
  
  properties: {
    type: 'Managed'
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId 
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

output id string = kubeEnv.id
