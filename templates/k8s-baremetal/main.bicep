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
param controlPlaneVmSize string = 'Standard_B2s'

// Give access to this user / object id to the secrets in the key vault
// - e.g. keyVaultAccessObjectId="$(az ad signed-in-user show --query 'objectId' -o tsv)"
@description('Assign this Azure AD object id access to the KeyVault')
param keyVaultAccessObjectId string = ''

// SSH jumpbox settings - only enable this for troubleshooting purposes
@description('Enable to deploy a jump box VM for SSH access to nodes')
param deployJumpBox bool = false
@description('SSH key to connect to the jumpbox, if unset password auth will be used, with the password in the KeyVault')
param jumpBoxPublicKey string = ''

// Switch between public/private cluster, which changes type of load balancer used and other things
@description('Switch between public/private clusters, changes type of load balancer')
param publicCluster bool = true

// ===== Variables ============================================================

// Generate bootstrap token and also a 32 byte cert key from random hex strings
var hexString1 = replace(guid(location), '-', '')
var hexString2 = replace(guid(location, clusterName), '-', '')
var bootStrapToken = '${substring(hexString1, 6, 6)}.${substring(hexString2, 0, 16)}'
var certKey = hexString1
var clusterVMPassword = '${uniqueString(clusterName)}!P${uniqueString(subscription().tenantId)}Z'
var vmUserName = 'kube'

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: clusterName
  location: location
}

//
// NSG to allow kube-api (port 6443) and SSH access, SSH is behind a jumpbox
//
module subnetNsg '../../modules/network/nsg.bicep' = {
  scope: resGroup
  name: 'subnetNsg'
  params: {
    openPorts: [
      '22'
      '6443'
    ]
  }
}

//
// VNet and default subnet
//
module network '../../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    nsgId: subnetNsg.outputs.nsgId
  }
}

//
// User managed identity to assign to the cluster for both KeyVault access and for the kube cloud provider
//
module clusterIdentity '../../modules/identity/user-managed.bicep' = {
  scope: resGroup
  name: 'clusterIdentity'
}

//
// Use a seperate subnet for the control plane, only so we have a more stable IP range to give to HAProxy
//
module controlPlaneSubnet '../../modules/network/subnet.bicep' = {
  scope: resGroup
  name: 'controlPlaneSubnet'
  params: {
    name: 'control-plane'
    vnetName: network.outputs.vnetName
    addressPrefix: '10.200.0.0/24'
    nsgId: subnetNsg.outputs.nsgId
  }
}

//
// Key Vault used to hold secrets and synchronize cluster creation
//
module keyVault '../../modules/misc/keyvault.bicep' = {
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

//
// Build the cloud-init required for the control-plane nodes see the control-plane.bicep sub-module
//
module controlPlaneCloudInit './cloudinit/control-plane.bicep' = {
  scope: resGroup
  name: 'controlPlaneCloudInit'
  params: {
    kubernetesVersion: kubernetesVersion
    // IP of the control plane load balancer, depends on if this is a public cluster or not
    controlPlaneExternalHost: publicCluster ? controlPlaneLoadBalancer.outputs.frontendIp : haproxyLoadBalancer.outputs.privateIp
    bootStrapToken: bootStrapToken
    certKey: certKey
    keyVaultName: keyVault.outputs.resourceName
    clientId: clusterIdentity.outputs.clientId
  }
}

//
// Build the cloud-init required for the worker nodes see the workers.bicep sub-module
//
module workerCloudInit './cloudinit/workers.bicep' = {
  scope: resGroup
  name: 'workerCloudInit'
  params: {
    kubernetesVersion: kubernetesVersion
    // IP of the control plane load balancer, depends on if this is a public cluster or not
    controlPlaneExternalHost: publicCluster ? controlPlaneLoadBalancer.outputs.frontendIp : haproxyLoadBalancer.outputs.privateIp
    bootStrapToken: bootStrapToken
    clientId: clusterIdentity.outputs.clientId
  }
}

//
// VM scale set to run the control plane nodes
//
module controlPlane '../../modules/compute/linux-vmss.bicep' = {
  scope: resGroup
  name: 'controlPlane'

  dependsOn: [
    keyVault
  ]

  params: {
    name: 'ctrl-plane'
    subnetId: controlPlaneSubnet.outputs.subnetId
    adminPasswordOrKey: clusterVMPassword
    authenticationType: 'password'
    cloudInit: controlPlaneCloudInit.outputs.cloudInit
    size: controlPlaneVmSize
    // Place this scale set into the backend pool of the Azure LB when a public cluster
    loadBalancerBackendPoolId: publicCluster ? controlPlaneLoadBalancer.outputs.backendPoolId : ''
    userIdentityResourceId: clusterIdentity.outputs.resourceId
    instanceCount: controlPlaneCount
    adminUser: vmUserName
  }
}

//
// VM scale set to run the worker nodes
//
module workers '../../modules/compute/linux-vmss.bicep' = {
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
    adminUser: vmUserName
  }
}

//
// Assign the user identity the Contributor role at the resource group level
// 
module roles '../../modules/identity/role-assign-rg.bicep' = {
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

//
// Configure the VM jumpbox if it's a private cluster or deployJumpBox is set
//
module jumpBoxCloudInit './cloudinit/jumpbox.bicep' = if (deployJumpBox || !publicCluster) {
  scope: resGroup
  name: 'jumpBoxCloudInit'
  params: {
    keyVaultName: keyVault.outputs.resourceName
  }
}

//
// Deploy a SSH jumpbox VM if it's a private cluster or deployJumpBox is set
//
module jumpBox '../../modules/compute/linux-vm.bicep' = if (deployJumpBox || !publicCluster) {
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
    cloudInit: (deployJumpBox || !publicCluster) ? jumpBoxCloudInit.outputs.cloudInit : ''
    userIdentityResourceId: clusterIdentity.outputs.resourceId
  }
}

//
//  A public IP to access the control plane (kube api-server) if cluster is public
//
module controlPlanePublicIp '../../modules/network/public-ip.bicep' = if (publicCluster) {
  scope: resGroup
  name: 'controlPlanePublicIp'
}

//
// Place control plane VMSS behind this Azure LB if cluster is public
//
module controlPlaneLoadBalancer '../../modules/network/load-balancer.bicep' = if (publicCluster) {
  scope: resGroup
  name: 'controlPlaneLoadBalancer'
  params: {
    port: 6443
    publicIpId: publicCluster ? controlPlanePublicIp.outputs.resourceId : ''
    subnetId: publicCluster ? '' : network.outputs.subnetId
  }
}

//
// Configure a VM to be a load balancer running HAProxy if cluster is private
//
module haproxyCloudInit './cloudinit/load-balancer.bicep' = if (!publicCluster) {
  scope: resGroup
  name: 'privateLBInit'
}

//
// Deploy VM as a load balancer running HAProxy if cluster is private
//
module haproxyLoadBalancer '../../modules/compute/linux-vm.bicep' = if (!publicCluster) {
  scope: resGroup
  name: 'haproxyLoadBalancer'

  params: {
    name: 'load-balancer'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: clusterVMPassword
    publicIp: false
    authenticationType: 'password'
    size: 'Standard_B1ms'
    adminUser: 'kube'
    cloudInit: publicCluster ? '' : haproxyCloudInit.outputs.cloudInit
    userIdentityResourceId: clusterIdentity.outputs.resourceId
  }
}

// ===== Outputs ==============================================================

output controlPlaneIp string = publicCluster ? controlPlaneLoadBalancer.outputs.frontendIp : haproxyLoadBalancer.outputs.privateIp
output controlPlaneFqdn string = publicCluster ? controlPlanePublicIp.outputs.fqdn : 'none'
output keyVaultName string = keyVault.outputs.resourceName
output jumpBoxIpAddress string = (deployJumpBox || !publicCluster) ? jumpBox.outputs.publicIP : 'none'
output publicCluster bool = publicCluster
