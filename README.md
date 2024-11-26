# CRI-O, Sysbox, and K3s Setup Playbooks

This repository contains Ansible playbooks for managing a Kubernetes environment on Ubuntu 23.04. These playbooks install CRI-O as the container runtime, set up Sysbox for enhanced environment isolation, and configure a K3s server to use CRI-O.

Created from this issue: https://github.com/nestybox/sysbox/issues/841

## Prerequisites

1. **Target System**: Ubuntu 23.04 (tested also in 22.04).
   - In case of using ubuntu 23 or above, you will need to create a new Dockerimage changing lines `263` `709` from [Daemonset](https://github.com/nestybox/sysbox-pkgr/blob/72d84abd652983cf34b4b52f48ba9d027f9a1779/k8s/scripts/sysbox-deploy-k8s.sh) and then change line `54` from this [Manifest](https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml): `roles/sysbox_uninstall/files/sysbox.yaml` and `roles/sysbox_install/files/sysbox.yaml`
2. **Ansible Installed**: Ensure Ansible is installed on your control node.
   - Installation command: `sudo apt update && sudo apt install ansible`
3. **User Permissions**: The user running the playbooks must have `sudo` privileges on the target machine(s).
4. **K3s Installed**: K3s Agent must already be installed. In case of K3s master installation, uncomment lines 1-8 and comment lines 10-18 from `roles/sysbox_install/tasks/main.yaml` and `roles/sysbox_uninstall/tasks/main.yaml`

## Playbooks

### 1. `crio-install.yaml`
This playbook installs CRI-O on the target Ubuntu machine and configures it as the container runtime.

**Key Tasks:**
- Adds the CRI-O repository for Ubuntu 23.04.
- Installs CRI-O, `cri-o-runc`, and `containernetworking-plugins`.
- Configures CRI-O for use with the K3s server.

### 2. `crio-uninstall.yaml`
This playbook removes CRI-O and all associated components from the target machine.

**Key Tasks:**
- Uninstalls CRI-O, `cri-o-runc`, and `containernetworking-plugins`.
- Cleans up configuration files and runtime data.

### 3. Sysbox Installation
The setup includes installing Sysbox for enhanced container isolation and improved security in Kubernetes environments.

**Key Tasks:**
- Installs Sysbox on the target machine.
- Configures Sysbox as an alternative runtime for sandboxed workloads.

## Usage

Remember to change your machines in `inventory/host.ini`
Run the playbooks using the following commands:

### Install CRI-O and Sysbox
```bash
ansible-playbook  crio-install.yaml
