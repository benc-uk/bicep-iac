targetScope = 'subscription'

param autoProvisionEnabled string = 'on'

resource autoProvTest 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  // Default is hardcoded into Azure as the only accepted name
  name: 'default'
  properties: {
    autoProvision: autoProvisionEnabled
  }
}