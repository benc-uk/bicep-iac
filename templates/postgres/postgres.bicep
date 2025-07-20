// ============================================================================
// Testing Bicep module for deploying a PostgreSQL database with Cosmos DB API
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param appName string

@description('Azure region for all resources')
param location string = deployment().location

// ===== Variables ============================================================

// ===== Modules & Resources ==================================================

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

module database '../../modules/database/postgres-cosmosdb.bicep' = {
  scope: resGroup

  params: {
    name: appName
    location: location
    adminPassword: 'P@ssw0rd123!'
    databaseName: 'frankfurter'
  }
}

// ===== Outputs ==============================================================

output connectionString string = database.outputs.dsn
