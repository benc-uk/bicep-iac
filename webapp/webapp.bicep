param location string = resourceGroup().location

param planName string = 'app-plan-linux'
param planTier string = 'P1v2'

param webappName string = 'nodejs-demoapp'
param webappImage string = 'ghcr.io/benc-uk/nodejs-demoapp:latest'
param appSettings array = []

param registryUrl string = 'https://ghcr.io'
param registryUsername string = ''
param registryPassword string = ''

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: planName
  location: location
  sku: {
    name: planTier
  }
  properties: {
    reserved: true
  }
}

//var appSettingsSet = concat(appSettings)

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: webappName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: appSettings
      // [
      //   // Only required for a non-public container registry
      //   {
      //     name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
      //     value: registryPassword
      //   }
      //   {
      //     name: 'DOCKER_REGISTRY_SERVER_URL'
      //     value: registryUrl
      //   }
      //   {
      //     name: 'DOCKER_REGISTRY_SERVER_USERNAME'
      //     value: registryUsername
      //   }       
      // ]
      linuxFxVersion: 'DOCKER|${webappImage}'
    }
  }
}