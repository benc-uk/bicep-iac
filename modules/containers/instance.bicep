// ============================================================================
// Deploy an Azure Container Instance
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Set a specific DNS suffix, otherwise a unique string will be picked')
param dnsSuffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('Image to deploy, should be full referenced if in a registry other than Dockerhub')
param image string

@description('Array of env vars to set, in the form of [{name: "VARNAME", value: "VARVALUE"}]')
param envVars array = []

@description('Port the container listens on, and will be exposed externally')
param port int = 80

@description('Number of CPUs to allocate to the container')
param cpuRequest string = '1'

@description('Amount of memory to allocate to the container, can be a decimal value')
param memoryRequest string = '0.5'

@description('Number of CPUs to allocate to the container')
@allowed([
  'Public'
  'Private'
])
param ipAddressType string = 'Public'

@description('Assign this instance to a VNet & subnet for private access, leave blank for public')
param subnetId string = ''

param registryCredUsername string = ''
@secure()
param registryCredPassword string = ''
param registryCredServer string = 'https://index.docker.io/v1/'

// ===== Variables ============================================================

var dnsNameLabel = replace('${name}${dnsSuffix}', '-', '')
var subnetConfig = subnetId != '' ? [
  {
    id: subnetId
  }
] : []

// ===== Modules & Resources ==================================================

resource containerInstance 'Microsoft.ContainerInstance/containerGroups@2021-10-01' = {
  name: name
  location: location

  properties: {
    osType: 'Linux'
    restartPolicy: 'OnFailure'
    sku: 'Standard'

    imageRegistryCredentials: registryCredUsername != '' ? [
      {
        server: registryCredServer
        username: registryCredUsername
        password: registryCredPassword
      }
    ] : []

    containers: [
      {
        name: '${name}-container'
        properties: {
          image: image
          environmentVariables: envVars

          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]

          resources: {
            requests: {
              cpu: json('${cpuRequest}')
              memoryInGB: json('${memoryRequest}')
            }
          }
        }
      }
    ]

    ipAddress: {
      type: ipAddressType
      dnsNameLabel: toLower(ipAddressType) == 'public' ? dnsNameLabel : null
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
    }

    subnetIds: subnetConfig
  }
}

// ===== Outputs ==============================================================

output resourceId string = containerInstance.id
output fqdn string = toLower(ipAddressType) == 'public' ? containerInstance.properties.ipAddress.fqdn : 'none'
output ipAddress string = containerInstance.properties.ipAddress.ip
output port int = containerInstance.properties.ipAddress.ports[0].port
