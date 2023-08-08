#!/bin/bash

helm uninstall -n free5gc v1
helm uninstall -n free5gc v2
echo "To tear everything down: "
echo "kind delete cluster"
