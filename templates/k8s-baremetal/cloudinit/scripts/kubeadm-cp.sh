#!/bin/bash
      source /root/lib-keyvault.sh
      setKeyVaultEndpoint

      if [[ $(hostname) == *000000 ]]; then
        echo "First node in the cluster, running kubeadm init"

        # Initialize the cluster as the first CP node
        kubeadm init --config /root/kubeadm.conf --upload-certs

        # Wait for it to be ready
        /root/wait-cp-ready.sh {0}
        sleep 10

        # Apply Flannel CNI pod network
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml 
        # Add default storage class for Azure
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f /root/default-sc.yaml
        # Add metrics server
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f /root/metrics-server.yaml
        
        # Upload the admin kubeconfig to the KeyVault 
        source /root/lib-keyvault.sh
        echo "Uploading /etc/kubernetes/admin.conf to KeyVault as secret kubeconfig"
        putKeyVaultSecretFromFile {1} kubeconfig /etc/kubernetes/admin.conf
        exit
      fi
      echo "Joining existing cluster as an additional control plane node"

      # Wait for control plane to be ready
      /root/wait-cp-ready.sh {0}

      # This is a slightly hacky way to try to stagger the process of additional nodes joining, but it works
      host=$(hostname)
      hostNum=${{host: -1}}
      sleepTime=$(( hostNum * 60 ))
      echo "Staggering process, waiting extra $sleepTime seconds before joining..."
      sleep $sleepTime
      
      # Join the cluster as an extra control plane node
      kubeadm join {0}:6443 --config /root/kubeadm.conf