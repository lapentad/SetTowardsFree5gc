#!/bin/bash
sudolessUser() {
	if sudo grep -qE "^\s*${USER}\s+ALL=(ALL:ALL)\s+NOPASSWD:" /etc/sudoers; then
		echo "Passwordless sudo is already set for the user."
	else
		echo "Setting passwordless sudo for the user..."
		echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
		echo "Passwordless sudo privileges have been set for the user."
	fi
}

checkBasics() {
	sudo apt update
	sudo apt install -y wget git curl
}

checkKernel() {
	required_version="5.0.0"
	current_version=$(uname -r)
	if [[ $current_version < $required_version ]]; then
		echo "Kernel version is less than $required_version. Exiting."
		exit 1
	else
		echo "Kernel version $current_version is compatible."
	fi
}

checkDocker() {
	if ! command -v docker &> /dev/null; then
		echo "Docker is not installed. Installing it..."
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
		sudo add-apt-repository \
		   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
		   $(lsb_release -cs) \
		   stable"
		sudo apt-get update -y
		sudo apt-get install docker-ce docker-ce-cli containerd.io -y
		sudo usermod -aG docker $USER
		newgrp docker
	else
                sudo usermod -aG docker $USER
		newgrp docker
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
        echo "Replacing kubectl version with 1.26.4"
		curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.26.4/2023-05-11/bin/linux/amd64/kubectl
		chmod +x ./kubectl
		mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
    else
        echo "kubectl version $kubectl_version is installed and meets the requirement."
    fi
}

installCNIPlugins() {
    directory="/opt/containernetworking/plugins/"
    file="/etc/modules"
    search_string="gtp5g"

    if [ -n "$(ls -A "$directory")" ] && grep -q "$search_string" "$file"; then
        echo "$directory is not empty, and gtp5g drivers are installed."
    else
        mkdir $directory
	    GET_VER=$(curl -L -s https://github.com/containernetworking/plugins/releases/latest | grep '^\s*v' | sed 's/ //g') && \
		  curl -Lo ./cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/$GET_VER/cni-plugins-linux-amd64-$GET_VER.tgz
		sudo tar -zxvf cni-plugins.tgz --directory $directory
		ls $directory
        curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="kind,docker,kubectl" PKG=cni-plugins bash
        git clone https://github.com/free5gc/gtp5g.git && cd ./gtp5g
        make
        sudo make install
    fi
}

installGo() {
	if ! command -v go &> /dev/null; then
		echo "Go is not installed. Installing it..."
		wget https://go.dev/dl/go1.20.4.linux-amd64.tar.gz
		sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.4.linux-amd64.tar.gz
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
		wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo gpg --dearmor --output /etc/apt/trusted.gpg.d/mongodb.gpg
		echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb.list
		sudo apt update
		sudo apt install -y mongodb-org
		sudo systemctl start mongodb
		sudo systemctl status mongod
	else
		echo "Mongo is installed."
	fi
}

installKind() {
	if ! command -v kind &> /dev/null; then
		echo "Kind is not installed. Installing it..."
		GET_VER=$(curl -L -s https://github.com/kubernetes-sigs/kind/releases/latest | grep '^\s*v' | sed 's/ //g') && \
		  curl -Lo /usr/local/kind https://kind.sigs.k8s.io/dl/$GET_VER/kind-linux-amd64
		sudo install -o root -g root -m 0755 /usr/local/kind /usr/local/bin/kind
		kind version
	else
		echo "Kind is installed."
	fi
}

checkNetwork() {
        NIC=$(ip route | grep default | awk '{print $5}')
	sudo sysctl -w net.ipv4.ip_forward=1
	sudo iptables -t nat -A POSTROUTING -o $NIC -j MASQUERADE
	sudo systemctl stop ufw
	sudo iptables -I FORWARD 1 -j ACCEPT
}

sudolessUser
checkBasics
checkKernel
checkDocker
checkHelm
checkKubectl
installCNIPlugins
installGo
installMongo
installKind
checkNetwork
