// ============================================================================
// Deploy a bare metal Kubernetes cluster using kubeadm
// ============================================================================

targetScope = 'subscription'

// Name used for resource group, and base name for most resources
param clusterName string
// Azure region for all resources
param location string = deployment().location

// Cluster configuration
param kubernetesVersion string = '1.21.3'
param controlPlaneCount int = 3
param workerCount int = 3
param workerVmSize string = 'Standard_B1ms'
param controlPlaneVmSize string = 'Standard_D4_v4' //'Standard_B4ms'

// Give access to this user / object id to the secrets in the key vault
// - e.g. keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
param keyVaultAccessObjectId string = ''

// Setting to false currently not supported due to lack of control plane egress
param publicCluster bool = true

// Deploy a SSH jumpbox, only do this for troubleshooting purposes
param deployJumpBox bool = true
// SSH key to connect to the jumpbox, if unset password auth will be used and clusterVMPassword
param jumpBoxPublicKey string = ''


// ===== Variables ============================================================

var bootStrapToken = 'abcdef.0123456789abcdef'
var certKey = '7cae2a25e84e01cb4a6583c7cfbb1df89b6f5c23974c2b9adc6a45ac1821cec3'
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
  }
}

module roles '../modules/identity/role-assign-sub.bicep' = {
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

output controlPlaneIp string = controlPlaneLoadBalancer.outputs.frontendIp
output controlPlaneFqdn string = publicCluster ? controlPlaneIp.outputs.fqdn : 'none'
output keyVaultName string = keyVault.outputs.resourceName
output jumpBoxIpAddress string = deployJumpBox ? jumpBox.outputs.publicIP : 'none'
