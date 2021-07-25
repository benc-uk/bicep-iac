//
// Deploy AKS with CNI and monitoring
//

targetScope = 'subscription'

param clusterName string = 'aks-cluster'
param location string = deployment().location

param enableMonitoring bool = true

param clusterParams object = {
  version: '1.20.7'
  nodeSize: 'Standard_DS2_v2'
  nodeCount: 2
  nodeCountMax: 10
}

resource resGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: clusterName
  location: location  
}

module network '../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
}

module logAnalytics '../modules/monitoring/log-analytics.bicep' = if(enableMonitoring) {
  scope: resGroup
  name: 'monitors'
}

module aks '../modules/kubernetes/aks.bicep' = {
  scope: resGroup
  name: 'aks'
  params: {
    // Base AKS config like version and nodes sizes
    cluster: clusterParams

    // Network details
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.subnetName
    
    // Optional features
    logsWorkspaceId: enableMonitoring ? logAnalytics.outputs.logWorkspaceId : ''
  }
}

output clusterName string = aks.outputs.clusterName
output clusterFQDN string = aks.outputs.clusterFQDN
output aksState string = aks.outputs.provisioningState
