// ============================================================================
// A module to deploy Azure Service Bus Namespace
// ============================================================================

param name string = resourceGroup().name
param location string = resourceGroup().location

// Remove for resources that DONT need unique names
param suffix string = '-${substring(uniqueString(resourceGroup().name), 0, 5)}'

@description('Pick your storage SKU')
@allowed([ 'Basic', 'Standard', 'Premium' ])
param sku string = 'Basic'

@description('Capacity of the SKU')
param capacity int = 1

@description('Create a topic, leave blank to not create a topic')
param topicName string = ''

// ===== Variables ============================================================

var resourceName = replace('${name}${suffix}', '-', '')

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: resourceName
  location: location
  sku: {
    name: sku
    tier: sku
    capacity: capacity
  }
}

// Topic resource is optional
resource topic 'Microsoft.ServiceBus/namespaces/topics@2021-11-01' = if (topicName != '') {
  name: topicName
  parent: serviceBusNamespace
}

output resourceId string = serviceBusNamespace.id
output name string = serviceBusNamespace.name

var serviceBusEndpoint = '${serviceBusNamespace.id}/AuthorizationRules/RootManageSharedAccessKey'
output connectionString string = listKeys(serviceBusEndpoint, '2021-11-01').primaryConnectionString
