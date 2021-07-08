#!/usr/local/bin/bash

if [[ "${EDUCATES_MINIKUBE_IP}" == "" ]]; then
  echo -e "\nGetting Minikube IP"
  minikube start
  EDUCATES_MINIKUBE_IP=$(minikube ip)
  export EDUCATES_MINIKUBE_IP
  minikube stop
fi

echo -e "\nStarting Minikube"

minikube start --insecure-registry=${EDUCATES_MINIKUBE_IP}/24 --cpus=4 --memory=8g --vm

minikube addons enable ingress
minikube addons enable ingress-dns

# Install operator
echo -e "\nInstalling Educates"
kubectl apply -k "github.com/eduk8s/eduk8s?ref=master"

# Install add-ons
echo -e "\nInstalling add-ons"
source ./install-cluster-add-ons.sh
install_cluster_add_ons

# Capture minikube ip
IP=$(minikube ip)
# Check that the value is correct
if [[ "${EDUCATES_MINIKUBE_IP}" != "${IP}" ]]; then
  echo -e "\nUpdating Minikube IP"
  echo "Please re-run this script!"
  EDUCATES_MINIKUBE_IP=$(minikube ip)
  export EDUCATES_MINIKUBE_IP
  minikube stop
fi

echo -e "\nConfiguring Educates"
# Configure operator with domain name
kubectl set env deployment/eduk8s-operator -n eduk8s INGRESS_DOMAIN=$EDUCATES_MINIKUBE_IP.nip.io

# If working with large images configure nginx add `proxy-body-size: 1g` in data section:
#  kubectl edit configmap nginx-load-balancer-conf -n kube-system

echo -e "\nFinished Educates installation"
# Show if if above worked
kubectl get all -n eduk8s  

echo -e "\nDeploying workshop"
# deploy workshop definition
kubectl apply -f ./resources/workshop.yaml

# deploy training portal 
kubectl apply -f ./resources/training-portal.yaml

echo -e "\nFinished deploying workshop"
echo "Watching resources... Click on URL to open training portal"
echo "Ctrl-C here stops 'kubectl watch' only (the workshop will continue to run)"
# Get trainingportals, will have to 
kubectl get trainingportal --watch
