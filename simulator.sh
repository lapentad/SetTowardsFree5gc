#!/bin/bash
for context in $(kubectl config get-contexts --no-headers --output name); do
    kubectl config use-context "$context"
    kubectl rollout status daemonset/kube-multus-ds -n kube-system --timeout=3m
done

helm -n free5gc install v2 towards5gs/ueransim

export POD_NAME=$(kubectl get pods -n free5gc -l "component=ue" -o jsonpath="{.items[0].metadata.name}")
while [[ $(kubectl get pods -n free5gc $POD_NAME -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done
echo "$POD_NAME ready"
echo "Try:"
echo "kubectl exec -n free5gc -it \$(kubectl get pods -n free5gc -l "component=ue" -o jsonpath="{.items[0].metadata.name}") -- curl --interface uesimtun0 https://www.google.com"
