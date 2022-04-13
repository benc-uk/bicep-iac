// ============================================================================
// Deploy an Azure Container Instance
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

param image string
param envVars array = []
param port int = 80
param cpuRequest int = 1
param memoryRequest string = '0.5'
param ipAddressType string = 'public'
param subnetId string = ''

// ===== Variables ============================================================

var dnsNameLabel = replace('${name}${suffix}', '-', '')
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

    containers: [
      {
        name: '${name}-container'
        properties: {
          image: image
          environmentVariables: [for envVar in envVars: {
            name: envVar.name
            value: envVar.value
          }]

          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]

          resources: {
            requests: {
              cpu: cpuRequest
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
