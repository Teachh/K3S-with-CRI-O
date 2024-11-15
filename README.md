# K3S-with-CRI-O

This repository contains the necessary files to set up K3s with CRI-O on an Ubuntu machine and deploy Sysbox for container isolation.
Created from this issue: https://github.com/nestybox/sysbox/issues/841

## Files

- **install.sh**: This script installs CRI-O and K3s on an Ubuntu machine. It configures the necessary components for K3s to use CRI-O as the container runtime.
- **crio.conf**: Configuration file for CRI-O. This file is generated as an output after running `install.sh`.
- **11-crio-ipv4-bridge.conflist**: Network configuration file for CRI-O. This file is also generated as an output after running `install.sh`.
- **sysbox.yaml**: A deployment file to set up Sysbox. Sysbox is used for enhanced container isolation, enabling K3s and CRI-O to run containers with system-level privileges.
