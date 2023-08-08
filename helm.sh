#!/bin/bash
createKindCluster() {
    #export KIND_EXPERIMENTAL_DOCKER_NETWORK=enabled
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
    directory="~/kubedata"
    if [ -d "$directory" ]; then
        rm -rf "${directory:?}/"*
    else
        mkdir -p "$directory"
    fi
    
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

createKindCluster
installFlannel
installMultus
createPV
getContainerIDandAddeth1
deployfree5gc

