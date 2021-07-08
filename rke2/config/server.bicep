@description('Version of RKE2 to use, if blank latest will be installed')
param version string = ''

@description('Magic token string used to add agents to the cluster')
param token string

@description('Server hostname for TLS-SAN')
param serverHost string

param tenantId string
param clientId string
param subscriptionId string
param resourceGroup string
param region string
param subnetName string
param nsgName string
param vnetName string

var cloudConfig = '''
#cloud-config
package_update: true

write_files:
  - content: |
      #!/bin/bash
      echo \"Installing RKE2 server using upstream script\"
      curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION="{0}" sh -

      echo PATH="/var/lib/rancher/rke2/bin:$PATH" >> /home/azureuser/.profile
      echo export KUBECONFIG=/etc/rancher/rke2/rke2.yaml >> /home/azureuser/.profile
      echo alias k='kubectl' >> /home/azureuser/.profile

      chmod a+rw /etc/rancher/rke2/rke2.yaml     
    path: /root/install.sh
    owner: root:root

  - content: |
      vm.max_map_count=262144
    path: /etc/sysctl.d/10-vm-map-count.conf
    owner: root:root

  - content: |
      token: {1}
      tls-san: {2}
      cloud-provider-name: azure
      cloud-provider-config: /etc/rancher/rke2/azure.json
    path: /etc/rancher/rke2/config.yaml
    owner: root:root

  - content: |
      {{
        "cloud": "AzurePublicCloud",
        "tenantId": "{3}",
        "userAssignedIdentityID": "{4}",
        "subscriptionId": "{5}",
        "resourceGroup": "{6}",
        "vmType": "standard",
        "location": "{7}",
        "subnetName": "{8}",
        "securityGroupName": "{9}",
        "securityGroupResourceGroup": "{6}",
        "vnetName": "{10}",
        "vnetResourceGroup": "{6}",
        "routeTableName": "rke2-routes",
        "cloudProviderBackoff": false,
        "useManagedIdentityExtension": true,
        "useInstanceMetadata": true,
        "loadBalancerSku": "standard",
        "excludeMasterFromStandardLB": false
      }}
    path: /etc/rancher/rke2/azure.json
    owner: root:root

runcmd:
  - [ chmod, +x, /root/install.sh ]

  - [ sh, -c, echo \"###################################\" ]
  - [ sh, -c, echo \"Installing and starting RKE2 server\" ]
  - [ sh, -c, echo \"###################################\" ]
  - [ /root/install.sh ]
  - [ systemctl, enable, rke2-server.service ]
  - [ systemctl, start, rke2-server.service ]

  - [ sysctl, -p, /etc/sysctl.d/10-vm-map-count.conf ]
  - [ sleep, 10 ]
  - [ chmod, a+rw, /etc/rancher/rke2/rke2.yaml ]
'''

output customDataString string = format(cloudConfig, version, token, serverHost, tenantId, clientId, subscriptionId, resourceGroup, region, subnetName, nsgName, vnetName)
