// ============================================================================
// A module to deploy Azure Communcation Services Email
// ============================================================================

param name string = resourceGroup().name
param parentService string
param domainManagement string = 'AzureManaged'
param senderNames object = {
  DoNotReply: 'DoNotReply'
}

// ===== Variables ============================================================

var location = 'global'

// ===== Modules & Resources ==================================================

resource emailService 'Microsoft.Communication/emailServices@2021-10-01-preview' existing = {
  name: parentService
}

resource domain 'Microsoft.Communication/emailServices/domains@2021-10-01-preview' = {
  name: name
  location: location

  parent: emailService

  properties: {
    domainManagement: domainManagement
    validSenderUsernames: senderNames
  }
}

// ===== Outputs ==============================================================

output resourceId string = domain.id
output resourceName string = domain.name
output domain string = domain.properties.mailFromSenderDomain
