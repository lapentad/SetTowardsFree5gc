#!/bin/bash
echo "1. login into localhost:5000 username:admin password:free5gc"
echo "2. make a new SUBSCRIBER leaving evrything by default"
echo "3. Optional:if you are in a VM without gui then log into the vm mapping the localhost into your machine: "
echo "ssh -L localhost:5000:localhost:5000 <USER>@<IP>"
kubectl port-forward --namespace free5gc svc/webui-service 5000:5000
 
