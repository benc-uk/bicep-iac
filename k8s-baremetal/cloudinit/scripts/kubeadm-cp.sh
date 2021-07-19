#!/bin/bash
      source /root/lib-keyvault.sh

      # See if firstNode secret exists, to do a crude leader election
      getKeyVaultSecret {3} firstNode > /dev/null 2>&1

      if [[ $? -ne 0 ]]; then
        echo "Detected this is the first node in cluster, running kubeadm init"
        putKeyVaultSecret {3} firstNode "$(hostname)"

        # Initialize the cluster as the first CP node
        kubeadm init --pod-network-cidr=10.244.0.0/16 --token-ttl=20m --token={1} --control-plane-endpoint {0}:6443 --upload-certs --certificate-key={2}
        
        # Wait for it to be ready
        /root/wait-cp-ready.sh {0}
        sleep 10

        # Apply Flannel CNI pod network
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml 
        
        # Make kubeconfig available to other users
        cp /etc/kubernetes/admin.conf /home/azureuser/admin.conf
        chmod a+rw /home/azureuser/admin.conf
        source /root/lib-keyvault.sh
        putKeyVaultSecretFromFile {3} kubeconfig /etc/kubernetes/admin.conf
        exit
      fi

      echo "Joining cluster as an additional control plane node"

      # Wait for control plane to be ready
      /root/wait-cp-ready.sh {0}
      sleep 10      
      # Join the cluster as an extra control plane node
      kubeadm join {0}:6443 --control-plane --token={1} --certificate-key={2} --discovery-token-unsafe-skip-ca-verification
        