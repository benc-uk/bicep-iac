// ==================================================================================
// Module for RKE2 agent cloudConfig
// ==================================================================================

@description('Version of RKE2 to use, if blank latest will be installed')
param version string = ''

@description('Magic token string used to add agents to the cluster')
param token string

@description('Hostname or IP of server or server loadbalancer if using HA')
param serverHost string

@description('Region for Azure all RKE2 resources')
param region string

@description('Name of the subnet the RKE2 server and agents are using')
param subnetName string

@description('NSG name attached to the subnet')
param nsgName string

@description('Name of the VNet the RKE2 server and agents are using')
param vnetName string

@description('Azure tenant ID')
param tenantId string

@description('Client ID of user identity')
param clientId string

@description('Azure subscription ID')
param subscriptionId string

@description('Resource group RKE2 has been deployed to')
param resourceGroup string

@description('The cloud environment identifier')
param cloudName string = 'AzurePublicCloud'

// ===== Variables ============================================================

var cloudConfig = '''
#cloud-config
package_update: true

write_files:
  - content: |
      #!/bin/bash
      echo \"Installing RKE2 agent using upstream script\"
      curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" INSTALL_RKE2_VERSION="{0}" sh -
    path: /root/install.sh
    owner: root:root

  - content: |
      vm.max_map_count=262144
    path: /etc/sysctl.d/10-vm-map-count.conf
    owner: root:root

  - content: |
      server: https://{1}:9345
      token: {2}
      node-label: ["failure-domain.beta.kubernetes.io/region={3}"]
      cloud-provider-name: azure
      cloud-provider-config: /etc/rancher/rke2/azure.json
    path: /etc/rancher/rke2/config.yaml
    owner: root:root

  - content: |
      {{
        "cloud": "{4}",
        "tenantId": "{5}",
        "userAssignedIdentityID": "{6}",
        "subscriptionId": "{7}",
        "resourceGroup": "{8}",
        "vmType": "standard",
        "location": "{3}",
        "subnetName": "{9}",
        "securityGroupName": "{10}",
        "securityGroupResourceGroup": "{8}",
        "vnetName": "{11}",
        "vnetResourceGroup": "{8}",
        "routeTableName": "rke2",
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
  - [ sh, -c, echo \"Installing and starting RKE2 agent\" ]
  - [ sh, -c, echo \"###################################\" ]
  - [ /root/install.sh ]
  - [ systemctl, enable, rke2-agent.service ]
  - [ systemctl, start, rke2-agent.service ]

  - [ sysctl, -p, /etc/sysctl.d/10-vm-map-count.conf ]
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
output cloudInit string = format(cloudConfig, version, serverHost, token, region, cloudName, tenantId, clientId, subscriptionId, resourceGroup, subnetName, nsgName, vnetName)
