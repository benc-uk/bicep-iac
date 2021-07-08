//
// Deploy a multi node RKE2 cluster on Azure
//

targetScope = 'subscription'

param resGroupName string
param location string
// Suffix is a string appended to all resource names
param suffix string = 'rke2' //-${substring(uniqueString(resGroupName), 0, 4)}'

// Password or SSH key to connect to the servers & agent node VMs
param authString string
// Use SSH key or password
param authType string = 'sshPublicKey'
// Number of agent node VMs to deploy
param agentCount int = 1
// VM sizes
param serverVMSize string = 'Standard_D16s_v4'
param agentVMSize string = 'Standard_D16s_v4'
// Token used for agents to join the cluster
param rke2Token string = uniqueString(resGroupName, suffix)

// Constant GUID for contributor role
var contributorRoleGUID = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

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
    serverHost: 'server-rke2'
    clientId: vmIdentity.outputs.clientId
    resourceGroup: resGroupName
    subscriptionId: subscription().subscriptionId
    tenantId: subscription().tenantId
    region: location
    vnetName: suffix
    nsgName: suffix
    subnetName: 'default'
  }
}

module agentConfig 'config/agent.bicep' = {
  name: 'agentConfig'
  scope: resGroup
  params: {
    token: rke2Token
    serverHost: 'server-rke2'
  }
}

module server '../modules/vm/linux.bicep' = {
  scope: resGroup
  name: 'server'
  params: {
    location: location
    suffix: 'rke2'
    name: 'server'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: authType
    customData: serverConfig.outputs.customDataString
    size: serverVMSize
    userIdentityResourceId: vmIdentity.outputs.resourceId
  }
}

module agent '../modules/vm/linux.bicep' = [for i in range(0, agentCount): {
  scope: resGroup
  name: 'agent-${i}'
  params: {
    location: location
    suffix: 'rke2'
    name: 'agent${i}'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: 'sshPublicKey'
    customData: agentConfig.outputs.customDataString
    size: agentVMSize
  }
}]

module roles '../modules/identity/res-group-role.bicep' = {
  scope: resGroup
  // This is NOT actually dependant on the server but Azure AD is so awful and slow
  // we need a delay after creating the identity before assigning the role
  dependsOn: [ 
    server 
  ]
  name: 'roles'
  params: {
    suffix: suffix
    principalId: vmIdentity.outputs.principalId
    roleId: contributorRoleGUID
  }
}
