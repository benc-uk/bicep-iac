// ============================================================================
// Deploy a bare metal Kubernetes cluster using kubeadm
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and base name for most resources')
param clusterName string
@description('Azure region for all resources')
param location string = deployment().location

// Cluster configuration
@description('Version of Kubernetes to deploy x.yy.z')
param kubernetesVersion string = '1.21.3'
@description('Number of nodes in the control plane, should be a odd number')
param controlPlaneCount int = 1
@description('Number of worker/agent nodes')
param workerCount int = 3
@description('Azure VM instance size for the worker nodes')
param workerVmSize string = 'Standard_B2s'
@description('Azure VM instance size for the control plane nodes')
param controlPlaneVmSize string = 'Standard_B8ms' //'Standard_B4ms'

// Give access to this user / object id to the secrets in the key vault
// - e.g. keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
@description('Assign this Azure AD object id access to the KeyVault')
param keyVaultAccessObjectId string = ''

// Setting to false currently not supported due to lack of control plane egress
@description('Make the cluster API public, note it is still secured')
param publicCluster bool = true

// SSH jumpbox settings - only enable this for troubleshooting purposes
@description('If enabled a jump box VM will be deployed for SSH access to nodes')
param deployJumpBox bool = true
@description('SSH key to connect to the jumpbox, if unset password auth will be used, with the password in the KeyVault')
param jumpBoxPublicKey string = ''

// ===== Variables ============================================================

// Generate bootstrap token and also a 32 byte cert key from random hex strings
var hexString1 = replace(guid(location), '-', '')
var hexString2 = replace(guid(location, clusterName), '-', '')
var bootStrapToken = '${substring(hexString1, 6, 6)}.${substring(hexString2, 0, 16)}'
var certKey = hexString1
var clusterVMPassword = '${uniqueString(clusterName)}!P${uniqueString(subscription().tenantId)}Z'

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: clusterName
  location: location  
}

module subnetNsg '../modules/network/nsg.bicep' = {
  scope: resGroup
  name: 'subnetNsg'
  params: {
    openPorts: [ 
      '22'
      '6443'
    ]
  }
}

module network '../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    nsgId: subnetNsg.outputs.nsgId
    //natGatewayId: natGateway.outputs.resourceId
  }
}

module clusterIdentity '../modules/identity/user-managed.bicep' = {
  scope: resGroup
  name: 'clusterIdentity'
}

module controlPlaneIp '../modules/network/public-ip.bicep' = if(publicCluster) {
  scope: resGroup
  name: 'controlPlaneIp'
}

module controlPlaneLoadBalancer '../modules/network/load-balancer.bicep' = {
  scope: resGroup
  name: 'controlPlaneLoadBalancer'  
  params: {
    port: 6443
    publicIpId: publicCluster ? controlPlaneIp.outputs.resourceId : ''
    subnetId: publicCluster ? '' : network.outputs.subnetId
  }
}

module keyVault '../modules/misc/keyvault.bicep' = {
  scope: resGroup
  name: 'keyVault'  
  params: {
    // At a minimum add our clusterIdentity, but also any extra keyVaultAccessObjectId if not blank
    objectIdsWithAccess: keyVaultAccessObjectId != '' ? [
      clusterIdentity.outputs.principalId
      keyVaultAccessObjectId
    ] : [
      clusterIdentity.outputs.principalId
    ]
    secrets: [
      {
        name: 'nodePassword'
        value: clusterVMPassword
      }
    ]
  }
}

module controlPlaneCloudInit './cloudinit/control-plane.bicep' = {
  scope: resGroup
  name: 'controlPlaneCloudInit'  
  params: {
    kubernetesVersion: kubernetesVersion
    controlPlaneExternalHost: controlPlaneLoadBalancer.outputs.frontendIp
    bootStrapToken: bootStrapToken
    certKey: certKey
    keyVaultName: keyVault.outputs.resourceName
    clientId: clusterIdentity.outputs.clientId
  }
}

module workerCloudInit './cloudinit/workers.bicep' = {
  scope: resGroup
  name: 'workerCloudInit'
  params: {
    kubernetesVersion: kubernetesVersion
    controlPlaneExternalHost: controlPlaneLoadBalancer.outputs.frontendIp
    bootStrapToken: bootStrapToken
    clientId: clusterIdentity.outputs.clientId
  }
}

module controlPlane '../modules/compute/linux-vmss.bicep' = {
  scope: resGroup
  name: 'controlPlane'

  dependsOn: [
    keyVault
  ]

  params: {
    name: 'ctrl-plane'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: clusterVMPassword
    authenticationType: 'password'
    cloudInit: controlPlaneCloudInit.outputs.cloudInit
    size: controlPlaneVmSize
    loadBalancerBackendPoolId: controlPlaneLoadBalancer.outputs.backendPoolId
    userIdentityResourceId: clusterIdentity.outputs.resourceId
    instanceCount: controlPlaneCount
    adminUser: 'kube'
  }
}

module workers '../modules/compute/linux-vmss.bicep' = {
  scope: resGroup
  name: 'workers'

  params: {
    name: 'worker'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: clusterVMPassword
    authenticationType: 'password'
    cloudInit: workerCloudInit.outputs.cloudInit
    size: workerVmSize
    userIdentityResourceId: clusterIdentity.outputs.resourceId
    instanceCount: workerCount
    adminUser: 'kube'
  }
}

module jumpBox '../modules/compute/linux-vm.bicep' = if(deployJumpBox) {
  scope: resGroup
  name: 'jumpBox'

  params: {
    name: 'jumpbox'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: jumpBoxPublicKey != '' ? jumpBoxPublicKey : clusterVMPassword
    publicIp: true
    authenticationType: jumpBoxPublicKey != '' ? 'publicKey' : 'password'
    size: 'Standard_B1ms'
    adminUser: 'kube'
  }
}

module roles '../modules/identity/role-assign-rg.bicep' = {
  scope: resGroup
  // This is NOT actually dependant on these but Azure AD is so awful and slow
  // we need a delay after creating the identity before assigning the role
  dependsOn: [ 
    controlPlane
    clusterIdentity
  ]
  name: 'roles'
  params: {
    principalId: clusterIdentity.outputs.principalId
    // Contributor role
    roleId: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  }
}

// REMOVED need to fix this
// https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-troubleshoot-backend-traffic#cause-4-accessing-the-internal-load-balancer-frontend-from-the-participating-load-balancer-backend-pool-vm
// module natGateway '../modules/network/nat-gateway.bicep' = {
//   scope: resGroup
//   name: 'natGateway'
// }

output controlPlaneIp string = controlPlaneLoadBalancer.outputs.frontendIp
output controlPlaneFqdn string = publicCluster ? controlPlaneIp.outputs.fqdn : 'none'
output keyVaultName string = keyVault.outputs.resourceName
output jumpBoxIpAddress string = deployJumpBox ? jumpBox.outputs.publicIP : 'none'
