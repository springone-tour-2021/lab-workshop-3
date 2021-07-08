#!/usr/local/bin/bash

# Get Minikube IP (getting from file so it works across terminal sessions)
test -f local-eduk8s-start.env && source local-eduk8s-start.env
if [[ "${EDUCATES_MINIKUBE_IP}" == "" ]]; then
  printf "\nGetting Minikube IP\n"
  minikube start
  echo "export EDUCATES_MINIKUBE_IP=$(minikube ip)" > local-eduk8s-start.env
  source local-eduk8s-start.env
  minikube stop
fi

printf "\nStarting Minikube\n"
minikube start --vm=true --insecure-registry="${EDUCATES_MINIKUBE_IP}"/24 --cpus=4 --memory=8g

# Capture minikube ip
IP=$(minikube ip)
# Check that the value is correct
if [[ "${EDUCATES_MINIKUBE_IP}" != "${IP}" ]]; then
  printf "\nMinikube IP for insecure registry does not match actual Minikube IP\n"
  echo "Updating record of Minikube IP\n"
  echo "export EDUCATES_MINIKUBE_IP=$(minikube ip)" > local-eduk8s-start.env
  echo "Please re-run this script!"
  exit
fi

minikube addons enable ingress
minikube addons enable ingress-dns

# Install operator
printf "\nInstalling Educates\n"
kubectl apply -k "github.com/eduk8s/eduk8s?ref=master"

# Install add-ons
printf "\nInstalling add-ons\n"
source ./install-cluster-add-ons.sh
install_cluster_add_ons

printf "\nConfiguring Educates\n"
# Configure operator with domain name
kubectl set env deployment/eduk8s-operator -n eduk8s INGRESS_DOMAIN=$EDUCATES_MINIKUBE_IP.nip.io

# If working with large images configure nginx add `proxy-body-size: 1g` in data section:
#  kubectl edit configmap nginx-load-balancer-conf -n kube-system

printf "\nFinished Educates installation\n"
# Show if if above worked
kubectl get all -n eduk8s  

printf "\nDeploying workshop\n"
# deploy workshop definition
kubectl apply -f ./resources/workshop.yaml

# deploy training portal 
kubectl apply -f ./resources/training-portal.yaml

printf "\nFinished deploying workshop\n"
echo "Watching resources... Click on URL to open training portal"
echo "Ctrl-C here stops 'kubectl watch' only (the workshop will continue to run)"
# Get trainingportals, will have to 
kubectl get trainingportal --watch
