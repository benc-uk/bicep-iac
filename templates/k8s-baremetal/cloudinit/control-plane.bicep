// ==================================================================================
// Module for cloud init on the control plane nodes
// ==================================================================================

param kubernetesVersion string
param controlPlaneExternalHost string
param bootStrapToken string
param certKey string
param keyVaultName string

// Needed for Azure cloud provider and cloud.conf
param clientId string
param tenantId string = subscription().tenantId
param subscriptionId string = subscription().subscriptionId
param clusterName string = resourceGroup().name
param location string = resourceGroup().location

// Optionally run extra commands before things off, we use ls as kind of null/noop command
param preRunCmd string = 'ls'

// ===== Variables ============================================================

// Bash scripts injected as part of cloud init, note use of format() to inject variables
var containerdScript = loadTextContent('scripts/install-containerd.sh')
var kubeadmScript = format(loadTextContent('scripts/install-kubeadm.sh'), kubernetesVersion)
var cpReadyScript = format(loadTextContent('scripts/wait-cp-ready.sh'))
var controlPlaneScript = format(loadTextContent('scripts/kubeadm-cp.sh'), controlPlaneExternalHost, keyVaultName)
var keyVaultLibScript = loadTextContent('scripts/lib-keyvault.sh')

// Other config files, heavily parameterized using format()
var kubeadmConf = format(loadTextContent('other/kubeadm.conf'), bootStrapToken, certKey, controlPlaneExternalHost)
var cloudConf = format(loadTextContent('other/cloud.conf'), tenantId, clientId, subscriptionId, clusterName, location)
var defaultStorageClass = loadTextContent('other/default-sc.yaml')
var metricsServer = loadTextContent('other/metrics-server.yaml')

var cloudConfig = '''
#cloud-config
package_update: true
packages:
  - jq
  - net-tools

write_files:
  - content: | 
      {0}
    path: /root/install-containerd.sh
    permissions: '0755'
  - content: | 
      {1}
    path: /root/install-kubeadm.sh
    permissions: '0755'
  - content: | 
      {2}
    path: /root/wait-cp-ready.sh
    permissions: '0755'      
  - content: | 
      {3}
    path: /root/kubeadm-cp.sh
    permissions: '0755'
  - content: | 
      {4}
    path: /root/lib-keyvault.sh
    permissions: '0755'
  - content: | 
      {5}
    path: /etc/kubernetes/cloud.conf
  - content: | 
      {6}
    path: /root/kubeadm.conf
  - content: | 
      {7}
    path: /root/default-sc.yaml
  - content: | 
      {8}
    path: /root/metrics-server.yaml    
  - content: | 
      export KUBECONFIG=/etc/kubernetes/admin.conf
      alias k='kubectl'
      alias kn='kubectl config set-context --current --namespace '
    path: /root/.profile
    append: true

runcmd:   
  - [ {9} ]
  - [ /root/install-containerd.sh ]
  - [ /root/install-kubeadm.sh ] 
  - [ /root/kubeadm-cp.sh ] 
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
// Completed cloud-config is effectively exported from this Bicep using this output
output cloudInit string = format(cloudConfig, containerdScript, kubeadmScript, cpReadyScript, controlPlaneScript, keyVaultLibScript, cloudConf, kubeadmConf, defaultStorageClass, metricsServer, preRunCmd)
