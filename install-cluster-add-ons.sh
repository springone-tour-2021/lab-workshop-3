#!/usr/bin/env bash
set -e
set -o pipefail

function install_cluster_add_ons() {

  printf "\nDeleting add-ons\n"
  kustomize build tooling/overlays/educates/ | kubectl delete -f -

  printf "\Installing add-ons\n"
  kustomize build tooling/overlays/educates/ | kubectl apply -f -

  printf "\nFinished installing add-ons\n"

}
