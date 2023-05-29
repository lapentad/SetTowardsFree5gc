# SetTowardsFree5gc
Scripts to help you deploy Free5GC in a single cluster on a Ubuntu machine using **Kind** and **Helm**, based on [Orange-OpenSource/towards5gs helm charts](https://github.com/Orange-OpenSource/towards5gs-helm/tree/main/charts).

This bash script performs various checks and installations related to the Kubernetes environment setup for deploying the free5GC project.

## TL;DR

To use the script, follow these steps:

1. Make the script executable and run it: `chmod +x deploy.sh && ./deploy.sh`
2. `watch kubectl get po -A` CTRL+C when all the pods are RUNNING
3. [Simulator](#Simulator)

## Prerequisites

Before running the script, ensure the following prerequisites are met:

- The script assumes that you have a Linux-based operating system, preferably Ubuntu.
- Make sure you have necessary permissions to install packages and modify system configurations.
- Internet connectivity is required to download and install packages.

## Usage

1. Download the script to your local machine.
2. Open a terminal and navigate to the directory where the script is located.
3. Make the script executable if needed: `chmod +x deploy.sh`.
4. Run the script: `./deploy.sh`.

## Functionality

The script performs the following tasks:

1. **checkKernel**: Checks the kernel version and exits if it is less than the required version.
2. **checkDocker**: Installs Docker if not already installed.
3. **checkHelm**: Installs Helm if not already installed.
4. **checkKubectl**: Installs kubectl if not already installed or updates to the required version.
5. **installCNIPlugins**: Installs CNI plugins required for networking.
6. **installGo**: Installs Go programming language if not already installed.
7. **installMongo**: Installs MongoDB if not already installed.
8. **installKind**: Installs Kind, a tool for running local Kubernetes clusters using Docker containers.
9. **createKindCluster**: Creates a Kind cluster with custom configurations.
10. **installFlannel**: Installs Flannel networking plugin for the Kind cluster.
11. **installMultus**: Installs Multus CNI plugin for the Kind cluster.
12. **createPV**: Creates a Persistent Volume in the Kind cluster.
13. **getContainerIDandAddeth1**: Retrieves the Docker ID of the container named `kind-control-plane` and adds an `eth1` interface to it.
14. **deployfree5gc**: Deploys the free5GC project to the Kubernetes cluster using Helm.

<a id="simulator"></a>
## Simulator
To run the simulator you need to have a subscriber, to do so you can follow the insctuctions in the `./webUi.sh`

1. Make sure all the scripts are runnable `chmod +x webUi.sh` etc etc
2. `./webUi.sh`
3. Login in the web ui and make a new Subscriber with default values.
4. `./simulator.sh`
5. Wait until the EU pod of the simulator is running and use the interface uesimtun0 of that pod to ping anything. 

## Note

- Make sure to review the script and adjust any specific configurations or requirements to match your environment.
- Ensure that you have the necessary permissions and prerequisites before running the script.
- Running the script may require administrative privileges and modify system configurations.

## References

- [towards5gs-helm](https://github.com/Orange-OpenSource/towards5gs-helm)
- [flannel networking](https://routemyip.com/posts/k8s/setup/flannel/#the-solution)
- [flannel Poject](https://github.com/flannel-io/flannel/)
- [multus-cni Project](https://github.com/k8snetworkplumbingwg/multus-cni)
- [gtp5c kernel drivers](https://github.com/free5gc/gtp5g)
- [deploying free5GC article](https://medium.com/rahasak/deploying-5g-core-network-with-free5gc-kubernets-and-helm-charts-29741cea3922)
- [free5GC Project](https://www.free5gc.org/)




