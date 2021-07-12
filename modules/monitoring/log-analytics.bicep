param suffix string
param prefix string = 'logs-'
param location string 
param sku string = 'Free'

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: '${prefix}${suffix}'
  properties:{
    sku:{
      name: sku
    }
  }
}

output logWorkspaceId string = logWorkspace.id
