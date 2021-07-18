#!/bin/bash
      # From https://kubernetes.io/docs/setup/production-environment/container-runtimes/
      cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
      overlay
      br_netfilter
      EOF

      sudo modprobe overlay
      sudo modprobe br_netfilter

      # Setup required sysctl params, these persist across reboots.
      cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
      net.bridge.bridge-nf-call-iptables  = 1
      net.ipv4.ip_forward                 = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      EOF

      # Apply sysctl params without reboot
      sudo sysctl --system

      # Install containerd
      apt-get install -y containerd
      sudo mkdir -p /etc/containerd
      containerd config default | sudo tee /etc/containerd/config.toml
      sudo systemctl restart containerd