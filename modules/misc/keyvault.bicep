param suffix string
param prefix string = 'kv-'
param location string 

param sku string = 'standard'
param objectIdsWithAccess array

// ===== Variables ============================================================

var name = '${prefix}${suffix}'

// ===== Modules & Resources ==================================================

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
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
