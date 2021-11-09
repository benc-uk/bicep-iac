param name string = resourceGroup().name
param location string = resourceGroup().location 

param netVnet string
param netSubnet string
param logsWorkspaceId string = ''

param config object = {
  version: '1.19.7'
  nodeSize: 'Standard_DS2_v2'
  nodeCount: 2
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

resource aks 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  name: name
  location: location
  
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    dnsPrefix: name
    kubernetesVersion: config.version
    agentPoolProfiles: [
      {
        name: 'default'
        mode: 'System'
        vnetSubnetID: resourceId('Microsoft.Network/virtualNetworks/subnets', netVnet, netSubnet)
        vmSize: config.nodeSize
        enableAutoScaling: true
        count: config.nodeCount
        minCount: config.nodeCount
        maxCount: config.nodeCountMax
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
