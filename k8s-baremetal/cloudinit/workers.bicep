// ==================================================================================
// Module for cloud init on the worker nodes
// ==================================================================================

param kubernetesVersion string
param controlPlaneExternalHost string
param bootStrapToken string

// ===== Variables ============================================================

var containerdScript = loadTextContent('scripts/install-containerd.sh')
var kubeadmScript = format(loadTextContent('scripts/install-kubeadm.sh'), kubernetesVersion)
var cpReadyScript = format(loadTextContent('scripts/wait-cp-ready.sh'))
var nodeJoinScript = format(loadTextContent('scripts/kubeadm-worker.sh'), controlPlaneExternalHost, bootStrapToken)

var cloudConfig = '''
#cloud-config
package_update: true

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
    path: /root/kubeadm-worker.sh
    owner: root:root
    permissions: '0755'  

runcmd:
  - [ /root/install-containerd.sh ]
  - [ /root/install-kubeadm.sh ]  
  - [ /root/kubeadm-worker.sh ]  
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
output cloudInit string = format(cloudConfig,  containerdScript, kubeadmScript, cpReadyScript, nodeJoinScript)
