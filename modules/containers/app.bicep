// ============================================================================
// Module to deploy an Azure Container App
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Resource ID of Container App Environment used to host this app')
param environmentId string

@description('Image reference to run in the app pod')
param image string

@description('CPU to assign to the app, fractional values are allowed')
param cpu string = '0.25'

@description('Memory to assign to the app, in Kubernetes format')
param memory string = '.5Gi'

@description('Minimum number of replicas to run')
@minValue(1)
param replicasMin int = 1

@description('Maximum number of replicas to run, will scale no higher than this')
param replicasMax int = 1

@description('Port to expose from the app as HTTP or TCP ingress, if any. Unset to disable ingress.')
param ingressPort int = 0

@description('Path to use for HTTP probes, leave blank to disable')
param probePath string = ''

@description('Port to use for probes')
param probePort int = 0

@description('Expose ingress traffic to the internet')
param ingressExternal bool = false

@description('Array of environment vars to set in the app pod')
param envs array = []

@description('Configure secrets which can be referenced by the envs array')
param secrets array = []

@description('Enable scaling on concurrent HTTP requests')
@minValue(0)
param scaleHttpRequests int = 0

@description('Revision mode for updates to the app')
@allowed([ 'multiple', 'single' ])
param revisionMode string = 'single'

@description('Custom domain name, leave blank to disable')
param customDomainName string = ''

@description('Resource id of cert to use for custom domain, leave blank to disable')
param customDomainCertId string = ''

@description('Transport for the ingress, HTTP by default, can also be TCP')
@allowed([ 'http', 'tcp' ])
param ingressTransport string = 'http'

@description('Expose TCP over a different port, optional and only used if ingressTransport is TCP')
param ingressExposedTcpPort int = 0

// ===== Variables ============================================================

var ingressConfig = {
  external: ingressExternal
  targetPort: ingressPort
  exposedPort: ingressExposedTcpPort > 0 ? ingressExposedTcpPort : null
  customDomains: customDomainName != '' ? [
    {
      name: customDomainName
      certificateId: customDomainCertId
    }
  ] : []
  transport: ingressTransport
}

var probeConfig = probePath != '' ? [
  {
    type: 'readiness'
    httpGet: {
      path: probePath
      port: probePort
    }
    initialDelaySeconds: 10
    periodSeconds: 10
  }
] : []

var httpScaleRule = [
  {
    name: 'http-scale-rule'
    http: {
      metadata: {
        // It's weird this needs to be a string!?
        concurrentRequests: '${scaleHttpRequests}'
      }
    }
  }
]

// ===== Modules & Resources ==================================================

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  location: location
  name: name

  properties: {
    managedEnvironmentId: environmentId

    template: {
      containers: [
        {
          image: image
          name: name
          env: envs
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          probes: probeConfig
        }
      ]

      scale: {
        maxReplicas: replicasMax
        minReplicas: replicasMin

        rules: scaleHttpRequests > 0 ? httpScaleRule : []
      }
    }

    configuration: {
      secrets: secrets
      activeRevisionsMode: revisionMode
      ingress: ingressPort != 0 ? ingressConfig : null
    }
  }
}

output latestRevision string = containerApp.properties.latestRevisionName
output fqdn string = ingressPort != 0 ? containerApp.properties.configuration.ingress.fqdn : ''
output id string = containerApp.id
output customDomainVerificationId string = containerApp.properties.customDomainVerificationId
