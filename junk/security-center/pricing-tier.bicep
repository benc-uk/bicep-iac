targetScope = 'subscription'

param defenderSetting string = 'Free'

resource appServiceDefender 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'AppServices'
  properties: {
    pricingTier: defenderSetting
  }
}

resource vmDefender 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: defenderSetting
  }
}

resource sqlDefender 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'SqlServers'
  properties: {
    pricingTier: defenderSetting
  }
}

resource storageDefender 'Microsoft.Security/pricings@2018-06-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: defenderSetting
  }
}