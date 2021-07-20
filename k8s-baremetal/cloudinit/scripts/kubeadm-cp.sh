#!/bin/bash
      source /root/lib-keyvault.sh

      # Feeble attempt at stopping a race condition with the leader election
      sleep $(( ( $RANDOM % 5 )  + 1 ))

      # See if firstNode secret exists, to do a crude leader election, based on first come first serve
      getKeyVaultSecret {1} firstNode > /dev/null 2>&1

      if [[ $? -ne 0 ]]; then
        echo "Detected this is the first node in cluster, running kubeadm init"
        putKeyVaultSecret {1} firstNode "$(hostname)"

        # Initialize the cluster as the first CP node
        kubeadm init --config /root/kubeadm.conf --upload-certs

        # Wait for it to be ready
        /root/wait-cp-ready.sh {0}
        sleep 10

        # Apply Flannel CNI pod network
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml 
        # Add default storage class for Azure
        kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f /root/default-sc.yaml
        
        # Make kubeconfig available to other users
        cp /etc/kubernetes/admin.conf /home/azureuser/admin.conf
        chmod a+rw /home/azureuser/admin.conf
        source /root/lib-keyvault.sh
        putKeyVaultSecretFromFile {1} kubeconfig /etc/kubernetes/admin.conf
        exit
      fi

      echo "Joining cluster as an additional control plane node"

      # Wait for control plane to be ready
      /root/wait-cp-ready.sh {0}
      sleep 10      
      # Join the cluster as an extra control plane node
      kubeadm join {0}:6443 --config /root/kubeadm.conf
      
        