// ==================================================================================
// Module for cloud init on the HAProxy load balancer
// ==================================================================================

var haproxyConf = loadTextContent('other/haproxy.cfg')

var cloudConfig = '''
#cloud-config
package_update: true
packages:
 - haproxy

write_files:
  - content: | 
      {0}
    path: /etc/haproxy/haproxy.cfg

runcmd:
  - [ systemctl restart haproxy.service ]
'''

// Heavy use of format function as Bicep doesn't yet support interpolation on multiline strings
output cloudInit string = format(cloudConfig, haproxyConf)
