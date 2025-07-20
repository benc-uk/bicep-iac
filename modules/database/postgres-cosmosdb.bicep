// ============================================================================
// A module to deploy PostgreSQL with Cosmos DB
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// Remove for resources that DONT need unique names
//param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('PostgreSQL version to deploy')
@allowed([
  '14'
  '15'
  '16'
])
param version string = '16'

@description('Password for the PostgreSQL administrator account')
@secure()
param adminPassword string

@description('Database name to create')
param databaseName string = 'exampledb'

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource postgres 'Microsoft.DBforPostgreSQL/serverGroupsv2@2023-03-02-preview' = {
  name: name
  location: location

  properties: {
    postgresqlVersion: version
    enableHa: false
    enableGeoBackup: false
    databaseName: databaseName

    administratorLoginPassword: adminPassword

    coordinatorServerEdition: 'BurstableMemoryOptimized'
    coordinatorStorageQuotaInMb: 32768
    coordinatorVCores: 1
    coordinatorEnablePublicIpAccess: true

    nodeCount: 0 // BurstableMemoryOptimized requires 0 nodes
    nodeServerEdition: 'MemoryOptimized'
    nodeVCores: 4
  }
}

// Firewall rule to allow access from Azure services
resource postgresAllowAzure 'Microsoft.DBforPostgreSQL/serverGroupsv2/firewallRules@2023-03-02-preview' = {
  parent: postgres
  name: 'allow-azure-services'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// ===== Outputs ==============================================================

output resourceId string = postgres.id
output host string = postgres.properties.serverNames[0].fullyQualifiedDomainName
output dsn string = 'host=${postgres.properties.serverNames[0].fullyQualifiedDomainName} port=5432 dbname=${databaseName} user=citus sslmode=require'
