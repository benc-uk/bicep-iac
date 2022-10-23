// ==================================================================================
// Module for cloud init of the jump box
// ==================================================================================

param keyVaultName string

// Bash scripts injected as part of cloud init, note use of format() to inject variables
var accessScript = format(loadTextContent('scripts/access-cluster.sh'), keyVaultName)
var keyVaultLibScript = loadTextContent('scripts/lib-keyvault.sh')

var cloudConfig = '''
#cloud-config
package_update: true
packages:
 - jq

write_files:
  - content: | 
      {0}
    path: /home/kube/access-cluster.sh
    permissions: '0755'
  - content: | 
      {1}
    path: /home/kube/lib-keyvault.sh

runcmd:
  - [ snap, install, kubectl, --classic ]
  - [ chown, -R, kube:kube, /home/kube ]
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
// Completed cloud-config is effectively exported from this Bicep using this output
output cloudInit string = format(cloudConfig, accessScript, keyVaultLibScript)
