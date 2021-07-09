// ============================================================================
// Deploy a multi node RKE2 cluster on Azure
// ============================================================================

targetScope = 'subscription'

// Resource group which will be created and contain everything
param resGroupName string
// Azure region for all resources
param location string
// Suffix is a string appended to all resource names
param suffix string = 'rke2' //-${substring(uniqueString(resGroupName), 0, 4)}'
// Password or SSH key to connect to the servers & agent node VMs
param authString string
// Use SSH key or password
param authType string = 'publicKey'
// Number of agent node VMs to deploy
param agentCount int = 3
// VM sizes to deploy
param serverVMSize string = 'Standard_D8_v3'
param agentVMSize string = 'Standard_D8_v3'
// Which cloud to use
@allowed([
  'AzurePublic'
  'AzureUSGovernmentCloud'
])
param cloudName string = 'AzurePublic'

// ===== Variables ============================================================

// Constant GUID for contributor role
var contributorRoleGUID = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
// Token used for agents to join the cluster
var rke2Token = uniqueString(resGroupName, suffix)
// Used to give the server a public FQDN
var dnsSuffix = substring(uniqueString(resGroup.name), 0, 4)
// Different domain for different clouds
var pipDomain = (cloudName == 'AzureUSGovernmentCloud' ? 'usgovcloudapi.net' : 'azure.com')
// Name for server, will get suffixed
var serverName = 'server'

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
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
      '22'
      '6443'
    ]
  }
}

module vmIdentity '../modules/identity/user-managed.bicep' = {
  scope: resGroup
  name: 'vmIdentity'
  params: {
    location: location
    suffix: suffix
  }
}

module serverConfig 'config/server.bicep' = {
  name: 'serverConfig'
  scope: resGroup
  params: {
    token: rke2Token
    serverHost: '${serverName}-${suffix}'
    region: location
    clientId: vmIdentity.outputs.clientId
    resourceGroup: resGroupName
    subscriptionId: subscription().subscriptionId
    tenantId: subscription().tenantId
    vnetName: suffix
    nsgName: suffix
    subnetName: network.outputs.subnetName
    cloudName: cloudName
    serverHostPublic: '${serverName}-${suffix}-${dnsSuffix}.${location}.cloudapp.${pipDomain}'
  }
}

module agentConfig 'config/agent.bicep' = {
  name: 'agentConfig'
  scope: resGroup
  params: {
    token: rke2Token
    serverHost: '${serverName}-${suffix}'
    region: location
    clientId: vmIdentity.outputs.clientId
    resourceGroup: resGroupName
    subscriptionId: subscription().subscriptionId
    tenantId: subscription().tenantId
    vnetName: suffix
    nsgName: suffix
    subnetName: network.outputs.subnetName
    cloudName: cloudName
  }
}

module server '../modules/vm/linux.bicep' = {
  scope: resGroup
  name: 'server'
  params: {
    location: location
    suffix: suffix
    name: serverName
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: authType
    cloudInit: serverConfig.outputs.cloudInit
    size: serverVMSize
    userIdentityResourceId: vmIdentity.outputs.resourceId
    publicIp: true
    dnsSuffix: dnsSuffix
  }
}

module agent '../modules/vm/linux.bicep' = [for i in range(0, agentCount): {
  scope: resGroup
  name: 'agent-${i}'
  params: {
    location: location
    suffix: suffix
    name: 'agent${i}'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: authType
    cloudInit: agentConfig.outputs.cloudInit
    size: agentVMSize
    publicIp: false
  }
}]

module roles '../modules/identity/res-group-role.bicep' = {
  scope: resGroup
  // This is NOT actually dependant on these but Azure AD is so awful and slow
  // we need a delay after creating the identity before assigning the role
  dependsOn: [ 
    server
    agent
    vmIdentity
  ]
  name: 'roles'
  params: {
    suffix: suffix
    principalId: vmIdentity.outputs.principalId
    roleId: contributorRoleGUID
  }
}

output serverIP string = server.outputs.publicIP
output serverFQDN string = server.outputs.dnsName
