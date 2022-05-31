// ========================================================================================================
// Create a DNS A record in an existing DNS zone, scope this to the resource group where the zone lives
// ========================================================================================================

@description('DNS zone name to create record in')
param zoneName string

@description('List of IP addresses to add to the A record')
param ipAddressList array

@description('Name of the DNS record')
param recordName string

@description('Record time to live')
param ttl int = 3600

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: zoneName
}

resource aRecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dnsZone

  name: recordName

  properties: {
    TTL: ttl
    ARecords: [for ip in ipAddressList: {
      ipv4Address: ip
    }]
  }
}

// ===== Outputs ==============================================================

output id string = aRecord.id
