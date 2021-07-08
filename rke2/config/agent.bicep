@description('Version of RKE2 to use, if blank latest will be installed')
param version string = ''

@description('Magic token string used to add agents to the cluster')
param token string

@description('Hostname or IP of server or server loadbalancer if using HA')
param serverHost string

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
    path: /etc/rancher/rke2/config.yaml
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

output customDataString string = format(cloudConfig, version, serverHost, token)
