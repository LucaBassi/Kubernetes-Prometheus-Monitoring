# master node
sudo hostnamectl set-hostname mas-masternode-01
sudo echo '10.20.0.101 mas-workernode-01' | sudo tee -a /etc/hosts
sudo reboot

# worker node
sudo hostnamectl set-hostname mas-workernode-01
sudo echo '10.20.0.100 mas-masternode-01' | sudo tee -a /etc/hosts
sudo reboot

# each nodes
sudo apt update -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker

#curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg
#echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/kubernetes.gpg] http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list
#sudo apt update

sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt install kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo tee /etc/default/kubelet <<EOF
KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
EOF
sudo systemctl daemon-reload && sudo systemctl restart kubelet
   
sudo tee /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
"log-driver": "json-file",
"log-opts": {"max-size": "100m"},
"storage-driver": "overlay2"
}
EOF
sudo systemctl daemon-reload && sudo systemctl restart docker

# master nodes

#sudo mkdir -p /opt/cni/bin
#wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
#sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.4.0.tgz

sudo sed -i  '/\[Service\]/a Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"' /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload && sudo systemctl restart kubelet

#sudo kubeadm init --control-plane-endpoint=mas-masternode-01 --upload-certs --pod-network-cidr=10.244.0.0/16
sudo kubeadm init --control-plane-endpoint=mas-masternode-01 --pod-network-cidr=10.244.0.0/16


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#------------------------------#
# after worker node joined cluser
kubectl label node mas-workernode-01 node-role.kubernetes.io/worker=worker


# Cluster settings
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
# kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml

## helm 
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

sudo tee /run/flannel/subnet.env << EOF
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.0/16
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF

# deploy ingress controller
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.loadBalancerIP=10.20.0.101


# get crazy-karpet
kubectl apply -f https://raw.githubusercontent.com/CPNV-ES-MAS3-X/Prometheus-Containerization/main/DansTonKube/Kebernetes-Cluster/one-shot-prom/carzy-karpet.yml
kubectl apply -f https://raw.githubusercontent.com/CPNV-ES-MAS3-X/Prometheus-Containerization/main/DansTonKube/Kebernetes-Cluster/ingress.yml

# Network settings 
sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo bash -c "iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 127.0.0.1"
sudo bash -c "iptables -A FORWARD -p tcp -d 127.0.0.1 --dport 80 -j ACCEPT"

# port porward
kubectl port-forward --namespace=ingress-nginx service/ingress-nginx-controller 8080:80

# test ingress 
curl --resolve demo.localdev.me:8080:10.20.0.100 http://demo.localdev.me:8080/prometheus
