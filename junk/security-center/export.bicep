param resPrefix string = 'examplebc'

resource workspaceTest 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: '${resPrefix}workspace'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource exportTest 'Microsoft.Security/automations@2019-01-01-preview' = {
  name: 'toLogAnalytics'
  location: resourceGroup().location
  properties: {
    description: 'example'
    isEnabled: true
    scopes: [
      {
        description: 'test'
        scopePath: subscription().id
      }
    ]
    actions: [
      {
        workspaceResourceId: workspaceTest.id
        actionType: 'Workspace'
      }
    ]
    sources: [
      {
        eventSource: 'Assessments'
        ruleSets: []
      }
    ]
  }
}