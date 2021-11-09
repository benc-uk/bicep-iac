// ============================================================================
// Deploy AKS into a VNet with CNI and monitoring
// ============================================================================

targetScope = 'subscription'

param clusterName string = 'aks-cluster'
param location string = deployment().location

param enableMonitoring bool = true

param clusterConfig object = {
  version: '1.21.2'
  nodeSize: 'Standard_D4s_v4'
  nodeCount: 1
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
  name: 'monitoring'
}

module aks '../modules/kubernetes/aks.bicep' = {
  scope: resGroup
  name: 'aks'
  params: {
    // Base AKS config like version and nodes sizes
    config: clusterConfig

    // Network details
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.subnetName
    
    // Optional features
    logsWorkspaceId: enableMonitoring ? logAnalytics.outputs.id : ''
  }
}

output clusterName string = aks.outputs.clusterName
output clusterFQDN string = aks.outputs.clusterFQDN
output aksState string = aks.outputs.provisioningState
