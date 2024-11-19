# Install K3S
USERNAME=devops
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl -sLS https://get.k3sup.dev | sh
sudo cp k3sup /usr/local/bin/k3sup

mkdir $HOME/.kube
k3sup install \
--ip 192.168.1.11 \
--tls-san 192.168.1.10 \
--cluster \
--k3s-channel latest \
--local-path $HOME/.kube/config \
--no-extras \
--user "$USERNAME"

# Install CRI-O
OS=xUbuntu_22.04
CRIO_VERSION=1.24
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /"|sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add -
sudo apt update
sudo apt install cri-o cri-o-runc
sudo systemctl start crio
sudo systemctl enable crio

# FROM HERE EVERYTHING WITH SUDO!
# Configure CRI-O
sudo su
#  Configure network settings essential for Kubernetes by enabling iptables filtering for bridge traffic, disabling IPv6, and enabling IP forwarding for IPv4
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Install CRI-O CNI and Configure
sudo apt install containernetworking-plugins
# sudo sed -i '/network_dir =/s/^# //' /etc/crio/crio.conf
# sudo sed -i 's/# plugin_dirs = \[/plugin_dirs = \[/' /etc/crio/crio.conf
# sudo sed -i '/plugin_dirs = \[/a\      "/usr/lib/cni/",' /etc/crio/crio.conf
# sudo sed -i 's|#       "/opt/cni/bin/",|      "/opt/cni/bin/",|g' /etc/crio/crio.conf
# sudo sed -i '/      "\/opt\/cni\/bin\/",/a\]' /etc/crio/crio.conf

# https://github.com/cri-o/cri-o/blob/main/contrib/cni/README.md#configuration-directory
sudo rm -rf /etc/cni/net.d/100-crio-bridge.conf 
sudo curl -fsSLo /etc/cni/net.d/11-crio-ipv4-bridge.conf https://raw.githubusercontent.com/cri-o/cri-o/refs/heads/main/contrib/cni/11-crio-ipv4-bridge.conflist
sudo sed -i 's/1.0.0/0.3.1/' /etc/cni/net.d/11-crio-ipv4-bridge.conflist
sudo sed -i 's|10.85.0.0/16|10.224.0.0/16|' /etc/cni/net.d/11-crio-ipv4-bridge.conflist

# Install Cri CLI
sudo apt install cri-tools

# Configure CRI-O to use default kubelet cgroup
# sudo sed -i '/\[crio.runtime\]/a\conmon_cgroup = "pod"' /etc/crio/crio.conf
# sudo sed -i '/conmon_cgroup = "pod"/a\cgroup_manager = "cgroupfs"' /etc/crio/crio.conf
# sudo sed -i '/cgroup_manager = "cgroupfs"/a\registries = \[' /etc/crio/crio.conf
# sudo sed -i '/^registries = \[/a\  "quay.io",' /etc/crio/crio.conf
# sudo sed -i '/^  "quay.io",/a\  "docker.io"' /etc/crio/crio.conf
# sudo sed -i '/^  "docker.io"/a\\]' /etc/crio/crio.conf

mv /etc/crio/crio.conf /etc/crio/crio.conf_backup
cp crio.conf /etc/crio/crio.conf

# Disable SWAP
free -h
swapoff -a
swapoff -a
# sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab
sed -i.bak -r 's/(.*swap.*)/#\1/' /etc/fstab
free -h

# IPv6 is disabled system-wide
sudo echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
sudo echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sudo sysctl -p

sudo sed -i "s|::1|#::1|" /etc/hosts

# Add containers ns, in this case allocates 10 PODS
echo "containers:300000:655360" | sudo tee -a /etc/subuid
echo "containers:300000:655360" | sudo tee -a /etc/subgid

# Apply changes
sudo systemctl restart --now crio
# Restart IP link in case of error with pods
sudo ip link delete cni0

# Install container security
sudo apt update
sudo apt install -y selinux-utils selinux-policy-default

# Reinstall K3S with crio as a container runner
export K3S_KUBECONFIG_MODE="644"
export INSTALL_K3S_EXEC=" --container-runtime-endpoint /var/run/crio/crio.sock --disable=traefik"
export INSTALL_K3S_VERSION=v1.29.0+k3s1
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=$INSTALL_K3S_VERSION sh -

# Install sysbox
kubectl apply -f sysbox.yaml
