param suffix string
param location string 

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  location: location
  name: 'logs-${suffix}'
  properties:{
    sku:{
      name: 'Free'
    }
  }
}

output logWorkspaceId string = logWorkspace.id