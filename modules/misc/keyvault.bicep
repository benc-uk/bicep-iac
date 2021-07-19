param name string = resourceGroup().name
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param location string = resourceGroup().location

param sku string = 'standard'
param objectIdsWithAccess array
param secrets array

// ===== Variables ============================================================

// Append suffix
var resourceName = '${name}${suffix}'
// HACK: To workaround bug Bicep https://github.com/Azure/bicep/issues/1754
var secretsArray = concat(secrets, [
  {
    name: 'ignore'
    value: guid(resourceName)
  }
])

// ===== Modules & Resources ==================================================

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: resourceName
  location: location 
  properties: {
    tenantId: subscription().tenantId

    sku: {
      family: 'A'
      name: sku
    }

    accessPolicies: [for oid in objectIdsWithAccess: {
      tenantId: subscription().tenantId
      objectId: oid
      permissions: {
        secrets: [
          'all'
        ]
      }
    }]
  }
}

resource addSecrets 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in secretsArray: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]

output resourceName string = resourceName
