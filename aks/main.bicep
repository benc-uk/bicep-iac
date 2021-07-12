//
// Deploy AKS with CNI and monitoring
//

targetScope = 'subscription'

param resGroupName string
param location string = 'northeurope'
param suffix string = 'test-${substring(uniqueString(resGroupName), 0, 4)}'

param enableMonitoring bool = true

param cluster object = {
  version: '1.20.7'
  nodeSize: 'Standard_DS2_v2'
  nodeCount: 2
  nodeCountMax: 10
}

resource resGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resGroupName
  location: location  
}

module network '../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    location: location
    suffix: suffix
    openPorts: [
      '0'
    ]
  }
}

module other '../modules/monitoring/log-analytics.bicep' = if(enableMonitoring) {
  scope: resGroup
  name: 'monitors'
  params: {
    location: location
    suffix: suffix
  }
}

module aks '../modules/kubernetes/aks.bicep' = {
  scope: resGroup
  name: 'aks'
  params: {
    location: location
    suffix: suffix
    // Base AKS config like version and nodes sizes
    cluster: cluster

    // Network details
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.subnetName
    
    // Optional features
    logsWorkspaceId: enableMonitoring ? other.outputs.logWorkspaceId : ''
  }
}

output clusterName string = aks.outputs.clusterName
output clusterFQDN string = aks.outputs.clusterFQDN
output aksState string = aks.outputs.provisioningState
