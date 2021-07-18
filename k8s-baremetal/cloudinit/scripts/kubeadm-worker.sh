#!/bin/bash
      /root/wait-cp-ready.sh {0}
      sleep 10
      kubeadm join {0}:6443 --token {1} --discovery-token-unsafe-skip-ca-verification