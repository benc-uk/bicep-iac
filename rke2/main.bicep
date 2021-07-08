targetScope = 'subscription'

param resGroupName string = 'rke2-test08'
param location string = 'uksouth'
param suffix string = 'rke2' //-${substring(uniqueString(resGroupName), 0, 4)}'

param authString string = 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1iR5NeXJd/+zpVHtgj//PY1znXgnMOhWYQOkxQj+4WsR18ptqT2gkS0wZOPVg0UEycz0DIssznzSK4QyJZtAVbMZasu21G+XdAnfdFqzAqr4QFEyGqZViLIE+yUHvfOcwrEtEenCCWHFSbmuUSsORyyol81P4rms9MdXoBNj4DaDOKa10fPziWCjC3Cprs7VaHcETIOgf//FN5t5qMrzwmW4cCpql3vzyr0FugdSOwv3yaQiylw1ayi6czJyRoIhPgpohSG5WigvEC5gFjhO43MFtD6tMu3EGzqzs7YyiFhRQI44dvHDCLHP/fJRN/w4IgQHH3jMlYwfHafed4JIVQ== rsa-key-20160706'
param agentCount int = 1
param serverVMSize string = 'Standard_D16s_v4'
param agentVMSize string = 'Standard_D16s_v4'
param rke2Token string = newGuid()

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
    authenticationType: 'sshPublicKey'
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

module roles '../modules/identity/roles.bicep' = {
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
