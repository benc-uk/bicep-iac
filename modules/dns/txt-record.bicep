// ========================================================================================================
// Create a DNS TXT record in an existing DNS zone, scope this to the resource group where the zone lives
// ========================================================================================================

@description('DNS zone name to create record in')
param zoneName string

@description('List of values to add to the TXT record')
param valueList array

@description('Name of the DNS record')
param recordName string

@description('Record time to live')
param ttl int = 3600

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: zoneName
}

resource aRecord 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: dnsZone

  name: recordName

  properties: {
    TTL: ttl
    TXTRecords: [for value in valueList: {
      value: [
        value
      ]
    }]
  }
}

// ===== Outputs ==============================================================

output id string = aRecord.id
