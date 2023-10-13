#!/bin/bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the user to the Docker group
sudo usermod -aG docker $USER && newgrp docker

sudo systemctl restart docker

# Continue with Minikube and Kubernetes setup
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

minikube start --cpus=4 --memory=6g --addons=ingress --vm-driver=docker --disk-size 10000mb
#minikube delete --all
minikube kubectl -- get nodes
alias kubectl="minikube kubectl --"

# Step3: Install AWX Operator
sudo cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - github.com/ansible/awx-operator/config/default?ref=2.1.0
images:
  - name: quay.io/ansible/awx-operator
    newTag: 2.1.0
namespace: awx
EOF

kubectl apply -k .
kubectl config set-context --current --namespace=awx

# Step4: Install AWX
sudo cat <<EOF > awx-server.yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-server
spec:
  service_type: nodeport
EOF

#kubectl apply -k .
#kubectl logs -f deployments/awx-operator-controller-manager -c awx-manager

# Step5: Enable external access
#kubectl port-forward service/awx-demo-service --address 0.0.0.0 30080:80 &> /dev/null &
