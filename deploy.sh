#!/bin/bash

checkKernel() {
	required_version="5.4.0"
	current_version=$(uname -r)
	if [[ $current_version < $required_version ]]; then
		echo "Kernel version is less than $required_version. Exiting."
	else
		echo "Kernel version $current_version is compatible."
	fi
}

checkDocker() {
	if ! command -v docker &> /dev/null; then
		echo "Docker is not installed. Installing it..."
		sudo apt-get update -y
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		sudo add-apt-repository \
		   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		   $(lsb_release -cs) \
		   stable"
		sudo apt-get update -y
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y
		sudo usermod -aG docker $USER
		
	else
		echo "Docker is installed."
		
	fi
}

checkHelm() {
	if ! command -v helm &> /dev/null; then
		echo "Helm is not installed. Installing it..."
		curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
		chmod 700 ./get_helm.sh
		./get_helm.sh
		rm ./get_helm.sh
		
	else
		echo "Helm is installed."
		
	fi
}

checkKubectl() {
    required_version="1.20.0"
    kubectl_version=$(kubectl version --client --short | awk '{print $3}')
    if ! command -v kubectl &> /dev/null; then
        echo "kubectl is not installed. Installing it..."
		curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
		sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        
    fi
    if [[ "$(printf '%s\n' "$required_version" "$kubectl_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo "kubectl version is less than $required_version or not installed."
        echo "Replacing kubectl version with updated one"
		curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.4/2023-05-11/bin/linux/amd64/kubectl
		chmod +x ./kubectl
		mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
    else
        echo "kubectl version $kubectl_version is installed and meets the requirement."
    fi
}

installCNIPlugins() {
	curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="kind,docker,kubectl" PKG=cni-plugins bash
	git clone https://github.com/free5gc/gtp5g.git && cd ./gtp5g
	make
	sudo make install
}

installGo() {
	if ! command -v go &> /dev/null; then
		echo "Go is not installed. Installing it..."
		wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
		sudo su
		rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.4.linux-amd64.tar.gz
		exit 0
		rm go1.20.4.linux-amd64.tar.gz
		echo 'export GOPATH=$HOME/go' >> ~/.bashrc
		echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
		echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
		echo 'export GO111MODULE=auto' >> ~/.bashrc
		source ~/.bashrc
		
	else
		echo "Go is installed."
		
	fi
}

installMongo() {
	if ! command -v mongo &> /dev/null; then
		echo "Mongo is not installed. Installing it..."
		sudo apt -y update
		sudo apt -y install mongodb wget git
		sudo systemctl start mongodb
		
	else
		echo "Mongo is installed."
		
	fi
	
}

installKind() {
	if ! command -v kind &> /dev/null; then
		echo "Kind is not installed. Installing it..."
		go install sigs.k8s.io/kind@v0.19.0
		
	else
		echo "Kind is installed."
		
	fi
	
}

createKindCluster() {
    export KIND_EXPERIMENTAL_DOCKER_NETWORK=enabled
    cat <<EOF | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  disableDefaultCNI: true
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /opt/containernetworking/plugins
    containerPath: /opt/cni/bin
EOF
}

installFlannel() {
	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

installMultus() {
	kubectl apply -f https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick.yml
}

createPV() {
	mkdir ~/kubedata
	cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-local-pv9
  labels:
    project: free5gc
spec:
  capacity:
    storage: 8Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /home/$USER/kubedata
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - kind-control-plane
EOF
}

getContainerIDandAddeth1() {
    container_name="kind-control-plane"
    docker_id=$(docker ps -q --filter "name=$container_name")

    if [ -z "$docker_id" ]; then
        echo "Container '$container_name' is not running."
        exit 1
    else
        echo "Docker ID of '$container_name': $docker_id"
        export DOCKER_ID="$docker_id"
    fi
	docker exec $DOCKER_ID ip link add eth1 type dummy
	docker exec $DOCKER_ID ip link set eth1 up
	
}

deployfree5gc() {
	kubectl create namespace free5gc
	helm repo add towards5gs 'https://raw.githubusercontent.com/Orange-OpenSource/towards5gs-helm/main/repo/'
	helm repo update
	helm repo list
	helm search repo

	helm -n free5gc install v1 towards5gs/free5gc
}

checkKernel
checkDocker
checkHelm
checkKubectl
installCNIPlugins
installGo
installKind
installMongo
createKindCluster
installFlannel
installMultus
createPV
getContainerIDandAddeth1
deployfree5gc

