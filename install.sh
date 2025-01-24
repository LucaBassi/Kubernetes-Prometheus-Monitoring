# master node hostname and hostfile
sudo hostnamectl set-hostname mas-masternode-01
sudo echo '10.20.0.101 mas-workernode-01' | sudo tee -a /etc/hosts
sudo reboot

# worker node hostname and hostfile
sudo hostnamectl set-hostname mas-workernode-01
sudo echo '10.20.0.100 mas-masternode-01' | sudo tee -a /etc/hosts
sudo reboot


#---------------#
# each nodes    #
#---------------#
# off swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# containerd install and config
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update 
sudo apt-get install -y containerd.io

sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's\registry.k8s.io/pause:3.6\registry.k8s.io/pause:3.9\' /etc/containerd/config.toml
sudo systemctl restart containerd

# Kubernetes install and config
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt install kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl

# environnement config
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system


#---------------#
# master node   #
#---------------#
# init Cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# after worker node joined cluser
kubectl label node mas-workernode-01 node-role.kubernetes.io/worker=worker

# Cluster settings
# flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# cni plugin
sudo mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
sudo  tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.2.0.tgz

# storage
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# helm install
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# deploy ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# get crazy-karpet Change dev by prod if you need
kubectl apply -f https://raw.githubusercontent.com/CPNV-ES-MAS3-X/Prometheus-Containerization/main/DansTonKube/Kebernetes-Cluster/one-shot-prom/carzy-karpet-dev.yml
kubectl apply -f https://raw.githubusercontent.com/CPNV-ES-MAS3-X/Prometheus-Containerization/main/DansTonKube/Kebernetes-Cluster/ingress/ingress-dev.yml


# Network settings 
sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo bash -c "iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 127.0.0.1"
sudo bash -c "iptables -A FORWARD -p tcp -d 127.0.0.1 --dport 80 -j ACCEPT"

# port porward
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80

# test ingress 
curl --resolve demo.localdev.me:8080:10.20.0.100 http://demo.localdev.me:8080/prometheus
