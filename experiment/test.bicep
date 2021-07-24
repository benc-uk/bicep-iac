targetScope = 'subscription'

param name string
param location string = deployment().location

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: name
  location: location  
}

module subnetNsg '../modules/network/nsg.bicep' = {
  scope: resGroup
  name: 'subnetNsg'
  params: {
    openPorts: [ 
      '22'
      '8080'
    ]
  }
}

module network '../modules/network/network.bicep' = {
  scope: resGroup
  name: 'network'
  params: {
    nsgId: subnetNsg.outputs.nsgId
    // DISABLED DOESN'T WORK 
    //natGatewayId: natGateway.outputs.resourceId
  }
}

// module loadBalancer '../modules/network/load-balancer.bicep' = {
//   scope: resGroup
//   name: 'loadBalancer'  
//   params: {
//     port: 8080
//     //publicIpId: publicCluster ? controlPlaneIp.outputs.resourceId : ''
//     subnetId: network.outputs.subnetId
//     // DISABLED DOESN'T WORK - One part of the Azure internal load balancer hairpinning fix
//     enableFloatingIP: true
//   }
// }

module vm1 '../modules/compute/linux-vm.bicep' = {
  scope: resGroup
  name: 'vm1'

  params: {
    name: 'vm1'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1iR5NeXJd/+zpVHtgj//PY1znXgnMOhWYQOkxQj+4WsR18ptqT2gkS0wZOPVg0UEycz0DIssznzSK4QyJZtAVbMZasu21G+XdAnfdFqzAqr4QFEyGqZViLIE+yUHvfOcwrEtEenCCWHFSbmuUSsORyyol81P4rms9MdXoBNj4DaDOKa10fPziWCjC3Cprs7VaHcETIOgf//FN5t5qMrzwmW4cCpql3vzyr0FugdSOwv3yaQiylw1ayi6czJyRoIhPgpohSG5WigvEC5gFjhO43MFtD6tMu3EGzqzs7YyiFhRQI44dvHDCLHP/fJRN/w4IgQHH3jMlYwfHafed4JIVQ== rsa-key-20160706'
    publicIp: true
    authenticationType: 'publicKey'
    size: 'Standard_D2_v4'
    adminUser: 'kube'
    //loadBalancerBackendPoolId: loadBalancer.outputs.backendPoolId
  }
}

module vm2 '../modules/compute/linux-vm.bicep' = {
  scope: resGroup
  name: 'vm2'

  params: {
    name: 'vm2'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1iR5NeXJd/+zpVHtgj//PY1znXgnMOhWYQOkxQj+4WsR18ptqT2gkS0wZOPVg0UEycz0DIssznzSK4QyJZtAVbMZasu21G+XdAnfdFqzAqr4QFEyGqZViLIE+yUHvfOcwrEtEenCCWHFSbmuUSsORyyol81P4rms9MdXoBNj4DaDOKa10fPziWCjC3Cprs7VaHcETIOgf//FN5t5qMrzwmW4cCpql3vzyr0FugdSOwv3yaQiylw1ayi6czJyRoIhPgpohSG5WigvEC5gFjhO43MFtD6tMu3EGzqzs7YyiFhRQI44dvHDCLHP/fJRN/w4IgQHH3jMlYwfHafed4JIVQ== rsa-key-20160706'
    publicIp: true
    authenticationType: 'publicKey'
    size: 'Standard_D2_v4'
    adminUser: 'kube'
    //loadBalancerBackendPoolId: loadBalancer.outputs.backendPoolId
  }
}

module lb '../modules/compute/linux-vm.bicep' = {
  scope: resGroup
  name: 'lb'

  params: {
    name: 'lb'
    subnetId: network.outputs.subnetId
    adminPasswordOrKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEA1iR5NeXJd/+zpVHtgj//PY1znXgnMOhWYQOkxQj+4WsR18ptqT2gkS0wZOPVg0UEycz0DIssznzSK4QyJZtAVbMZasu21G+XdAnfdFqzAqr4QFEyGqZViLIE+yUHvfOcwrEtEenCCWHFSbmuUSsORyyol81P4rms9MdXoBNj4DaDOKa10fPziWCjC3Cprs7VaHcETIOgf//FN5t5qMrzwmW4cCpql3vzyr0FugdSOwv3yaQiylw1ayi6czJyRoIhPgpohSG5WigvEC5gFjhO43MFtD6tMu3EGzqzs7YyiFhRQI44dvHDCLHP/fJRN/w4IgQHH3jMlYwfHafed4JIVQ== rsa-key-20160706'
    publicIp: true
    authenticationType: 'publicKey'
    size: 'Standard_D2_v4'
    adminUser: 'kube'
    //loadBalancerBackendPoolId: loadBalancer.outputs.backendPoolId
  }
}

// module natGateway '../modules/network/nat-gateway.bicep' = {
//   scope: resGroup
//   name: 'natGateway'
// }
