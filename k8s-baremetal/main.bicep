// ============================================================================
// Deploy a bare metal Kubernetes cluster using kubeadm
// ============================================================================

targetScope = 'subscription'

// Resource group which will be created and contain everything
param resGroupName string
// Azure region for all resources
param location string
// Password or SSH key to connect to the servers & agent node VMs
param authString string
// Use SSH key or password
param authType string = 'publicKey'

param prefix string = ''
param suffix string = 'k8s'

param kubernetesVersion string = '1.21.3'
param controlPlaneCount int = 2
param workerCount int = 2
param workerVmSize string = 'Standard_D4_v4'
param controlPlaneVmSize string = 'Standard_D4_v4'

param keyVaultAccessObjectId string = ''

// ===== Variables ============================================================

var bootStrapToken = 'abcdef.0123456789abcdef'
var certKey = '7cae2a25e84e01cb4a6583c7cfbb1df89b6f5c23974c2b9adc6a45ac1821cec3'
var keyVaultSuffix = '${suffix}-${substring(uniqueString(resGroupName), 0, 5)}'

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resGroupName
  location: location  
}

module subnetNsg '../modules/network/nsg.bicep' = {
  scope: resGroup
  name: 'subnetNsg'
  params: {
    location: location
    suffix: suffix
    prefix: ''
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
    location: location
    suffix: suffix
    prefix: prefix
    nsgId: subnetNsg.outputs.nsgId
  }
}

module clusterIdentity '../modules/identity/user-managed.bicep' = {
  scope: resGroup
  name: 'clusterIdentity'
  params: {
    location: location
    suffix: suffix
    prefix: prefix
  }
}

module controlPlaneIp '../modules/network/public-ip.bicep' = {
  scope: resGroup
  name: 'cpPublicIp'  
  params: {
    location: location
    suffix: suffix
    prefix: prefix
  }
}

module controlPlaneLB '../modules/network/load-balancer.bicep' = {
  scope: resGroup
  name: 'cpLoadBalancer'  
  params: {
    location: location
    suffix: suffix
    prefix: prefix
    port: 6443
    publicIpId: controlPlaneIp.outputs.resourceId
  }
}

module keyVault '../modules/misc/keyvault.bicep' = {
  scope: resGroup
  name: 'keyVault'  
  params: {
    location: location
    suffix: keyVaultSuffix
    prefix: prefix
    objectIdsWithAccess: keyVaultAccessObjectId != '' ? [
      clusterIdentity.outputs.principalId
      keyVaultAccessObjectId
    ] : [
      clusterIdentity.outputs.principalId
    ]
  }
}

module controlPlaneCloudInit './cloudinit/control-plane.bicep' = {
  scope: resGroup
  name: 'cpCloudInit'  
  params: {
    kubernetesVersion: kubernetesVersion
    controlPlaneExternalHost: controlPlaneIp.outputs.ipAddress
    bootStrapToken: bootStrapToken
    certKey: certKey
    keyVaultName: '${prefix}${keyVaultSuffix}'
  }
}

module workerCloudInit './cloudinit/workers.bicep' = {
  scope: resGroup
  name: 'workerCloudInit'
  params: {
    kubernetesVersion: kubernetesVersion
    controlPlaneExternalHost: controlPlaneIp.outputs.ipAddress
    bootStrapToken: bootStrapToken
  }
}

module controlPlane '../modules/vm/linux.bicep' = [for i in range(0, controlPlaneCount): {
  scope: resGroup
  name: 'controlPlane${i}'
  
  dependsOn: [
    keyVault
  ]

  params: {
    location: location
    suffix: ''
    prefix: 'cp${i}'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: authType
    cloudInit: controlPlaneCloudInit.outputs.cloudInit
    size: controlPlaneVmSize
    publicIp: false
    loadBalancerBackendPoolId: controlPlaneLB.outputs.backendPoolId
    userIdentityResourceId: clusterIdentity.outputs.resourceId
  }
}]

module workers '../modules/vm/linux.bicep' = [for i in range(0, workerCount): {
  scope: resGroup
  name: 'worker${i}'
  params: {
    location: location
    suffix: ''
    prefix: 'worker${i}'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: authString
    authenticationType: authType
    cloudInit: workerCloudInit.outputs.cloudInit
    size: workerVmSize
    publicIp: true
    userIdentityResourceId: clusterIdentity.outputs.resourceId
  }
}]

output controlPlaneIp string = controlPlaneIp.outputs.ipAddress
output controlPlaneFqdn string = controlPlaneIp.outputs.fqdn
output keyVaultName string = '${prefix}${keyVaultSuffix}'
