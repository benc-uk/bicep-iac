#!/bin/bash
      echo "Joining cluster as a worker node"

      /root/wait-cp-ready.sh {0}
      sleep 20
      kubeadm join {0}:6443 --config /root/kubeadm.conf