#!/usr/bin/env bash
set -e
set -o pipefail

function install_cluster_add_ons() {
  printf "\nInstalling add-ons\n"
  RCURL_BASE="https://raw.githubusercontent.com/booternetes-III-springonetour-july-2021/cat-service-release-ops/main"

  printf "\nInstalling add-on: kpack\n"
  FILE="tooling/kpack/release.yaml"
  RCURL="$RCURL_BASE/$FILE"
  kubectl apply -f $RCURL

  printf "\nInstalling add-on: argocd\n"
  FILE="tooling/argocd/install.yaml"
  RCURL="$RCURL_BASE/$FILE"
  kubectl create ns argocd
  kubectl apply -f $RCURL -n argocd

  printf "\nInstalling add-on: argocd-image-updater\n"
  FILE="tooling/argocd-image-updater/install.yaml"
  RCURL="$RCURL_BASE/$FILE"
  kubectl apply -f $RCURL -n argocd

  printf "\nFinished installing add-ons\n"
}
