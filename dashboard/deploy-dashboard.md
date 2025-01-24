# Download dashboard with helm
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# or Download dashboard and deploy with kubectl
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/charts/recommended.yaml 

# apply ingress access dashboard
kubectl apply -f ing-dash.yml 

# os network settings 
sudo bash -c "iptables -t nat -A PREROUTING -p tcp --dport 8443 -j DNAT --to-destination 127.0.0.1"
sudo bash -c "iptables -A FORWARD -p tcp -d 127.0.0.1 --dport 443 -j ACCEPT"
sudo bash -c "iptables -t nat -A PREROUTING -p tcp --dport 8443 -j DNAT --to-destination 127.0.0.1"

# kube port forwarding
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443

# Create a Admin User
https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md


# Install metric-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.0/components.yaml

## change config
https://github.com/kubernetes-sigs/metrics-server/issues/812


kubectl edit deploy metrics-server -n kube-system


Add

- --kubelet-insecure-tls
```
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=8448
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-insecure-tls
```
