// ============================================================================
// Deploy Azure Communication Services with email domain
// ============================================================================

targetScope = 'subscription'

@description('Name used for resource group, and default base name for all resources')
param baseName string = 'temp-email-3'

@description('Azure region for all resources')
param location string = deployment().location

/*
az rest --method patch --url \
'/subscriptions/52512f28-c6ed-403e-9569-82a9fb9fec91/resourceGroups/temp-email-3/providers/Microsoft.Communication/communicationServices/temp-email-3-3bxxl?api-version=2021-10-01-preview' \
--body '{ "properties": { "linkedDomains": [ "/subscriptions/52512f28-c6ed-403e-9569-82a9fb9fec91/resourceGroups/temp-email-3/providers/Microsoft.Communication/emailServices/temp-email-3-3bxxl/domains/AzureManagedDomain" ] } }'
*/

resource resGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: baseName
  location: location
}

module emailService '../../modules/communication/email.bicep' = {
  name: 'emailService'
  scope: resGroup
  params: {
    name: baseName
  }
}

module domain '../../modules/communication/domain.bicep' = {
  name: 'domain'
  scope: resGroup
  dependsOn: [ emailService ]
  params: {
    // NOTE! The name *must* be this, otherwise you get an error
    name: 'AzureManagedDomain'
    parentService: emailService.outputs.resourceName
  }
}

module acs '../../modules/communication/service.bicep' = {
  name: 'acs'
  scope: resGroup
  params: {
    name: baseName
  }
}

output domainResourceId string = domain.outputs.resourceId
output domainName string = domain.outputs.domain
output acsResourceId string = acs.outputs.resourceId
