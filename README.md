# Kubernetes-Prometheus-Monitoring
## Create secret to login to private docker registry

```sh
kubectl create secret docker-registry reg-cred-secret --docker-server=$REGISTRY_NAME:5000 --docker-username=myuser --docker-password=mypasswd
```
## Troubleshot
### Cluster 
```bash
#reset cluster 

## Master Node
sudo kubeadm reset --force
sudo rm $HOME/.kube/config
sudo rm -rf /etc/cni/net.d
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo systemctl daemon-reload && sudo systemctl restart kubelet
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sudo systemctl restart containerd


## Worker Node
sudo kubeadm reset --force
sudo rm $HOME/.kube/config
sudo rm -rf /etc/cni/net.d
sudo systemctl restart containerd
#sudo kubeadm join...

```
### ingress
```bash
kubectl get validatingwebhookconfigurations 
kubectl delete validatingwebhookconfigurations ingress-nginx-admission
```

### Pods
```bash

kubectl describe deployment
kubectl describe pod
kubectl logs
kubectl get events

#For example, if your deployment is named “myapp-deployment,” you would use:
kubectl get pods -l app=myapp-deployment

#Next, you can use kubectl describe pod command to get more details.
kubectl describe pod <pod name> -n <namespace>


kubectl logs <pod name> -n <namespace> -p
kubectl logs <pod name> -n <namespace> --previous
kubectl logs <pod name> -n <namespace> --all-containers
kubectl logs <pod name> -n <namespace> -c mycontainer
kubectl logs <pod name> -n <namespace> --tail 50
```
### Ingress
```bash
kubectl get ns

kubectl delete all  --all -n ingress-nginx

kubectl delete ingress ingress-nginx
kubectl delete deployment ingress-nginx
kubectl delete service ingress-nginx
```

# Sources 
## flannel network
https://github.com/flannel-io/flannel

## containerd install
https://www.nocentino.com/posts/2021-12-27-installing-and-configuring-containerd-as-a-kubernetes-container-runtime/
