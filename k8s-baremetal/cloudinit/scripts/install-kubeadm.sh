#!/bin/bash
      VERSION={0}-00 
      apt-get install -y apt-transport-https ca-certificates curl
      curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
      echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list

      apt-get update
      apt-get install -y kubelet=$VERSION kubeadm=$VERSION kubectl=$VERSION
      apt-mark hold kubelet kubeadm kubectl