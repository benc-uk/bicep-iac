// ============================================================================
// A module to deploy managed application certificate
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

@description('Name Container App Environment')
param environmentName string

@description('Path to certificate file in PEM format')
param certContent string

resource managedEnv 'Microsoft.App/managedEnvironments@2022-03-01' existing = {
  name: environmentName
}

@description('Password of the cert file, if any')
param certPassword string = ''

resource cert 'Microsoft.App/managedEnvironments/certificates@2022-03-01' = {
  name: name
  location: location

  parent: managedEnv

  properties: {
    password: certPassword

    // Why not load from file? Due to ARM limitations we'd need to hardcode file path 😣
    value: any(certContent)
  }
}

output id string = cert.id
