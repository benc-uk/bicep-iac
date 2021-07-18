// ==================================================================================
// Module for cloud init on the control plane nodes
// ==================================================================================

param kubernetesVersion string
param controlPlaneExternalHost string
param bootStrapToken string
param certKey string
param keyVaultName string

// ===== Variables ============================================================

var containerdScript = loadTextContent('scripts/install-containerd.sh')
var kubeadmScript = format(loadTextContent('scripts/install-kubeadm.sh'), kubernetesVersion)
var cpReadyScript = format(loadTextContent('scripts/wait-cp-ready.sh'))
var controlPlaneScript = format(loadTextContent('scripts/kubeadm-cp.sh'), controlPlaneExternalHost, bootStrapToken, certKey, keyVaultName)
var keyVaultLibScript = loadTextContent('scripts/lib-keyvault.sh')

var cloudConfig = '''
#cloud-config
package_update: true
packages:
  - jq

write_files:
  - content: | 
      {0}
    path: /root/install-containerd.sh
    owner: root:root
    permissions: '0755'
  - content: | 
      {1}
    path: /root/install-kubeadm.sh
    owner: root:root
    permissions: '0755'
  - content: | 
      {2}
    path: /root/wait-cp-ready.sh
    owner: root:root
    permissions: '0755'      
  - content: | 
      {3}
    path: /root/kubeadm-cp.sh
    owner: root:root
    permissions: '0755'
  - content: | 
      {4}
    path: /root/lib-keyvault.sh
    owner: root:root
    permissions: '0755'       
  - content: | 
      export KUBECONFIG=/etc/kubernetes/admin.conf
      alias k='kubectl'
      alias kn='kubectl config set-context --current --namespace '
    path: /root/.profile
    append: true

runcmd:   
  - [ /root/install-containerd.sh ]
  - [ /root/install-kubeadm.sh ] 
  - [ /root/kubeadm-cp.sh] 
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
output cloudInit string = format(cloudConfig,  containerdScript, kubeadmScript, cpReadyScript, controlPlaneScript, keyVaultLibScript)
