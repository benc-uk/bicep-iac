// ============================================================================
// Deploy a container app with app container environment and log analytics
// Adds custom domain to the app, needs a cert generated and an existing DNS zone
// ============================================================================

// Generate a self-signed cert with the following commands
//
// openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
//   -keyout cert.key -out cert.pem -subj "/CN=$DOMAIN" \
//   -addext "subjectAltName=DNS:$DOMAIN"
// openssl pkcs12 -export -out cert.p12 -inkey cert.key -in cert.pem

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string = 'temp-demoapp'

@description('Azure region for all resources')
param location string = deployment().location

@description('Container image')
param image string = 'ghcr.io/benc-uk/nodejs-demoapp:latest'

@description('Port exposed by container')
param port int = 3000

// Parameters for your custom domain, and DNS Zone
param domainPrefix string = 'myapp'
param dnsZone string = 'benco.io'
param dnsZoneResGroup string = 'shared'

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

module logAnalytics '../../modules/monitoring/log-analytics.bicep' = {
  scope: resGroup
  name: 'monitoring'
}

module containerAppEnv '../../modules/containers/app-env.bicep' = {
  scope: resGroup
  name: 'containerAppEnv'
  params: {
    logAnalyticsName: logAnalytics.outputs.name
    logAnalyticsResGroup: resGroup.name
  }
}

module cert '../../modules/containers/certificate.bicep' = {
  scope: resGroup
  name: 'cert'

  params: {
    environmentName: containerAppEnv.outputs.name
    certContent: loadFileAsBase64('./cert.p12')
  }
}

module dnsCnameRecord '../../modules/dns/cname-record.bicep' = {
  scope: resourceGroup(dnsZoneResGroup)
  name: 'dns-cname'
  params: {
    recordName: domainPrefix
    zoneName: dnsZone
    cName: demoApp.outputs.fqdn
  }
}

module dnsTxtRecord '../../modules/dns/txt-record.bicep' = {
  scope: resourceGroup(dnsZoneResGroup)
  name: 'dns-txt'
  params: {
    recordName: 'asuid.${domainPrefix}'
    zoneName: dnsZone
    valueList: [
      demoApp.outputs.customDomainVerificationId
    ]
  }
}

module demoApp '../../modules/containers/app.bicep' = {
  scope: resGroup
  name: 'demoApp'
  params: {
    name: appName
    environmentId: containerAppEnv.outputs.id

    image: image

    ingressPort: port
    ingressExternal: true
    customDomainCertId: cert.outputs.id
    customDomainName: 'myapp.benco.io'

    scaleHttpRequests: 200

    probePath: '/'
    probePort: port

    secrets: [
      {
        // OPTIONAL - OpenWeather API key, enables the weather feature of the demo app
        // Get a free API key here https://home.openweathermap.org/users/sign_up
        name: 'weather-key-secret'
        value: '__CHANGE_ME__'
      }
    ]

    envs: [
      {
        name: 'WEATHER_API_KEY'
        secretref: 'weather-key-secret'
      }
    ]
  }
}

// ===== Outputs ==============================================================

output appURL string = 'https://${demoApp.outputs.fqdn}'
