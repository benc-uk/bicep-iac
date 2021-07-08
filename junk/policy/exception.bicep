targetScope = 'subscription'

resource exemption 'Microsoft.Authorization/policyExemptions@2020-07-01-preview' = {
  name: 'exampleException'
  properties: {
    description: 'Demo of exemptions'
    exemptionCategory: 'Waiver'
    policyAssignmentId:'${subscription().id}/providers/Microsoft.Authorization/policyAssignments/SecurityCenterBuiltIn'
  }
}
