param suffix string
param prefix string = 'aks-'
param location string 

param netVnet string
param netSubnet string
param logsWorkspaceId string = ''

param cluster object = {
  version: '1.19.7'
  nodeSize: 'Standard_DS2_v2'
  nodeCount: 1
  nodeCountMax: 10
}

var addOns = {
  // Enable monitoring add on, only if logsWorkspaceId is set
  omsagent: logsWorkspaceId != '' ? {
    enabled: true
    config: {
      logAnalyticsWorkspaceResourceID: logsWorkspaceId
    }
  } : {}
}

resource aks 'Microsoft.ContainerService/managedClusters@2020-12-01' = {
  name: '${prefix}${suffix}'
  location: location
  
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: '${prefix}${suffix}'
    kubernetesVersion: cluster.version
    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', netVnet, netSubnet)
        vmSize: cluster.nodeSize
        enableAutoScaling: true
        count: cluster.nodeCount
        minCount: cluster.nodeCount
        maxCount: cluster.nodeCountMax
      }
    ]
    
    // Enable advanced networking and policy
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
    }

    // Add ons are configured above, as a conditional variable object
    addonProfiles: addOns
  }
}

output clusterName string = aks.name
output clusterFQDN string = aks.properties.fqdn
output provisioningState string = aks.properties.provisioningState
