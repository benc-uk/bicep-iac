targetScope = 'subscription'

param resGroupName string = 'aks-bicep.temp'
param location string = 'northeurope'
param suffix string = 'test-${substring(uniqueString(resGroupName), 0, 4)}'

param enableVnodes bool = true
param enableMonitoring bool = true

param kube object {
  default: {
    version: '1.19.7'
    nodeSize: 'Standard_DS2_v2'
    nodeCount: 2
    nodeCountMax: 10
  }
}

resource resGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resGroupName
  location: location  
}

module network 'modules/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    location: location
    suffix: suffix
    enableVnodes: enableVnodes
  }
}

module other 'modules/monitoring.bicep' = if(enableMonitoring) {
  scope: resGroup
  name: 'monitors'
  params: {
    location: location
    suffix: suffix
  }
}

module aks 'modules/aks.bicep' = {
  scope: resGroup
  name: 'aks'
  params: {
    location: location
    suffix: suffix
    // Base AKS config like version and nodes sizes
    kube: kube

    // Network details
    netVnet: network.outputs.vnetName
    netSubnet: network.outputs.aksSubnetName
    
    // Optional features
    netSubnetVnodes: enableVnodes ? network.outputs.vodesSubnetName : ''
    logsWorkspaceId: enableMonitoring ? other.outputs.logWorkspaceId : ''
  }
}

module identity 'modules/identity.bicep' = {
  scope: resourceGroup('MC_${resGroupName}_aks-${suffix}_${location}')
  name: 'identity'
  params: {
    aksName: aks.outputs.clusterName
  }
}

module roles 'modules/roles.bicep' = {
  scope: resGroup
  name: 'roles'
  params: {
    suffix: suffix
    principalId: identity.outputs.vnodesPrincipalId
  }
}

output clusterName string = aks.outputs.clusterName
output clusterFQDN string = aks.outputs.clusterFQDN
output aksState string = aks.outputs.provisioningState
output vnodesPrincipalId string = identity.outputs.vnodesPrincipalId
