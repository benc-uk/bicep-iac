param name string = resourceGroup().name
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'
param location string = resourceGroup().location

@description('SKU of the KeyVault')
@allowed([ 'premium', 'standard' ])
param sku string = 'standard'

@description('Array of OID GUIDs of indentities in Azure AD to be given access to secrets')
param objectIdsWithAccess array = []

@description('Array of objects with {name, value} pairs, to be added as secrets')
param secrets array = []

// ===== Variables ============================================================

// Append suffix, as these resources need to be uniquely named
var resourceName = '${name}${suffix}'

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

resource addSecrets 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = [for secret in secrets: {
  name: secret.name
  parent: keyVault
  properties: {
    value: secret.value
  }
}]

output resourceName string = resourceName
