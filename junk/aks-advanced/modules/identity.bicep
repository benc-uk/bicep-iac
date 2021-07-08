// This file is some trickery!
// Allow us to get hold of the user assigned identity created by AKS for the ACI vnodes addon
// this identity is automatically created, and we need to assign some roles to it
// https://docs.microsoft.com/en-us/azure/aks/virtual-nodes-cli#assign-permissions-to-the-virtual-network

param aksName string

resource vnodesIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: 'aciconnectorlinux-${aksName}'
}

output vnodesPrincipalId string = vnodesIdentity.properties.principalId