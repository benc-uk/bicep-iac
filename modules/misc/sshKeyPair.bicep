//
// THIS IS UNTESTED, AND LIKELY DOESN'T WORK
//

param location string 

// ===== Variables ============================================================

resource sshScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'sshkeypair-script'
  location: location 
  kind: 'AzureCLI'
  properties: {
    scriptContent: loadTextContent('sshKeyPair.sh')
    cleanupPreference: 'OnExpiration'
    retentionInterval: 'PT60M'
    azCliVersion: '2.0.77'
  }
}

output publicKey string = reference('sshkeypair-script').outputs.publicKey
output privateKey string = reference('sshkeypair-script').outputs.privateKey
